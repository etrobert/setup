"""OpenAI-compatible /v1/chat/completions endpoint backed by `claude -p`.

aichat only speaks HTTP, so this translates its request into a Claude Code
invocation and wraps the reply back into the shape aichat parses.
"""

import json
import os
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MODEL = "claude-haiku-4-5-20251001"
PORT = 4142
# claude discovers CLAUDE.md by walking up from its working directory, so the
# shim runs from the setup repo: that is where the machine, service and Nix
# conventions worth applying to a shell command live.
REPO = os.path.expanduser("~/setup")


def strip_fences(text):
    kept = []
    for line in text.strip().splitlines():
        if not line.strip().startswith("```"):
            kept.append(line)
    return "\n".join(kept).strip()


def join_role(messages, role):
    parts = []
    for message in messages:
        if message.get("role") == role:
            parts.append(message.get("content", ""))
    return "\n".join(parts).strip()


def run_claude(system, prompt):
    argv = ["claude", "--print", "--model", MODEL, "--strict-mcp-config"]
    if system:
        argv += ["--append-system-prompt", system]
    argv.append(prompt)
    done = subprocess.run(argv, capture_output=True, text=True, timeout=120)
    if done.returncode != 0:
        raise RuntimeError(done.stderr.strip() or "claude exited non-zero")
    return strip_fences(done.stdout)


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def respond(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        try:
            length = int(self.headers.get("Content-Length", 0))
            request = json.loads(self.rfile.read(length))
            messages = request.get("messages", [])
            system = join_role(messages, "system")
            prompt = join_role(messages, "user")
            content = run_claude(system, prompt)
        except Exception as err:
            error = {"message": str(err), "type": "shim_error"}
            self.respond(502, {"error": error})
            return
        message = {"role": "assistant", "content": content}
        self.respond(200, {"choices": [{"message": message}]})

    def log_message(self, fmt, *args):
        print(fmt % args, flush=True)


if os.path.isdir(REPO):
    os.chdir(REPO)

ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
