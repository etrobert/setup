// Flags declared packages that end up in no host system derivation.
//
// Takes the union of every host toplevel derivation closure and checks each
// package against it. Read-only — unlike the module sweep there is nothing to
// poison, so it reads the working tree directly with no worktree.

import { execFile } from "node:child_process";
import { promisify } from "node:util";

// Deliberately never installed: invoked with `nix run`. Listed rather than
// silently skipped, and reported below if one ever becomes installed.
const allow = new Set([
  "flake-input-table", // .github/workflows/update-flake.yml
  "nix-dead-packages", // .github/workflows/checks.yml
]);

const run = promisify(execFile);

// maxBuffer: a host closure listing exceeds the 1 MiB default
const sh = async (file: string, args: string[]): Promise<string> =>
  (await run(file, args, { maxBuffer: Infinity })).stdout;

const nixEval = (...args: string[]): Promise<string> =>
  sh("nix", ["eval", "--accept-flake-config", ...args]);

const names = async (attr: string): Promise<string[]> =>
  JSON.parse(await nixEval("--json", attr, "--apply", "builtins.attrNames"));

const hostClosure = async (host: string): Promise<string[]> => {
  const drv = await nixEval(
    "--raw",
    `.#${host}.config.system.build.toplevel.drvPath`,
  );
  const requisites = await sh("nix-store", ["--query", "--requisites", drv]);
  return requisites.trim().split("\n");
};

// tryEval so a package that cannot evaluate for one system does not abort the
// run; a package that evaluates for no system has no drv and is reported.
const packageDrvs = async (
  system: string,
): Promise<[string, string | null][]> =>
  Object.entries(
    JSON.parse(
      await nixEval(
        "--json",
        `.#packages.${system}`,
        "--apply",
        `ps: builtins.mapAttrs (
           _: p: let r = builtins.tryEval (p.drvPath or null); in if r.success then r.value else null
         ) ps`,
      ),
    ),
  );

const main = async (): Promise<void> => {
  process.chdir((await sh("git", ["rev-parse", "--show-toplevel"])).trim());

  const [nixos, darwin, systems] = await Promise.all([
    names(".#nixosConfigurations"),
    names(".#darwinConfigurations"),
    names(".#packages"),
  ]);
  const hosts = [
    ...nixos.map((host) => `nixosConfigurations.${host}`),
    ...darwin.map((host) => `darwinConfigurations.${host}`),
  ];

  // Every evaluation runs concurrently: each host instantiates its own nixpkgs,
  // so there is nothing to share and the run is bounded by the slowest one.
  console.error("collecting host system closures...");
  console.error("collecting package derivations...");
  const [closures, packages] = await Promise.all([
    Promise.all(hosts.map(hostClosure)),
    Promise.all(systems.map(packageDrvs)),
  ]);
  const closure = new Set(closures.flat());

  const all = new Set<string>();
  const used = new Set<string>();
  for (const [name, drv] of packages.flat()) {
    if (drv === null) continue;
    all.add(name);
    if (closure.has(drv)) used.add(name);
  }

  const reports: [string, string[]][] = [
    [
      "in no host system derivation:",
      [...all].filter((name) => !used.has(name) && !allow.has(name)),
    ],
    [
      "allowlisted but now installed — drop from the allowlist:",
      [...used].filter((name) => allow.has(name)),
    ],
    // Deleting a package would otherwise leave its allowlist entry behind
    // unnoticed, since a name that is in neither set matches nothing above.
    [
      "allowlisted but no such package — drop from the allowlist:",
      [...allow].filter((name) => !all.has(name)),
    ],
  ];

  for (const [title, names] of reports) {
    if (names.length === 0) continue;
    console.log(title);
    for (const name of names.sort()) console.log(`  ${name}`);
    process.exitCode = 1;
  }
  if (!process.exitCode) {
    console.log("every package outside the allowlist reaches a host.");
  }
};

main().catch((error: unknown) => {
  console.error(String(error));
  process.exit(1);
});
