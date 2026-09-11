"""Notify over ntfy when a template image shows up in a window.

Reads ~/.config/screen-watch/config.json:

    {"app_id": "Foo", "template": "foo.png", "title": "Foo spotted"}

`template` is relative to the config directory. While a window with that
app id is on an active workspace, its output is captured back to back and
searched for the template at several scales, since a game scales its world
with the window. A hit notifies once, then re-arms after the template has
been gone for a few seconds.
"""

import json
import os
import socket
import subprocess
import sys
import time
from pathlib import Path

import cv2
import numpy as np

CONFIG_DIR = (
    Path(os.environ.get("XDG_CONFIG_HOME", "~/.config")).expanduser() / "screen-watch"
)
# Matching runs on a half-resolution frame: 7 scales in 0.7 s instead of 3 s.
FRAME_SCALE = 0.5
SCALES = [0.7, 0.8, 0.9, 1.0, 1.15, 1.3, 1.5]
# Positives score 0.8-1.0 at the right scale, negatives peak around 0.55.
THRESHOLD = 0.7
POLL_HIDDEN = 10
REARM_AFTER = 3


def niri(request):
    with socket.socket(socket.AF_UNIX) as sock:
        sock.connect(os.environ["NIRI_SOCKET"])
        sock.sendall((json.dumps(request) + "\n").encode())
        reply = json.loads(sock.makefile().readline())
    return reply["Ok"][request]


def visible_output(app_id):
    """The output showing a window with this app id, or None."""
    windows = [w for w in niri("Windows") if w["app_id"] == app_id]
    workspaces = niri("Workspaces")
    active = {w["id"]: w["output"] for w in workspaces if w["is_active"]}
    for window in windows:
        if window["workspace_id"] in active:
            return active[window["workspace_id"]]
    return None


def capture(output):
    # PPM: raw pixels, so no codec on either side.
    ppm = subprocess.run(
        ["grim", "-t", "ppm", "-o", output, "-"], check=True, capture_output=True
    ).stdout
    frame = cv2.imdecode(np.frombuffer(ppm, np.uint8), cv2.IMREAD_COLOR)
    return shrink(frame, FRAME_SCALE)


def shrink(image, factor):
    return cv2.resize(image, None, fx=factor, fy=factor, interpolation=cv2.INTER_AREA)


def best_match(frame, template):
    """(score, top-left corner, size) of the best match over all scales."""
    matches = []
    for scale in SCALES:
        scaled = shrink(template, FRAME_SCALE * scale)
        result = cv2.matchTemplate(frame, scaled, cv2.TM_CCOEFF_NORMED)
        _, score, _, corner = cv2.minMaxLoc(result)
        matches.append((score, corner, scaled.shape[1::-1]))
    return max(matches)


def notify(title, score, frame, corner, size):
    """Attach the frame, match boxed, so the hit can be placed afterwards."""
    x, y = corner
    w, h = size
    cv2.rectangle(frame, (x - 20, y - 20), (x + w + 20, y + h + 20), (0, 0, 255), 3)
    _, jpeg = cv2.imencode(".jpg", frame)
    subprocess.run(
        [
            "ntfy",
            "publish",
            "--quiet",
            "--title",
            title,
            "--file=-",
            "--filename=frame.jpg",
            f"score {score:.2f}",
        ],
        input=jpeg.tobytes(),
        check=True,
    )


def main():
    config = json.loads((CONFIG_DIR / "config.json").read_text())
    template = cv2.imread(str(CONFIG_DIR / config["template"]))
    if template is None:
        sys.exit(f"cannot read template {config['template']}")

    armed = True
    last_seen = 0.0
    while True:
        output = visible_output(config["app_id"])
        if output is None:
            # Out of sight counts as gone.
            armed = True
            time.sleep(POLL_HIDDEN)
            continue

        start = time.time()
        frame = capture(output)
        score, corner, size = best_match(frame, template)
        now = time.time()
        print(f"{score:.2f} in {now - start:.2f}s", flush=True)
        if score >= THRESHOLD:
            last_seen = now
            if armed:
                armed = False
                notify(config["title"], score, frame, corner, size)
        elif now - last_seen > REARM_AFTER:
            armed = True


main()
