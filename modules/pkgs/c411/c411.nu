# Search c411's Torznab API and hand a release to transmission on charon.
def search [category: string, subdir: string, terms: list<string>] {
    let key = open --raw /run/agenix/c411-api-key | str trim
    let url = {
        scheme: https
        host: "c411.org", 
        path: "/api/torznab"
        # cat does the filtering; t is required but inert (t=search is the same).
        params: {
            apikey: $key
            t: "search", 
            cat: $category
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

    # A title too long for the terminal makes input list drop the whole column.
    # math max 0: a negative bound would count from the end of the title.
    let room = [
        ((term size).columns - 50)
        0
    ] | math max

    # --index so the table can omit the link; nushell renders size and date itself.
    let n = $results
    | select seeds size published title
    | update title {|r| $r.title | str substring ..$room}
    | input list --fuzzy --index

    # Music lands apart from video: jellyfin's library is the video landing zone.
    if $n != null {
        let link = $results | get $n | get link
        transmission-remote torrents:80 --add $link --download-dir $"/var/lib/transmission/Downloads/($subdir)"
    }
}

def "main music" [...terms: string] { search 3010 music $terms }
def "main movies" [...terms: string] { search 2000 "" $terms }
def "main tv" [...terms: string] { search 5000 "" $terms }

def main [] { print "Usage: c411 (music | movies | tv) <search terms>" }
