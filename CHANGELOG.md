# Changelog

All notable changes to `mac-anatomy` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-21

Initial release.

### Added
- `overview` subcommand — macOS version, boot volume status (sealed SSV
  detection), disk usage, SIP status, root-layout summary, next-steps
  pointer.
- `volumes` subcommand — parsed `diskutil apfs list` output with a
  quick-reference legend explaining role columns (System / Data / VM /
  Preboot / Recovery / Update). `--json` returns the full `plutil`
  conversion of `diskutil apfs list -plist`.
- `firmlinks` subcommand — reads `/usr/share/firmlinks` and explains
  the synthetic-root → Data volume mapping mechanism. `--json` emits a
  structured array.
- `symlinks` subcommand — root-level symlinks resolved, with hand-curated
  annotations for the legacy NeXTSTEP/BSD paths (`/etc`, `/var`, `/tmp`,
  `/home`, `.VolumeIcon.icns`). `--json` supported.
- `sip` subcommand — current SIP state plus a structured explanation of
  what SIP actually protects (filesystem, NVRAM, kexts, debugging, task
  inspection) and the Recovery-mode disable / enable workflow.
- `setuid` subcommand — sorted list of setuid / setgid binaries in
  `/usr/bin`, `/usr/sbin`, `/bin`, `/sbin`, `/usr/libexec`. `--json`
  supported.
- `world-writable` subcommand (alias `ww`) — searches a narrow set of
  critical system directories (system binaries, `/etc`, system
  frameworks and extensions, launchd agents/daemons) for files with the
  0002 perm bit set. `--json` supported.
- `tree` subcommand — ASCII tree of `/` to depth N (default 2, max 6).
  Prefers Homebrew `tree` at `/usr/local/bin` or `/opt/homebrew/bin`
  over PATH (avoids eza-aliased `tree`). Falls back to `find` + awk
  indent if no real `tree` is installed.
- `doctor` subcommand — seven graded health checks (SSV sealed, SIP
  enabled, no world-writable in critical dirs, root symlinks resolve,
  firmlinks file present, SSV snapshots exist, Data volume writable).
  Exit codes 0/1/2 by severity. `--json` supported.
- `report` subcommand — generates a self-contained HTML report
  combining every section. Light/dark color-scheme adaptive. `--open`
  flag to launch in the default browser.
- Global flags: `--json`, `--no-color`, `--quiet`/`-q`, `--verbose`/`-v`,
  `--open`, `--version`, `--help`/`-h`.
- Bash 3.2 compatibility — no associative arrays, no `mapfile`, no
  `${var^^}`. Runs on stock macOS bash so users don't need to
  `brew install bash` first.
- bats test suite covering smoke (version/help/unknown flags), each
  subcommand's basic operation, and JSON-output validity.
- GitHub Actions CI matrix on `macos-14`, `macos-15`, and `macos-latest`
  with `shellcheck --severity=error` linting and the full bats run.
- `install.sh` symlinks the binary and man page into `$PREFIX/bin` and
  `$PREFIX/share/man/man1` (default `$HOME/.local`). `--uninstall`
  reverses the operation.
- Full `man mac-anatomy(1)` page describing every subcommand and flag.
- Special-casing for `.VolumeIcon.icns` in the broken-symlink check —
  it's a fixed pointer that's only valid when the volume has a custom
  Finder icon set, so doctor doesn't flag it as a fault by default.

[Unreleased]: https://github.com/NewdlDewdl/mac-anatomy/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/NewdlDewdl/mac-anatomy/releases/tag/v0.1.0
