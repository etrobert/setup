"""Flags declared packages that end up in no host system derivation.

Takes the union of every host toplevel derivation closure and checks each
package against it. Read-only — unlike the module sweep there is nothing to
poison, so it reads the working tree directly with no worktree.
"""

import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

# Deliberately never installed: invoked with `nix run`. Listed rather than
# silently skipped, and reported below if one ever becomes installed.
ALLOW = {
    "flake-input-table",  # .github/workflows/update-flake.yml
    "nix-dead-packages",  # .github/workflows/checks.yml
}

# tryEval so a package that cannot evaluate for one system does not abort the
# run; a package that evaluates for no system has no drv and is reported.
DRV_PATHS = """
ps: builtins.mapAttrs (_: p:
  let r = builtins.tryEval (p.drvPath or null);
  in if r.success then r.value else null
) ps
"""


def run(*argv):
    return subprocess.run(argv, check=True, stdout=subprocess.PIPE, text=True).stdout


def nix_eval(attr, *flags):
    return run("nix", "eval", "--accept-flake-config", f".#{attr}", *flags)


def names(attr):
    return json.loads(nix_eval(attr, "--json", "--apply", "builtins.attrNames"))


def host_closure(host):
    drv = nix_eval(f"{host}.config.system.build.toplevel.drvPath", "--raw")
    return set(run("nix-store", "--query", "--requisites", drv).split())


def package_drvs(system):
    drvs = json.loads(nix_eval(f"packages.{system}", "--json", "--apply", DRV_PATHS))
    return {name: drv for name, drv in drvs.items() if drv is not None}


def result(label, future):
    try:
        return future.result()
    except subprocess.CalledProcessError:
        sys.exit(f"{label}: evaluation failed")


def main():
    os.chdir(run("git", "rev-parse", "--show-toplevel").strip())

    # Every evaluation runs concurrently: each host instantiates its own
    # nixpkgs, so there is nothing to share and the run is bounded by the
    # slowest one.
    with ThreadPoolExecutor() as pool:
        print("collecting host system closures...", file=sys.stderr)
        hosts = [
            f"{output}.{host}"
            for output in ("nixosConfigurations", "darwinConfigurations")
            for host in names(output)
        ]
        closures = {host: pool.submit(host_closure, host) for host in hosts}

        print("collecting package derivations...", file=sys.stderr)
        packages = {
            system: pool.submit(package_drvs, system) for system in names("packages")
        }

        closure = set().union(*(result(h, f) for h, f in closures.items()))
        drvs = {}
        for system, future in packages.items():
            for name, drv in result(system, future).items():
                drvs.setdefault(name, set()).add(drv)

    used = {name for name, paths in drvs.items() if paths & closure}
    reports = [
        ("in no host system derivation:", drvs.keys() - used - ALLOW),
        ("allowlisted but now installed — drop from the allowlist:", used & ALLOW),
        # Deleting a package would otherwise leave its allowlist entry behind
        # unnoticed, since a name in neither `used` nor `unused` matches nothing.
        (
            "allowlisted but no such package — drop from the allowlist:",
            ALLOW - drvs.keys(),
        ),
    ]

    status = 0
    for title, found in reports:
        if found:
            print(title)
            for name in sorted(found):
                print(f"  {name}")
            status = 1

    if status == 0:
        print("every package outside the allowlist reaches a host.")

    sys.exit(status)


main()
