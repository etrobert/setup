# Search c411's Torznab API and hand a release to transmission on charon.
def text [tag: string] { $in | where tag == $tag | get 0.content.0.content }
def attribute [tag: string, name: string] { $in | where tag == $tag | get 0.attributes | get $name }
def torznab [name: string] { $in | where tag == attr | where attributes.name == $name | get 0.attributes.value }

def main [...terms: string] {
  let key = (open --raw /run/agenix/c411-api-key | str trim)
  let url = {scheme: https, host: "c411.org", path: "/api/torznab",
             params: {apikey: $key, t: "music", cat: "3010", limit: 100, q: ($terms | str join " ")}} | url join

  let results = (http get $url
    | get content.0.content | where tag == item
    | each {|item|
        let f = $item.content
        {
          seeds: ($f | torznab seeders | into int),
          size: ($f | text size | into filesize),
          published: ($f | text pubDate | into datetime),
          title: ($f | text title),
          link: ($f | attribute enclosure url),
        }
      }
  )

  if ($results | is-empty) { error make --unspanned {msg: "no results"} }

  # --index so the table can omit the link; nushell renders size and date itself.
  let n = ($results | select seeds size published title | input list --fuzzy --index)

  if $n != null { transmission-remote torrents:80 --add ($results | get $n | get link) }
}
