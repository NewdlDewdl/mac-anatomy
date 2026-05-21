# Contributing to mac-anatomy

Thanks for considering a contribution. This document covers how the
project is structured, the conventions it follows, and what kind of
changes are likely to land.

## Scope

`mac-anatomy` is a focused, read-only inspection tool for the macOS root
filesystem. The contract:

- **No filesystem modifications, ever.** Every subcommand reads.
  Nothing writes (other than the optional HTML report file the user
  explicitly named or accepted as a default in `/tmp`).
- **No external dependencies at runtime.** Stock macOS bash 3.2, stock
  `find`, `awk`, `sed`, `diskutil`, `csrutil`, `mount`, `sw_vers`. The
  `tree` subcommand will use Homebrew `tree` if installed but degrades
  gracefully without it.
- **One single file in `bin/`.** Easy to audit, easy to install, easy
  to symlink. Splitting into a `lib/` hierarchy would force users to
  install more than just the script.

## Testing

Tests live in `tests/` and use [bats-core](https://github.com/bats-core/bats-core).

Install locally:

```sh
brew install bats-core
```

Run:

```sh
bats tests/
```

CI runs the same suite on `macos-14`, `macos-15`, and `macos-latest`
plus a `shellcheck --severity=error` pass.

When adding a subcommand:

1. Add a smoke test in [smoke.bats](tests/smoke.bats) (help, exit
   codes) if it surfaces in `--help`.
2. Add at least one functional test in
   [subcommands.bats](tests/subcommands.bats) — must invoke the
   subcommand and assert a sentinel string in the output that's
   plausibly stable across macOS versions.
3. If the subcommand accepts `--json`, add a corresponding test in
   [json.bats](tests/json.bats) that verifies the output parses with
   `python3 -m json.tool`.

## Style

The script is written to match the conventions of the related
`*-doctor` family (`mac-doctor`, `finder-doctor`, `disk-doctor`,
`startup-doctor`, `monitor-info`):

- `#!/usr/bin/env bash` shebang, `set -uo pipefail` at the top.
- ANSI colors gated on `[[ -t 1 ]] && (( NO_COLOR == 0 ))`.
- Subcommands as `cmd_<name>()` functions, dispatched by a top-level
  `main()` argv parser.
- Section markers use the heavy box-drawing comment style:
  `# ─── colors ─────────────────────────`.
- Long story-telling header comment explaining *why* the tool exists.
- "Built for Rohin Agrawal" or similar attribution at the bottom is
  encouraged, even on contributed changes — it's a small personal-tools
  family.

## Bash 3.2 compatibility

macOS ships `/bin/bash` 3.2.57 and won't update it for licensing
reasons. We target that version so users don't have to
`brew install bash`. Avoid:

- `declare -A` associative arrays (use case-statement helpers).
- `mapfile` / `readarray` (use `while read -r ; do … done < <(...)`).
- `${var^^}` / `${var,,}` (use `tr`).
- `**` recursive glob (use `find`).
- `${arr[@]}` expansion on an empty array under `set -u` — use
  `${arr[@]+"${arr[@]}"}` or guard with `(( ${#arr[@]} > 0 ))`.

CI will catch most of these via shellcheck and via the smoke tests
running on the stock macOS bash.

## Submitting changes

1. Fork, create a feature branch.
2. Keep changes small and focused. One new subcommand or one fix per
   PR.
3. Update the man page (`man/mac-anatomy.1`) and the CHANGELOG when
   user-visible behavior changes.
4. Make sure `bats tests/` passes locally and ` ./bin/mac-anatomy --help`
   still renders cleanly.
5. PR description: include a sample of the new output. For doctor
   checks, include both a healthy-state and warning/critical-state
   example.

## License

By submitting a contribution you agree it will be released under the
MIT license. See [LICENSE](LICENSE).
