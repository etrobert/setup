// Flags declared packages that end up in no host system derivation.
//
// Takes the union of every host toplevel derivation closure and checks each
// package against it. Read-only — unlike the module sweep there is nothing to
// poison, so it reads the working tree directly with no worktree.
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"sort"
	"strings"
	"sync"
)

// Deliberately never installed: invoked with `nix run`. Listed rather than
// silently skipped, and reported below if one ever becomes installed.
var allow = map[string]bool{
	"flake-input-table": true, // .github/workflows/update-flake.yml
	"nix-dead-packages": true, // .github/workflows/checks.yml
}

// tryEval so a package that cannot evaluate for one system does not abort the
// run; a package that evaluates for no system has no drv and is reported.
const drvPaths = `ps: builtins.mapAttrs (
  _: p: let r = builtins.tryEval (p.drvPath or null); in if r.success then r.value else null
) ps`

func run(ctx context.Context, name string, args ...string) ([]byte, error) {
	cmd := exec.CommandContext(ctx, name, args...)
	cmd.Stderr = os.Stderr
	return cmd.Output()
}

func nixEval(ctx context.Context, args ...string) ([]byte, error) {
	return run(ctx, "nix", append([]string{"eval", "--accept-flake-config"}, args...)...)
}

func names(attr string) []string {
	out, err := nixEval(context.Background(), "--json", ".#"+attr, "--apply", "builtins.attrNames")
	if err != nil {
		fail(fmt.Errorf("%s: evaluation failed", attr))
	}
	var names []string
	if err := json.Unmarshal(out, &names); err != nil {
		fail(err)
	}
	return names
}

// parallel runs the tasks concurrently and returns the first error; the
// context kills every task still running so none outlives the failure.
func parallel(tasks []func(context.Context) error) error {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	// The failure is sent before its siblings are killed, so it is read first.
	errs := make(chan error, len(tasks))
	var wg sync.WaitGroup
	for _, task := range tasks {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if err := task(ctx); err != nil {
				errs <- err
				cancel()
			}
		}()
	}
	wg.Wait()
	close(errs)
	return <-errs
}

func fail(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(1)
}

func report(title string, names []string) bool {
	if len(names) == 0 {
		return false
	}
	sort.Strings(names)
	fmt.Println(title)
	for _, name := range names {
		fmt.Println("  " + name)
	}
	return true
}

func main() {
	root, err := run(context.Background(), "git", "rev-parse", "--show-toplevel")
	if err != nil {
		fail(err)
	}
	if err := os.Chdir(strings.TrimSpace(string(root))); err != nil {
		fail(err)
	}

	var hosts []string
	for _, output := range []string{"nixosConfigurations", "darwinConfigurations"} {
		for _, host := range names(output) {
			hosts = append(hosts, output+"."+host)
		}
	}
	systems := names("packages")

	// Every evaluation runs concurrently: each host instantiates its own
	// nixpkgs, so there is nothing to share and the run is bounded by the
	// slowest one.
	// --no-eval-cache: concurrent writers to the cache trip SQLITE_BUSY, which
	// nix logs as an error and ignores; the cache holds nothing for these
	// paths anyway.
	closures := make([][]string, len(hosts))
	packages := make([]map[string]*string, len(systems))
	var tasks []func(context.Context) error
	for i, host := range hosts {
		tasks = append(tasks, func(ctx context.Context) error {
			drv, err := nixEval(ctx, "--raw", "--no-eval-cache",
				".#"+host+".config.system.build.toplevel.drvPath")
			if err != nil {
				return fmt.Errorf("%s: evaluation failed", host)
			}
			out, err := run(ctx, "nix-store", "--query", "--requisites", string(drv))
			if err != nil {
				return fmt.Errorf("%s: closure query failed", host)
			}
			closures[i] = strings.Fields(string(out))
			return nil
		})
	}
	for i, system := range systems {
		tasks = append(tasks, func(ctx context.Context) error {
			out, err := nixEval(ctx, "--json", "--no-eval-cache",
				".#packages."+system, "--apply", drvPaths)
			if err != nil {
				return fmt.Errorf("packages.%s: evaluation failed", system)
			}
			return json.Unmarshal(out, &packages[i])
		})
	}
	fmt.Fprintln(os.Stderr, "collecting host system closures...")
	fmt.Fprintln(os.Stderr, "collecting package derivations...")
	if err := parallel(tasks); err != nil {
		fail(err)
	}

	closure := map[string]bool{}
	for _, paths := range closures {
		for _, path := range paths {
			closure[path] = true
		}
	}
	all, used := map[string]bool{}, map[string]bool{}
	for _, drvs := range packages {
		for name, drv := range drvs {
			if drv == nil {
				continue
			}
			all[name] = true
			if closure[*drv] {
				used[name] = true
			}
		}
	}

	var flagged, stale, gone []string
	for name := range all {
		switch {
		case !used[name] && !allow[name]:
			flagged = append(flagged, name)
		case used[name] && allow[name]:
			stale = append(stale, name)
		}
	}
	// Deleting a package would otherwise leave its allowlist entry behind
	// unnoticed, since a name that is no longer in `all` matches nothing above.
	for name := range allow {
		if !all[name] {
			gone = append(gone, name)
		}
	}

	status := 0
	if report("in no host system derivation:", flagged) {
		status = 1
	}
	if report("allowlisted but now installed — drop from the allowlist:", stale) {
		status = 1
	}
	if report("allowlisted but no such package — drop from the allowlist:", gone) {
		status = 1
	}
	if status == 0 {
		fmt.Println("every package outside the allowlist reaches a host.")
	}
	os.Exit(status)
}
