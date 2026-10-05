# Declare what Radarr keeps in its database: download client, path mapping,
# indexer, root folder, quality sizes and profile, notification. Runs after
# radarr.service.

def api [method: string, path: string, body?: record] {
    let url = $"($env.RADARR_URL)/api/v3/($path)"
    let headers = { X-Api-Key: $env.RADARR_KEY }
    match $method {
        get => (http get --headers $headers $url)
        post => (http post --headers $headers --content-type application/json $url $body)
        put => (http put --headers $headers --content-type application/json $url $body)
        delete => (http delete --headers $headers $url)
    }
}

# Create the resource, or replace the one that shares its name.
def provider [path: string, body: record] {
    let existing = api get $path | where name == $body.name
    if ($existing | is-empty) {
        api post $path $body
    } else {
        api put $"($path)/($existing.0.id)" ($body | insert id $existing.0.id)
    } | ignore
}

# Create the resource unless one with the same key field exists.
def ensure [path: string, field: string, body: record] {
    let existing = api get $path | where {|row| ($row | get $field) == ($body | get $field) }
    if ($existing | is-empty) {
        api post $path $body | ignore
    }
}

# Poll until the closure returns a value: Radarr listens before the unit counts as started.
def wait-for [what: string, probe: closure] {
    for _ in 1..120 {
        let value = try { do $probe }
        if $value != null { return $value }
        sleep 1sec
    }
    error make --unspanned { msg: $"timed out waiting for ($what)" }
}

def main [url: string, c411_key: path, recyclarr_config: path] {
    $env.RADARR_URL = $url
    $env.RADARR_KEY = wait-for "radarr" { http get $"($url)/initialize.json" | get apiKey }

    # charon's reaper is the only remover (transmission.nix); a client Radarr may
    # not remove from is also what makes it hardlink instead of move.
    provider downloadclient {
        name: torrents
        implementation: Transmission
        configContract: TransmissionSettings
        enable: true
        priority: 1
        removeCompletedDownloads: false
        tags: []
        fields: [
            { name: host, value: torrents }
            { name: port, value: 80 }
        ]
    }

    ensure remotepathmapping host {
        host: torrents
        remotePath: /var/lib/transmission/Downloads/
        localPath: /tank/media/torrents/
    }

    # Transmission creates the category folder on charon at the first grab; the
    # health check wants its pulled copy to exist before that.
    mkdir /tank/media/torrents/radarr

    # c411 files films under 2030, animation under 2060, documentaries under 2070.
    provider indexer {
        name: c411
        implementation: Torznab
        configContract: TorznabSettings
        enableRss: true
        enableAutomaticSearch: true
        enableInteractiveSearch: true
        priority: 25
        tags: []
        fields: [
            { name: baseUrl, value: "https://c411.org" }
            { name: apiPath, value: /api/torznab }
            { name: apiKey, value: (open --raw $c411_key | str trim) }
            { name: categories, value: [2030 2060 2070] }
            # MULTi on c411 means original (-2) plus French (2) audio, as TRaSH's French guide assumes.
            { name: multiLanguages, value: [-2 2] }
        ]
    }

    mkdir /tank/media/movies
    ensure rootfolder path { path: /tank/media/movies }

    # Reads RADARR_URL and RADARR_KEY from the environment.
    ^recyclarr sync --config $recyclarr_config

    # The only profile left is the one every movie gets, from the UI or Seerr.
    for profile in (api get qualityprofile | where name != "Original audio") {
        api delete $"qualityprofile/($profile.id)"
    }

    # The tags field: omitted, Radarr leaves it null and the sender crashes on it.
    provider notification {
        name: ntfy
        implementation: Ntfy
        configContract: NtfySettings
        onDownload: true
        onUpgrade: true
        tags: []
        fields: [
            { name: serverUrl, value: "http://127.0.0.1:2586" }
            { name: topics, value: [home] }
            { name: tags, value: [] }
        ]
    }
}
