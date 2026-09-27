---
name: music-import
description:
  Add music to Étienne's Navidrome library on tower with beets. Use whenever he
  asks to import, add, or tag albums, torrents, Bandcamp downloads, or yt-dlp
  audio, or asks where music files live.
---

# Music import

`/tank/media/music/<origin>/…` — `bandcamp`, `torrents`, `yt-dlp` — is what
Navidrome serves; `playlists/` and the beets catalogue (`.beets/`) sit beside
them. `beet` (`beets-wrapped` in `etrobert/setup`) is on tower only, so run it
there.

Every import sets its origin, which picks the top-level directory:

```sh
beet import --set source=torrents /tank/media/torrents/<dir>
```

Torrents land in `/tank/media/torrents/`. Beets copies them in; the landing copy
stays until charon has finished seeding.
