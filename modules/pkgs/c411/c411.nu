# Search c411's Torznab API and hand a release to transmission on charon.
def main [...terms: string] {
    let key = open --raw /run/agenix/c411-api-key | str trim
    let url = {
        scheme: https
        host: "c411.org"
        path: "/api/torznab"
        # cat does the filtering; t is required but inert (t=search is the same).
        params: {
            apikey: $key
            t: "music"
            cat: "3010"
            limit: 100
            q: ($terms | str join " ")
        }
    } | url join

    let results = (http get $url
    | get content.0.content | where tag == item
    | each {|item|
        let f = $item.content
        {
          seeds: ($f | where tag == attr | where attributes.name == seeders | get 0.attributes.value | into int),
          size: ($f | where tag == size | get 0.content.0.content | into filesize),
          published: ($f | where tag == pubDate | get 0.content.0.content | into datetime),
          title: ($f | where tag == title | get 0.content.0.content),
          link: ($f | where tag == enclosure | get 0.attributes.url),
        }
      }
  )

    if ($results | is-empty) { error make --unspanned {msg: "no results"} }

    # --index so the table can omit the link; nushell renders size and date itself.
    let n = $results | select seeds size published title | input list --fuzzy --index

    if $n != null { transmission-remote torrents:80 --add ($results | get $n | get link) }
}
