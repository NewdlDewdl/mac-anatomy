# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`mac-anatomy` is a single-file, read-only bash CLI that maps and audits the
macOS root filesystem (the Big Sur+ two-volume layout: sealed read-only System
volume + writable Data volume firmlinked into one namespace). The entire
program is `bin/mac-anatomy`. Everything else is docs, tests, packaging, and
the man page.

## Commands

```sh
bats tests/                       # run the whole test suite
bats tests/smoke.bats             # run one test file
bats --filter "doctor" tests/     # run tests whose name matches a regex
bats --tap tests/                 # TAP output (what CI uses)

shellcheck --severity=error bin/mac-anatomy   # lint (CI fails on errors)
shellcheck bin/mac-anatomy                    # full lint (warnings allowed)

./bin/mac-anatomy --help          # run directly without installing
./bin/mac-anatomy --no-color doctor
./install.sh                      # symlink into $HOME/.local; --uninstall to remove
```

`bats` and `shellcheck` come from `brew install bats-core shellcheck`. The tool
itself has **zero runtime dependencies** beyond stock macOS utilities.

Note: the subcommands call live macOS tooling (`diskutil`, `csrutil`, `mount`,
`sw_vers`, `find /`) and exit early via `require_macos` on non-Darwin hosts, so
functional behavior can only be exercised on a real Mac — including in this
Linux environment, where `require_macos` will abort. Edit and shellcheck here;
rely on CI (macos-14/15/latest runners) to validate runtime behavior.

## Architecture

Single executable, structured as:

- **`main()`** (bottom of file): a hand-rolled argv parser that sets global
  flag variables (`JSON`, `QUIET`, `VERBOSE`, `NO_COLOR`, `OPEN_REPORT`), then
  dispatches the first non-flag token to a `cmd_<name>` function. Default
  subcommand is `overview`. `world-writable` has alias `ww`.
- **`cmd_<name>()` functions**: one per subcommand (`overview`, `volumes`,
  `firmlinks`, `symlinks`, `sip`, `setuid`, `world_writable`, `tree`, `doctor`,
  `report`). Each is self-contained.
- **Shared helpers**: `header`/`note`/`err`/`die` (formatted output),
  `setup_colors` (gates ANSI on `[[ -t 1 ]] && NO_COLOR==0`), `require_macos`,
  `html_escape`, `safe_capture` (runs a command swallowing failure, used so one
  failing section can't abort the HTML report).

Two cross-cutting conventions to preserve when editing:

- **`--json` is a branch inside each subcommand**, emitted by hand-rolled
  `printf` (no `jq`/`python`), and must be the *only* thing on stdout — no
  headers, color, or log lines. Each subcommand that supports JSON has a
  matching test in `tests/json.bats` that pipes output through `python3` to
  confirm it parses. Supported on: `doctor`, `volumes`, `firmlinks`,
  `symlinks`, `setuid`, `world-writable`.
- **`cmd_report`** generates a single-file HTML report by re-running every
  other `cmd_*` via `safe_capture` with `QUIET=1 NO_COLOR=1` forced, escaping
  the captured text into `<pre>` blocks. Adding a subcommand means adding a
  capture call and a `<h2>`/`<nav>` entry here too.

`doctor` is the only subcommand with a **meaningful exit code**: 0 healthy, 1
warnings, 2 critical (SSV not sealed). It accumulates `SEV|message` findings in
an array and computes the max severity. Note two deliberate special-cases in
the checks: `/.VolumeIcon.icns` is allowed to be a dangling symlink (normal on
default installs), and the world-writable scan uses a **deliberately narrow**
path list (system bin dirs, `/etc`, core `/System/Library` subdirs) — scanning
all of `/System` or `/usr` drowns real findings in third-party `.app`/`.bundle`
package-hygiene noise. Keep that scope narrow.

## Hard constraints

These are the project's contract, not preferences — violating them breaks the
reason the tool exists:

- **Read-only, always.** No subcommand may modify the filesystem. The only
  permitted writes are the user-named (or `/tmp` default) HTML report file, and
  `doctor`'s single `touch`+`rm` of `/private/tmp/.mac-anatomy-write-test` to
  probe Data-volume writability. Never add `sudo`.
- **bash 3.2 compatible.** macOS ships `/bin/bash` 3.2.57 and won't update it.
  Avoid `declare -A`, `mapfile`/`readarray`, `${var^^}`/`${var,,}`, `**`
  recursive globs. Use `while read -r … done < <(...)` instead of `mapfile`,
  case-statement helpers instead of associative arrays, `tr` for case folding.
  Under `set -u`, expand possibly-empty arrays as `"${arr[@]+"${arr[@]}"}"` or
  guard with `(( ${#arr[@]} > 0 ))`.
- **One file in `bin/`.** Do not split into a `lib/` hierarchy — the install
  story is "symlink one script."
- **Zero runtime deps.** Only stock macOS tools. `tree` opportunistically uses
  Homebrew `tree` (checked at known paths, not `$PATH`, because eza aliases
  `tree`) but degrades to a `find`+`awk` fallback.

## When adding or changing a subcommand

Per `CONTRIBUTING.md`, keep these in sync:

1. Add the `cmd_<name>` function and a `main()` dispatch case.
2. Add it to `cmd_help` and the header comment block at the top of the script.
3. Smoke test in `tests/smoke.bats` if it surfaces in `--help`; a functional
   test in `tests/subcommands.bats` asserting a stable sentinel string; and if
   it supports `--json`, a parse test in `tests/json.bats`.
4. Wire it into `cmd_report` (capture call + `<h2>`/`<nav>`).
5. Update `man/mac-anatomy.1`, `README.md`, and `CHANGELOG.md` for any
   user-visible change.

Functional tests assert section headers / structural strings rather than exact
values, since output varies by host and macOS version. Stick to that pattern.

## Style

`#!/usr/bin/env bash` + `set -uo pipefail`; subcommands as `cmd_<name>()`;
heavy box-drawing section markers (`# ─── name ───`); a long "why this exists"
story comment at the top. The tool is part of a stylistically-matched family of
single-file macOS utilities (`mac-doctor`, `finder-doctor`, `disk-doctor`,
`startup-doctor`, `monitor-info`) — match their conventions.
