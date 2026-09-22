"""A niri IPC socket serving a fixture: one JSON line in, one JSON line out.

The fixture is re-read per connection, so a test swaps screens by rewriting it.
"""

import json
import os
import socket
import sys

fixture, path = sys.argv[1], sys.argv[2]
if os.path.exists(path):
    os.unlink(path)

server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
server.bind(path)
server.listen(8)
print("ready", flush=True)

while True:
    conn, _ = server.accept()
    with conn:
        request = json.loads(conn.makefile("r").readline())
        reply = (
            {"Ok": {"Outputs": json.load(open(fixture))}}
            if request == "Outputs"
            else {"Err": f"the mock only serves Outputs, not {request}"}
        )
        conn.sendall((json.dumps(reply) + "\n").encode())
