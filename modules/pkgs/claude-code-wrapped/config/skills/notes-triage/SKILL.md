---
name: notes-triage
description:
  Process Étienne's Apple Notes inbox through a local page with one big button
  per action. Use whenever he asks to triage, process or go through his notes.
---

# Notes triage

The inbox is the iCloud "Notes" folder, read on aaron over SSH with JXA
(JavaScript for Automation). Work in `~/.cache/notes-triage/` on tower.

## Setup

1. Export the notes changed in the last N days, newest batch first, with their
   photos (`export.js` is next to this file):

   ```sh
   ssh aaron 'rm -rf /tmp/notes-media && mkdir -p /tmp/notes-media'
   ssh aaron 'osascript -l JavaScript - N' < export.js > notes.json
   mkdir -p media && scp -q 'aaron:/tmp/notes-media/*' media/
   touch decisions.jsonl
   ```

2. Before serving, drop any note holding card numbers, passwords or other
   secrets from `notes.json`, and tell Étienne about it without repeating it.
3. Run `python3 server.py` from the work directory, in the background. The page
   is at `http://localhost:8765`; from another machine,
   `ssh -L 8765:localhost:8765 tower`.

## Processing

Handle each decision as soon as it lands; don't wait for the batch to end. Keep
a count of handled lines in `handled.txt` and wait for new ones in the
background:

```sh
n=$(cat handled.txt); until [ "$(wc -l < decisions.jsonl)" -gt "$n" ]; do sleep 1; done; sleep 2; tail -n +$((n + 1)) decisions.jsonl
```

Process every new line, not just the last, then update `handled.txt`.

The text field holds Étienne's instructions, often dictated: read past
transcription errors. When a note or instruction is unclear, investigate (web,
`~/sync/doc`, calendar, Gmail) and report what you found before acting.

Once a note is processed, delete it on aaron — only after its content is
confirmed saved, never in parallel with the save:

```sh
ssh aaron "osascript -l JavaScript -e 'const N=Application(\"Notes\"); N.delete(N.notes.byId(\"<id>\"))'"
```

Deleted notes sit in "Recently Deleted" for 30 days; restore one with
`N.move(note, {to: folder})` if Étienne changes his mind. "Done" means keep the
note untouched.

To put a note back on the page, remove its line from `decisions.jsonl`, adjust
`handled.txt`, and have Étienne reload.
