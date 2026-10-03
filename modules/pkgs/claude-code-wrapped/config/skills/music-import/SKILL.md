---
name: music-import
description:
  Add music to Étienne's Navidrome library on tower, through Lidarr for torrents
  and beets for Bandcamp and yt-dlp. Use whenever he asks to import, add, or tag
  albums, torrents, Bandcamp downloads, or yt-dlp audio, or asks where music
  files live.
---

# Music import

Navidrome serves `/tank/media/music`. The top-level directory says where an
album came from — `bandcamp/`, `torrents/`, `yt-dlp/`, each holding
`Artist/Album/` — with `playlists/` and the beets catalogue (`.beets/`) beside
them.

## Torrents: Lidarr

`torrents/` is Lidarr's root folder. Add an album at <http://lidarr/> on the
tailnet: search, pick the album (not the artist), Root Folder
`/tank/media/music/torrents`, Monitor `None`, Monitor New Items `None`, Quality
Profile `Lossless`, tick "Start search for new album".

To browse a discography, add the artist with Monitor `None` (adds nothing) and
use the magnifying glass on an album row; the bookmark icon only marks the album
monitored and does not search.

Monitor `None` means one immediate search and no retry: if c411 has nothing
today, search again by hand later or mark the album and artist monitored.

Lidarr grabs from c411, hands the torrent to transmission on charon,
`torrent-pull` copies it to `/tank/media/torrents` every 15 minutes, Lidarr
hardlinks it into `torrents/Artist/Album/NN Title.ext`, and Navidrome's watcher
picks it up. Indexer, download client, naming and root folder are declared by
the `lidarr-setup` oneshot (`modules/features/lidarr.nix` in `etrobert/setup`);
nothing is configured in Lidarr's UI.

## Bandcamp and yt-dlp: beets

`beet` (`beets-wrapped`) is on tower only, so run it there. `--set source=`
picks the top-level directory:

```sh
beet import --set source=bandcamp <dir>
```

## Releases Lidarr cannot match

For a release not on MusicBrainz, `c411 music <terms>` on tower hands it to
transmission by hand. It lands in `/tank/media/torrents/<name>` and Lidarr does
not import it; file it with `beet import --set source=torrents`. The landing
copy stays until charon has finished seeding.
