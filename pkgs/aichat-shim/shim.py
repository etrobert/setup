"""OpenAI-compatible /v1/chat/completions endpoint backed by `claude -p`.

aichat only speaks HTTP, so this translates its request into a Claude Code
invocation and wraps the reply back into the shape aichat parses.
"""

import json
import os
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# default.nix substitutes a store path here, whose length is not ours to
# control, so this one line opts out of the 79-column limit.
CLAUDE = "@claude@"  # noqa: E501
MODEL = "haiku"
PORT = 4142
# The `??` alias prefixes the request with this so claude can run in the
# caller's directory and pick up that project's CLAUDE.md; aichat itself has
# no way to send a working directory.
CWD_PREFIX = "cwd: "
DENIED_TOOLS = ",".join(
    [
        "Bash",
        "Read",
        "Write",
        "Edit",
        "Glob",
        "Grep",
        "Task",
        "WebFetch",
        "WebSearch",
        "NotebookEdit",
    ]
)


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


def split_cwd(prompt):
    if not prompt.startswith(CWD_PREFIX):
        return None, prompt
    first, _, rest = prompt.partition("\n")
    cwd = first.removeprefix(CWD_PREFIX).strip()
    if not os.path.isdir(cwd):
        return None, rest.strip()
    return cwd, rest.strip()


def run_claude(system, prompt):
    cwd, prompt = split_cwd(prompt)
    argv = [CLAUDE, "--print", "--model", MODEL, "--strict-mcp-config"]
    if system:
        argv += ["--append-system-prompt", system]
    # Without this claude answers agentically — it will happily run the search
    # itself rather than hand back the command to run.
    argv += ["--disallowed-tools", DENIED_TOOLS]
    # The prompt goes on stdin because --disallowed-tools is variadic and
    # swallows any argument that follows it.
    done = subprocess.run(
        argv,
        input=prompt,
        capture_output=True,
        text=True,
        timeout=120,
        cwd=cwd,
    )
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


ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
