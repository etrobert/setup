# Search c411's Torznab API and hand a release to transmission on charon.
def text [tag: string] { $in | where tag == $tag | get 0.content.0.content }
def attribute [tag: string, name: string] { $in | where tag == $tag | get 0.attributes | get $name }
def torznab [name: string] { $in | where tag == attr | where attributes.name == $name | get 0.attributes.value }

def age [when: datetime] {
  let days = (((date now) - $when) / 1day | math round)
  if $days >= 365 { $"(($days / 365 | math round))y" } else if $days >= 30 { $"(($days / 30 | math round))mo" } else { $"($days)d" }
}

def main [...terms: string] {
  let key = (open --raw /run/agenix/c411-api-key | str trim)
  let url = {scheme: https, host: "c411.org", path: "/api/torznab",
             params: {apikey: $key, t: "music", cat: "3010", limit: 100, q: ($terms | str join " ")}} | url join

  let results = (http get $url
    | get content | where tag == channel | get 0.content | where tag == item
    | each {|item|
        let f = $item.content
        {
          seeds: ($f | torznab seeders | into int),
          size: ($f | text size | into filesize),
          age: (age ($f | text pubDate | into datetime)),
          title: ($f | text title),
          link: ($f | attribute enclosure url),
        }
      }
  )

  if ($results | is-empty) { error make --unspanned {msg: "no results"} }

  let choice = ($results | input list --fuzzy --display {|r|
    let seeds = ($"($r.seeds)" | fill --width 4 --alignment r)
    let size = ($"($r.size)" | fill --width 9 --alignment r)
    let age = ($r.age | fill --width 4 --alignment r)
    $"($seeds) seeds  ($size)  ($age)  ($r.title)"
  })

  if $choice != null { transmission-remote torrents:80 --add $choice.link }
}
