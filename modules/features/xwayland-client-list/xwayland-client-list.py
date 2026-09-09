"""Publish _NET_CLIENT_LIST on the XWayland root window.

xwayland-satellite implements a five-hint subset of EWMH and declares exactly
that in _NET_SUPPORTED; _NET_CLIENT_LIST is only SHOULD in the spec, and it
never sets one. Dofus 3's ScreenManager locates its own window by scanning
that list anyway, so it finds nothing, enumerates zero displays, and aborts on
startup with an empty-list IndexOutOfRange.

Listing every window carrying a _NET_WM_PID is enough for that lookup.
"""

import time

from Xlib import X, display, error

INTERVAL = 1.0


def clients(root, pid_atom):
    found = []
    stack = list(root.query_tree().children)
    while stack:
        win = stack.pop()
        # A window can go away mid-walk; anything else should reach systemd.
        try:
            stack.extend(win.query_tree().children)
            if win.get_full_property(pid_atom, X.AnyPropertyType):
                found.append(win.id)
        except error.BadWindow:
            continue
    return found


def main():
    d = display.Display()
    root = d.screen().root
    client_list = d.intern_atom("_NET_CLIENT_LIST")
    pid_atom = d.intern_atom("_NET_WM_PID")
    window_type = d.intern_atom("WINDOW")

    while True:
        wins = clients(root, pid_atom)
        root.change_property(client_list, window_type, 32, wins)
        d.sync()
        time.sleep(INTERVAL)


main()
