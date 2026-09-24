# Search c411's Torznab API and hand a release to transmission on charon.
def main [...terms: string] {
  let key = (open --raw /run/agenix/c411-api-key | str trim)
  let url = {scheme: https, host: "c411.org", path: "/api/torznab",
             params: {apikey: $key, t: "music", q: ($terms | str join " ")}} | url join

  let results = (http get --headers [User-Agent c411] $url
    | get content | where tag == channel | get 0.content | where tag == item
    | each {|item|
        let f = $item.content
        {
          seeds: ($f | where tag == attr | where attributes.name == seeders | get 0.attributes.value | into int),
          size: ($f | where tag == size | get 0.content.0.content | into filesize),
          title: ($f | where tag == title | get 0.content.0.content),
          link: ($f | where tag == enclosure | get 0.attributes.url),
        }
      }
  )

  if ($results | is-empty) { error make --unspanned {msg: "no results"} }

  let choice = ($results | input list --fuzzy --display {|r|
    let seeds = ($"($r.seeds)" | fill --width 4 --alignment r)
    let size = ($"($r.size)" | fill --width 9 --alignment r)
    $"($seeds) seeds  ($size)  ($r.title)"
  })

  if $choice != null { transmission-remote torrents:80 --add $choice.link }
}
