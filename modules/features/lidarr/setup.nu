# Declare what Lidarr keeps in its database: naming, download client, path
# mapping, indexer, root folder, notification. Runs after lidarr.service.

def api [method: string, path: string, body?: record] {
    let url = $"($env.LIDARR_URL)/api/v1/($path)"
    let headers = {X-Api-Key: $env.LIDARR_KEY}
    match $method {
        get => (http get --headers $headers $url)
        post => (http post --headers $headers --content-type application/json $url $body)
        put => (http put --headers $headers --content-type application/json $url $body)
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

# Poll until the closure returns a value: Lidarr listens, then seeds profiles, after it starts.
def wait-for [what: string, probe: closure] {
    for _ in 1..120 {
        let value = try { do $probe }
        if $value != null { return $value }
        sleep 1sec
    }
    error make --unspanned {msg: $"timed out waiting for ($what)"}
}

def main [url: string, c411_key: path] {
    $env.LIDARR_URL = $url
    $env.LIDARR_KEY = wait-for "lidarr" {
        http get $"($url)/initialize.json" | get apiKey
    }
    let lossless = wait-for "quality profiles" {
        api get qualityprofile | where name == Lossless | get -o 0.id
    }
    let standard = api get metadataprofile | where name == Standard | get 0.id

    # Off, Lidarr drops imports flat into the artist folder under their original names.
    let album = "{Album Title}{ (Album Disambiguation)}"
    api put config/naming (api get config/naming | merge {
        renameTracks: true
        standardTrackFormat: $"($album)/{track:00} {Track Title}"
        multiDiscTrackFormat: $"($album)/{medium:00}-{track:00} {Track Title}"
    }) | ignore

    # charon's reaper is the only remover (transmission.nix); a client Lidarr may
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
            {name: host, value: torrents}
            {name: port, value: 80}
        ]
    }

    (ensure remotepathmapping host {
        host: torrents
        remotePath: /var/lib/transmission/Downloads/
        localPath: /tank/media/torrents/
    })

    # Transmission creates the category folder on charon at the first grab; the
    # health check wants its pulled copy to exist before that.
    mkdir /tank/media/torrents/lidarr

    # slskd has no login (the tailnet is the access control); Tubifarry still wants an API key.
    # removeCompletedDownloads: slskd keeps sharing a download until its own retention deletes it.
    provider downloadclient {
        name: soulseek
        implementation: SlskdClient
        configContract: SlskdProviderSettings
        enable: true
        priority: 1
        removeCompletedDownloads: false
        tags: []
        fields: [
            {name: baseUrl, value: "http://soulseek"}
            {name: apiKey, value: unused}
        ]
    }

    (ensure
        remotepathmapping
        host
        {host: soulseek, remotePath: /var/lib/slskd/downloads/, localPath: /tank/media/soulseek/}
    )

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
            {name: baseUrl, value: "https://c411.org"}
            {name: apiPath, value: /api/torznab}
            {
                name: apiKey
                value: (open --raw $c411_key | str trim)
            }
            {
                name: categories
                value: [3010]
            }
        ]
    }

    # Ahead of c411 (lower is preferred): no seeding rule to honour, wider catalogue.
    provider indexer {
        name: soulseek
        implementation: SlskdIndexer
        configContract: SlskdSettings
        enableRss: false
        enableAutomaticSearch: true
        enableInteractiveSearch: true
        priority: 10
        tags: []
        fields: [
            {name: baseUrl, value: "http://soulseek"}
            {name: apiKey, value: unused}
        ]
    }

    # Saving scans the tree and adds every artist on it; monitored, they would all be hunted.
    ensure rootfolder path {
        name: torrents
        path: /tank/media/music/torrents
        defaultQualityProfileId: $lossless
        defaultMetadataProfileId: $standard
        defaultMonitorOption: none
        defaultNewItemMonitorOption: none
        defaultTags: []
    }

    # onUpgrade: without it an import that replaces existing files is silent.
    # The tags field: omitted, Lidarr leaves it null and the sender crashes on it.
    provider notification {
        name: ntfy
        implementation: Ntfy
        configContract: NtfySettings
        onReleaseImport: true
        onUpgrade: true
        tags: []
        fields: [
            {name: serverUrl, value: "http://127.0.0.1:2586"}
            {
                name: topics
                value: [home]
            }
            {
                name: tags
                value: []
            }
        ]
    }

    # Off by default: imports kept the uploader's tags, so one album split into three in Navidrome.
    # newFiles, not sync: sync rewrites tags on every metadata refresh.
    api put config/metadataprovider (api get config/metadataprovider | merge {
        writeAudioTags: newFiles
        scrubAudioTags: true
    }) | ignore
}
