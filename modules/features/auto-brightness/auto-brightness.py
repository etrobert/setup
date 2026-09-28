import subprocess
import sys
from datetime import datetime, timezone

from astral import Observer
from astral.sun import elevation

day, night = (int(arg) for arg in sys.argv[1:])

# Berlin, as in darkman.nix
sun = elevation(Observer(52.5, 13.4), datetime.now(timezone.utc))

# Day above 6°, night below -6° (end of civil twilight)
fade = min(max((6 - sun) / 12, 0), 1)

brightness = round(day - (day - night) * fade)
subprocess.run(
    ["noctalia", "msg", "brightness-set", "all", f"{brightness}%"],
    check=True,
)
