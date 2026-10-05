const admin = "seerr"
# Seerr's Permission enum: REQUEST | AUTO_APPROVE, and ADMIN.
const request_auto_approve = 160
const seerr_admin = 2
const jellyfin_enhanced = "f69e946a-4b3c-4e9a-8f0a-8d7c1b2c4d9b"
const home_screen_sections = "b8298e01-2697-407a-b44d-aa8dc795e850"

def jellyfin [method: string, path: string, body?: any] {
    let url = $"($env.JELLYFIN_URL)/($path)"
    let headers = { Authorization: $"MediaBrowser Token=($env.JELLYFIN_KEY)" }
    match $method {
        get => (http get --headers $headers $url)
        post => (http post --headers $headers --content-type application/json $url $body)
    }
}

def seerr [method: string, path: string, body?: any] {
    let url = $"($env.SEERR_URL)/api/v1/($path)"
    let headers = { X-Api-Key: $env.SEERR_KEY }
    match $method {
        get => (http get --headers $headers $url)
        post => (http post --headers $headers --content-type application/json $url $body)
        put => (http put --headers $headers --content-type application/json $url $body)
    }
}

# Poll until the closure returns a value: both apps listen before they answer.
def wait-for [what: string, probe: closure] {
    for _ in 1..120 {
        let value = try { do $probe }
        if $value != null { return $value }
        sleep 1sec
    }
    error make --unspanned { msg: $"timed out waiting for ($what)" }
}

# Create the server, or replace the one that shares its name.
def server [path: string, body: record] {
    let existing = seerr get $path | where name == $body.name
    if ($existing | is-empty) {
        seerr post $path $body
    } else {
        seerr put $"($path)/($existing.0.id)" $body
    } | ignore
}

# Seerr's server entry for an *arr: its only profile and root folder.
def arr [url: string, name: string] {
    let key = http get $"($url)/initialize.json" | get apiKey
    let headers = { X-Api-Key: $key }
    let profile = http get --headers $headers $"($url)/api/v3/qualityprofile" | where name == "Original audio" | first
    let address = $url | url parse
    {
        name: $name
        hostname: $address.host
        port: ($address.port | into int)
        apiKey: $key
        # Seerr's API schema requires it, though http is the default.
        useSsl: false
        activeProfileId: $profile.id
        activeProfileName: $profile.name
        activeDirectory: (http get --headers $headers $"($url)/api/v3/rootfolder" | first | get path)
        is4k: false
        isDefault: true
        # Seerr then shows a request as downloading, then available.
        syncEnabled: true
    }
}

# Merge the fields into a plugin's configuration; the rest keeps its value.
def plugin [id: string, fields: record] {
    let path = $"Plugins/($id)/Configuration"
    jellyfin post $path (jellyfin get $path | merge $fields) | ignore
}

def main [seerr_url: string, jellyfin_url: string, radarr_url: string, sonarr_url: string] {
    $env.SEERR_URL = $seerr_url
    $env.JELLYFIN_URL = $jellyfin_url
    $env.JELLYFIN_KEY = open --raw $"($env.CREDENTIALS_DIRECTORY)/jellyfin-api-key" | str trim

    wait-for jellyfin { jellyfin get System/Info | get Id }
    wait-for seerr { http get $"($seerr_url)/api/v1/status" | get version }

    # Seerr's first login needs a Jellyfin admin password; the key is already admin, so reusing it exposes nothing.
    if (jellyfin get Users | where Name == $admin | is-empty) {
        let user = jellyfin post Users/New { Name: $admin, Password: $env.JELLYFIN_KEY }
        jellyfin post $"Users/($user.Id)/Policy" ($user.Policy | merge { IsAdministrator: true, IsHidden: true }) | ignore
    }

    let initialized = http get $"($seerr_url)/api/v1/settings/public" | get initialized
    # serverType 2 is Jellyfin in Seerr's MediaServerType enum.
    let login = { username: $admin, password: $env.JELLYFIN_KEY, serverType: 2 }
    let address = $jellyfin_url | url parse
    let login = if $initialized { $login } else {
        $login | merge { hostname: $address.host, port: ($address.port | into int) }
    }
    let response = http post --full --content-type application/json $"($seerr_url)/api/v1/auth/jellyfin" $login
    let cookie = $response.headers.response | where name == set-cookie | get value.0 | split row ";" | first
    $env.SEERR_KEY = http get --headers { Cookie: $cookie } $"($seerr_url)/api/v1/settings/main" | get apiKey

    # A library Jellyfin has not scanned yet has no id, so Seerr cannot list it.
    if (jellyfin get Library/VirtualFolders | any {|folder| $folder.ItemId? == null }) {
        jellyfin post Library/Refresh {} | ignore
        wait-for "library scan" {
            if (jellyfin get Library/VirtualFolders | all {|folder| $folder.ItemId? != null }) { true }
        }
    }
    let libraries = seerr get "settings/jellyfin/library?sync=true" | get id | str join ","
    seerr get $"settings/jellyfin/library?enable=($libraries)" | ignore

    # Seerr's own links to a title then open where the household watches.
    seerr post settings/jellyfin { externalHostname: "https://watch.etiennerobert.com" } | ignore

    seerr post settings/main { defaultPermissions: $request_auto_approve } | ignore

    server settings/radarr (arr $radarr_url Radarr | merge { minimumAvailability: released })
    server settings/sonarr (arr $sonarr_url Sonarr | merge { enableSeasonFolders: true })

    # Every Jellyfin account may request, so search and home screen requests just work.
    let jellyfin_users = jellyfin get Users | where Name != $admin
    seerr post user/import-from-jellyfin { jellyfinUserIds: ($jellyfin_users | get Id) } | ignore
    let jellyfin_admins = $jellyfin_users | where Policy.IsAdministrator | get Id | str replace --all "-" ""
    for user in (seerr get "user?take=100" | get results | where id != 1) {
        let permissions = if ($user.jellyfinUserId in $jellyfin_admins) { $seerr_admin } else { $request_auto_approve }
        seerr put $"user/($user.id)" { permissions: $permissions } | ignore
    }

    if not $initialized {
        seerr post settings/initialize {} | ignore
    }

    # Both plugins call Seerr from the Jellyfin server, so Seerr stays off the internet.
    plugin $jellyfin_enhanced {
        JellyseerrEnabled: true
        JellyseerrUrls: $seerr_url
        JellyseerrApiKey: $env.SEERR_KEY
        JellyseerrAutoImportUsers: true
    }
    # With no sections listed, the plugin empties every home screen.
    let sections = [
        ContinueWatching NextUp RecentlyAddedMovies RecentlyAddedShows BecauseYouWatched
        DiscoverMovies DiscoverTV Genre WatchAgain MyJellyseerrRequests
    ]
    plugin $home_screen_sections {
        Enabled: true
        JellyseerrUrl: $seerr_url
        JellyseerrApiKey: $env.SEERR_KEY
        SectionSettings: ($sections | enumerate | each {|section|
            {
                SectionId: $section.item
                Enabled: true
                LowerLimit: 1
                UpperLimit: 1
                OrderIndex: $section.index
                ViewMode: Portrait
            }
        })
    }
}
