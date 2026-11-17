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
    const text = (await readBody(req)).trim();
    if (!text) {
      res.writeHead(400).end("empty body\n");
      return;
    }
    // "wx" fails if the file already exists.
    await writeFile(join(dir, fileName(new Date())), `${text}\n`, {
      flag: "wx",
    });
    res.end();
  } catch (err) {
    console.error(err);
    res.writeHead(500).end(`${err}\n`);
  }
}).listen(port, "127.0.0.1");
