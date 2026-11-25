import json
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

HERE = Path(__file__).parent
DATA = Path.cwd()
DECISIONS = DATA / "decisions.jsonl"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/notes.json":
            lines = DECISIONS.read_text().splitlines()
            decided = {json.loads(line)["id"] for line in lines}
            notes = json.loads((DATA / "notes.json").read_text())
            body = json.dumps([n for n in notes if n["id"] not in decided]).encode()
            kind = "application/json"
        elif self.path.startswith("/media/"):
            body = (DATA / self.path.lstrip("/")).read_bytes()
            kind = "image/png"
        else:
            body = (HERE / "index.html").read_bytes()
            kind = "text/html"
        self.send_response(200)
        self.send_header("Content-Type", kind + "; charset=utf-8")
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        decision = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        decision["at"] = time.strftime("%H:%M:%S")
        with DECISIONS.open("a") as f:
            f.write(json.dumps(decision, ensure_ascii=False) + "\n")
        self.send_response(204)
        self.end_headers()


HTTPServer(("127.0.0.1", 8765), Handler).serve_forever()
