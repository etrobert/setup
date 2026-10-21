import os
import queue
import subprocess
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import torch
from kokoro import KPipeline

PORT = 8880
VOICE = "am_michael"
PLAY = [
    "pw-play",
    "--raw",
    "--format",
    "f32",
    "--rate",
    "24000",
    "--channels",
    "1",
    "-",
]

# Past the physical cores, SMT threads make synthesis several times slower.
torch.set_num_threads(os.cpu_count() // 2)

pipeline = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M")
# The first synthesis is ~30x slower than the next ones.
for _ in pipeline("Ready.", voice=VOICE):
    pass

texts = queue.Queue()
# Bumped by /stop: texts queued before it are dropped, even mid-playback.
generation = 0
player = None


def speak_forever():
    global player
    while True:
        text_generation, text = texts.get()
        player = subprocess.Popen(PLAY, stdin=subprocess.PIPE)
        try:
            for _, _, audio in pipeline(text, voice=VOICE):
                if text_generation != generation:
                    break
                player.stdin.write(audio.numpy().tobytes())
            player.stdin.close()
        except BrokenPipeError:
            pass
        player.wait()


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        global generation
        if self.path == "/say":
            length = int(self.headers["Content-Length"])
            texts.put((generation, self.rfile.read(length).decode()))
        elif self.path == "/stop":
            generation += 1
            if player:
                player.kill()
        else:
            self.send_error(404)
            return
        self.send_response(204)
        self.end_headers()


threading.Thread(target=speak_forever, daemon=True).start()
ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
