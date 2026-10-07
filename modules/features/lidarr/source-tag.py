# Writes a SOURCE tag naming where an album came from.
#
# No arguments: Lidarr's custom script hook, for one import.
# backfill <lidarr url>: tags the whole library, from Lidarr's import
# history where it knows the client, else from the source folder.
import json
import os
import sys
import urllib.request
from collections import Counter
from pathlib import Path

import mutagen
from mutagen.id3 import ID3, TXXX
from mutagen.mp4 import MP4FreeForm, MP4Tags

LIBRARY = Path("/tank/media/music")
# Lidarr's download client names (setup.nu) double as source names.
CLIENTS = {"soulseek", "torrents"}
# beets files albums under one folder per source.
FOLDERS = CLIENTS | {"bandcamp", "yt-dlp"}
AUDIO = {".flac", ".mp3", ".m4a", ".ogg", ".opus", ".ape", ".wv"}


def tag(path, source):
    audio = mutagen.File(path)
    if audio is None:
        raise ValueError(f"not an audio file: {path}")
    if audio.tags is None:
        audio.add_tags()
    if isinstance(audio.tags, ID3):
        audio.tags.add(TXXX(encoding=3, desc="SOURCE", text=[source]))
    elif isinstance(audio.tags, MP4Tags):
        key = "----:com.apple.iTunes:SOURCE"
        audio.tags[key] = [MP4FreeForm(source.encode())]
    else:
        audio.tags["SOURCE"] = [source]
    audio.save()


# Lidarr builds the environment with a StringDictionary, which lowercases keys.
def hook():
    if os.environ["lidarr_eventtype"] == "Test":
        return
    source = os.environ["lidarr_download_client"]
    if source not in CLIENTS:
        sys.exit(f"unknown download client: {source!r}")
    for path in os.environ["lidarr_addedtrackpaths"].split("|"):
        tag(path, source)


def backfill(url):
    def get(path, key=None):
        request = urllib.request.Request(f"{url}/{path}")
        if key:
            request.add_header("X-Api-Key", key)
        with urllib.request.urlopen(request) as response:
            return json.load(response)

    key = get("initialize.json")["apiKey"]
    history = get(
        "api/v1/history?eventType=3&pageSize=1000000"
        "&sortKey=date&sortDirection=ascending",
        key,
    )["records"]
    # Later imports to the same path win: an upgrade replaces the file.
    known = {
        record["data"]["importedPath"]: record["data"]["downloadClient"]
        for record in history
        if record["data"].get("downloadClient") in CLIENTS
    }

    counts = Counter()
    for path in sorted(LIBRARY.rglob("*")):
        if path.suffix.lower() not in AUDIO:
            continue
        folder = path.relative_to(LIBRARY).parts[0]
        if folder not in FOLDERS:
            sys.exit(f"no source for folder {folder!r}: {path}")
        source = known.get(str(path), folder)
        tag(path, source)
        counts[source] += 1
    for source, count in sorted(counts.items()):
        print(f"{source}: {count} files")


if len(sys.argv) == 1:
    hook()
elif sys.argv[1] == "backfill":
    backfill(sys.argv[2])
else:
    sys.exit("usage: lidarr-source-tag [backfill <lidarr url>]")
