import { appendFile, readFile } from "node:fs/promises";
import { createServer, type IncomingMessage } from "node:http";
import { parseArgs } from "node:util";

const { values } = parseArgs({
  options: {
    port: { type: "string" },
    file: { type: "string" },
  },
});
if (values.port === undefined || values.file === undefined) {
  throw new Error("--port and --file are required");
}
const port = Number(values.port);
const file = values.file;

const escapeHtml = (s: string) =>
  s.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");

const page = (content: string) => `<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Inbox</title>
<style>
  :root { color-scheme: light dark; }
  body { font: 1.1rem system-ui, sans-serif; max-width: 40rem; margin: 1rem auto; padding: 0 1rem; }
  textarea { width: 100%; box-sizing: border-box; font: inherit; }
  pre { white-space: pre-wrap; }
</style>
<form method="post">
  <textarea name="text" rows="4" required autofocus></textarea>
  <button>Capture</button>
</form>
<pre>${escapeHtml(content)}</pre>
`;

const pad = (n: number) => String(n).padStart(2, "0");

// One Markdown list item, continuation lines indented.
const entry = (now: Date, text: string) => {
  const stamp = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}`;
  return `- ${stamp} ${text.replaceAll("\r\n", "\n").replaceAll("\n", "\n  ")}\n`;
};

const readBody = async (req: IncomingMessage) => {
  let body = "";
  for await (const chunk of req) body += chunk;
  return body;
};

const readInbox = async () => {
  try {
    return await readFile(file, "utf8");
  } catch (err) {
    if ((err as NodeJS.ErrnoException).code === "ENOENT") return "";
    throw err;
  }
};

createServer(async (req, res) => {
  try {
    if (req.url !== "/") {
      res.writeHead(404).end("not found\n");
    } else if (req.method === "GET") {
      res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
      res.end(page(await readInbox()));
    } else if (req.method === "POST") {
      const text = new URLSearchParams(await readBody(req)).get("text")?.trim();
      if (!text) {
        res.writeHead(400).end("missing form field: text\n");
        return;
      }
      await appendFile(file, entry(new Date(), text));
      res.writeHead(303, { Location: "/" }).end();
    } else {
      res.writeHead(405).end("method not allowed\n");
    }
  } catch (err) {
    console.error(err);
    res.writeHead(500).end(`${err}\n`);
  }
}).listen(port, "127.0.0.1");
