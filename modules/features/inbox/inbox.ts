import { appendFile } from "node:fs/promises";
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

createServer(async (req, res) => {
  try {
    if (req.url !== "/") {
      res.writeHead(404).end("not found\n");
    } else if (req.method !== "POST") {
      res.writeHead(405).end("method not allowed\n");
    } else {
      const text = new URLSearchParams(await readBody(req)).get("text")?.trim();
      if (!text) {
        res.writeHead(400).end("missing form field: text\n");
        return;
      }
      await appendFile(file, entry(new Date(), text));
      res.writeHead(204).end();
    }
  } catch (err) {
    console.error(err);
    res.writeHead(500).end(`${err}\n`);
  }
}).listen(port, "127.0.0.1");
