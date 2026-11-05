import { writeFile } from "node:fs/promises";
import { createServer, type IncomingMessage } from "node:http";
import { join } from "node:path";
import { parseArgs } from "node:util";

const { values } = parseArgs({
  options: {
    port: { type: "string" },
    dir: { type: "string" },
  },
});
if (values.port === undefined || values.dir === undefined) {
  throw new Error("--port and --dir are required");
}
const port = Number(values.port);
const dir = values.dir;

const pad = (n: number) => String(n).padStart(2, "0");

const fileName = (now: Date) =>
  `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}T${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}.md`;

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
      const text = (await readBody(req)).trim();
      if (!text) {
        res.writeHead(400).end("empty body\n");
        return;
      }
      const name = fileName(new Date());
      try {
        // "wx" fails if the file already exists.
        await writeFile(join(dir, name), `${text}\n`, { flag: "wx" });
      } catch (err) {
        if ((err as NodeJS.ErrnoException).code !== "EEXIST") throw err;
        res.writeHead(409).end(`${name} already exists, try again\n`);
        return;
      }
      res.writeHead(201).end();
    }
  } catch (err) {
    console.error(err);
    res.writeHead(500).end(`${err}\n`);
  }
}).listen(port, "127.0.0.1");
