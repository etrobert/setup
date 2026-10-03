//! Flags declared packages that end up in no host system derivation.
//!
//! Takes the union of every host toplevel derivation closure and checks each
//! package against it. Read-only — unlike the module sweep there is nothing to
//! poison, so it reads the working tree directly with no worktree.

use std::collections::{BTreeSet, HashSet};
use std::io::Read;
use std::process::{self, Child, Command, ExitCode, Stdio};
use std::sync::mpsc;
use std::thread;

// Deliberately never installed: invoked with `nix run`. Listed rather than
// silently skipped, and reported below if one ever becomes installed.
const ALLOW: &[&str] = &[
    "flake-input-table", // .github/workflows/update-flake.yml
    "nix-dead-packages", // .github/workflows/checks.yml
];

const NAMES: &str = r#"x: builtins.concatStringsSep "\n" (builtins.attrNames x)"#;

// tryEval so a package that cannot evaluate for one system does not abort the
// run; a package that evaluates for no system has no drv line and is reported.
const PACKAGE_DRVS: &str = r#"ps: builtins.concatStringsSep "\n" (builtins.filter (l: l != null) (
  builtins.attrValues (builtins.mapAttrs (name: p:
    let r = builtins.tryEval (p.drvPath or null);
    in if r.success && r.value != null then "${name} ${r.value}" else null
  ) ps)))"#;

struct Job {
    label: String,
    command: Command,
}

fn fail(message: &str) -> ! {
    eprintln!("{message}");
    process::exit(1);
}

// --no-eval-cache: concurrent writers to the cache trip SQLITE_BUSY, which nix
// logs as an error and ignores; the cache holds nothing for these paths anyway.
fn nix_eval(attr: &str, apply: &str) -> Job {
    let mut command = Command::new("nix");
    command.args(["eval", "--raw", "--accept-flake-config", "--no-eval-cache"]);
    command.args([attr, "--apply", apply]);
    Job {
        label: format!("nix eval {attr}"),
        command,
    }
}

fn nix_store_requisites(drv: &str) -> Job {
    let mut command = Command::new("nix-store");
    command.args(["--query", "--requisites", drv]);
    Job {
        label: format!("nix-store --query --requisites {drv}"),
        command,
    }
}

/// Runs every job concurrently and returns their stdout in job order. The
/// first failure kills the rest: stderr is inherited, so the tool has already
/// said why.
fn run(mut jobs: Vec<Job>) -> Vec<String> {
    let mut children: Vec<Child> = jobs
        .iter_mut()
        .map(|job| {
            job.command
                .stdout(Stdio::piped())
                .spawn()
                .unwrap_or_else(|e| fail(&format!("{}: {e}", job.label)))
        })
        .collect();
    let mut outputs = vec![String::new(); jobs.len()];
    let (tx, rx) = mpsc::channel();
    thread::scope(|scope| {
        for (i, child) in children.iter_mut().enumerate() {
            let mut stdout = child.stdout.take().expect("stdout is piped");
            let tx = tx.clone();
            scope.spawn(move || {
                let mut text = String::new();
                let read = stdout.read_to_string(&mut text).map(|_| text);
                tx.send((i, read))
                    .expect("main thread outlives the readers");
            });
        }
        drop(tx);
        for (i, read) in rx {
            let label = &jobs[i].label;
            let status = children[i]
                .wait()
                .unwrap_or_else(|e| fail(&format!("{label}: {e}")));
            if !status.success() {
                for child in &mut children {
                    let _ = child.kill();
                }
                fail(&format!("{label}: {status}"));
            }
            outputs[i] = read.unwrap_or_else(|e| fail(&format!("{label}: reading stdout: {e}")));
        }
    });
    outputs
}

fn main() -> ExitCode {
    let toplevel = Command::new("git")
        .args(["rev-parse", "--show-toplevel"])
        .output()
        .unwrap_or_else(|e| fail(&format!("git rev-parse --show-toplevel: {e}")));
    if !toplevel.status.success() {
        fail(&format!(
            "git rev-parse --show-toplevel: {}",
            toplevel.status
        ));
    }
    let root = String::from_utf8_lossy(&toplevel.stdout);
    std::env::set_current_dir(root.trim())
        .unwrap_or_else(|e| fail(&format!("cd {}: {e}", root.trim())));

    let names = run(vec![
        nix_eval(".#nixosConfigurations", NAMES),
        nix_eval(".#darwinConfigurations", NAMES),
        nix_eval(".#packages", NAMES),
    ]);
    let hosts: Vec<String> = ["nixosConfigurations", "darwinConfigurations"]
        .iter()
        .zip(&names)
        .flat_map(|(output, list)| {
            list.lines()
                .map(move |host| format!(".#{output}.{host}.config.system.build.toplevel"))
        })
        .collect();
    let systems: Vec<&str> = names[2].lines().collect();

    // Every evaluation runs concurrently: each host instantiates its own
    // nixpkgs, so there is nothing to share and the run is bounded by the
    // slowest one.
    eprintln!("collecting host system closures...");
    eprintln!("collecting package derivations...");
    let outputs = run(hosts
        .iter()
        .map(|host| nix_eval(host, "toplevel: toplevel.drvPath"))
        .chain(
            systems
                .iter()
                .map(|system| nix_eval(&format!(".#packages.{system}"), PACKAGE_DRVS)),
        )
        .collect());
    let (toplevels, packages) = outputs.split_at(hosts.len());

    let requisites = run(toplevels
        .iter()
        .map(|drv| nix_store_requisites(drv))
        .collect());
    let closure: HashSet<&str> = requisites.iter().flat_map(|r| r.lines()).collect();

    let mut all = BTreeSet::new();
    let mut used = BTreeSet::new();
    for line in packages.iter().flat_map(|p| p.lines()) {
        let (name, drv) = line
            .split_once(' ')
            .unwrap_or_else(|| fail(&format!("unexpected package line: {line}")));
        all.insert(name);
        if closure.contains(drv) {
            used.insert(name);
        }
    }
    let allow: BTreeSet<&str> = ALLOW.iter().copied().collect();
    let flagged: Vec<&str> = all
        .difference(&used)
        .filter(|name| !allow.contains(*name))
        .copied()
        .collect();
    let stale: Vec<&str> = used.intersection(&allow).copied().collect();
    // A deleted package is in neither `used` nor `all`, so its allowlist entry
    // would otherwise linger unnoticed.
    let gone: Vec<&str> = allow.difference(&all).copied().collect();

    let mut failed = false;
    for (heading, names) in [
        ("in no host system derivation:", flagged),
        (
            "allowlisted but now installed — drop from the allowlist:",
            stale,
        ),
        (
            "allowlisted but no such package — drop from the allowlist:",
            gone,
        ),
    ] {
        if names.is_empty() {
            continue;
        }
        println!("{heading}");
        for name in names {
            println!("  {name}");
        }
        failed = true;
    }

    if failed {
        return ExitCode::FAILURE;
    }
    println!("every package outside the allowlist reaches a host.");
    ExitCode::SUCCESS
}
