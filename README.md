# mac-anatomy

> Map and audit the macOS root filesystem.

[![ci](https://github.com/NewdlDewdl/mac-anatomy/actions/workflows/ci.yml/badge.svg)](https://github.com/NewdlDewdl/mac-anatomy/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-11+-black.svg)](#)

A read-only inspection tool for the macOS root volume. Explains the
two-volume Big Sur+ layout (sealed System volume + writable Data
volume firmlinked into one namespace), audits the filesystem for
surprising state, generates a single-file HTML report. Pure bash,
zero runtime dependencies, runs on stock macOS bash 3.2.

```
$ mac-anatomy

── macOS ──
  ProductName:		macOS
  ProductVersion:	26.2
  BuildVersion:		25C56
  Architecture:   arm64

── Boot volume ──
  /dev/disk3s1s1 on / (apfs, sealed, local, read-only, journaled)
  ✓ System volume is sealed (Signed System Volume, verified at boot)

── SIP ──
  System Integrity Protection status: enabled.

── Root layout summary ──
  Directories:   16
  Symlinks:      5
  Files:         1
  Firmlinks:     18 (from /usr/share/firmlinks)
```

---

## Why this exists

Try `git init /` on macOS 11+ and you get `Read-only file system`. Not
a permissions problem — the root volume is a **sealed**, **read-only**
APFS volume by design, cryptographically verified at every boot. The
dirs that *look* writable from `ls /` (`/Applications`, `/Users`,
`/Library`) are actually **firmlinks** that transparently redirect to a
separate **Data volume** mounted at `/System/Volumes/Data`. Layer in
the legacy NeXTSTEP symlinks (`/etc → /private/etc`, `/var →
/private/var`, `/tmp → /private/tmp`) and SIP-protected paths that
even `sudo` can't write to, and the macOS root is meaningfully harder
to reason about than `ls -la /` suggests.

`mac-anatomy` maps that layout in place, with annotations, and audits
it for surprises (broken symlinks, world-writable system files,
missing snapshots, SIP turned off).

## Install

### One-liner

```sh
git clone https://github.com/NewdlDewdl/mac-anatomy.git && \
  cd mac-anatomy && ./install.sh
```

This symlinks `bin/mac-anatomy` and `man/mac-anatomy.1` into
`$HOME/.local/{bin,share/man/man1}`. Override with `PREFIX=/usr/local
./install.sh` if you want it system-wide.

### Manual

```sh
git clone https://github.com/NewdlDewdl/mac-anatomy.git
ln -s "$PWD/mac-anatomy/bin/mac-anatomy" /usr/local/bin/mac-anatomy
ln -s "$PWD/mac-anatomy/man/mac-anatomy.1" /usr/local/share/man/man1/mac-anatomy.1
```

### Verify

```sh
mac-anatomy --version
mac-anatomy doctor
```

## Usage

```
mac-anatomy [global-flags] <subcommand> [args]
```

| Subcommand        | What it does                                                          |
| ----------------- | --------------------------------------------------------------------- |
| `overview`        | Default. macOS version, boot volume, SIP, root layout.                |
| `volumes`         | Parsed `diskutil apfs list` — containers, volumes, roles.             |
| `firmlinks`       | `/usr/share/firmlinks` resolved with explanations.                    |
| `symlinks`        | Root-level symlinks annotated with their NeXTSTEP/BSD origins.        |
| `sip`             | SIP status + description of what SIP actually protects.               |
| `setuid`          | Setuid/setgid binaries in system bin dirs. Surprises = red flags.     |
| `world-writable`  | Audit critical system dirs for 0002-perm files. Alias: `ww`.          |
| `tree [depth]`    | ASCII tree of `/` to depth N (default 2, max 6).                      |
| `doctor`          | Seven graded health checks. Exit code 0/1/2 by severity.              |
| `report [path]`   | Single-file HTML report of every section.                             |

### Global flags

| Flag           | Effect                                                            |
| -------------- | ----------------------------------------------------------------- |
| `--json`       | Machine-readable output (subcommands that support it).            |
| `--no-color`   | Disable ANSI colors even on a TTY.                                |
| `--quiet`, `-q`| Suppress section headers.                                         |
| `--open`       | (with `report`) Open generated HTML in default browser.           |
| `--version`    | Print version and exit.                                           |
| `--help`, `-h` | Print usage and exit.                                             |

## Examples

### Health check (with shell exit code)

```sh
$ mac-anatomy doctor

── mac-anatomy doctor ──
  ✓ SSV is sealed (boot-time signature verified)
  ✓ SIP is enabled
  ✓ No world-writable files in critical system dirs
  ✓ All root-level symlinks resolve
  ✓ /usr/share/firmlinks present (18 entries)
  ℹ No SSV snapshots visible (non-snapshot boot, or restricted access)
  ✓ Data volume reachable + writable (touched /private/tmp)

  Status: healthy (exit 0)
```

Exit codes: `0` healthy · `1` warnings · `2` critical (e.g., SSV not
sealed). Wire into a shell pipeline:

```sh
mac-anatomy doctor --no-color > "$HOME/mac-anatomy-$(date +%F).log" \
  || mail -s "Mac health check: warnings" you@example.com < "$HOME/..."
```

### What's actually on the Data volume

```sh
$ mac-anatomy firmlinks
```

Pulls `/usr/share/firmlinks`, formats each row, and explains the
synthetic-root → Data mechanism:

```
── Firmlinks: synthetic root → Data volume ──
  /AppleInternal                   → /System/Volumes/Data/AppleInternal
  /Applications                    → /System/Volumes/Data/Applications
  /Library                         → /System/Volumes/Data/Library
  /Users                           → /System/Volumes/Data/Users
  /opt                             → /System/Volumes/Data/opt
  /usr/local                       → /System/Volumes/Data/usr/local
  ...
```

### Annotated root symlinks

```sh
$ mac-anatomy symlinks

── Root-level symlinks ──
  .VolumeIcon.icns       → System/Volumes/Data/.VolumeIcon.icns
    icon shown for the volume in Finder; lives on Data
  etc                    → private/etc
    legacy NeXTSTEP/BSD location; real config in /private/etc
  home                   → /System/Volumes/Data/home
    auto_home automounter target; historically used for NFS-mounted homes
  tmp                    → private/tmp
    legacy; real scratch in /private/tmp (cleared on reboot via launchd)
  var                    → private/var
    legacy; real spool/state/log in /private/var
```

### HTML report

```sh
mac-anatomy report --open
```

Generates a single-file HTML with every section combined, opens in
the default browser. No JS, no external assets — paste-able, sharable,
adapts to system light/dark scheme. A sample is committed under
[examples/](examples/).

### Machine-readable output

```sh
$ mac-anatomy doctor --json | jq '.findings[] | select(.severity == "WARN")'
$ mac-anatomy firmlinks --json | jq '.[] | .path'
$ mac-anatomy ww --json | jq '.count'
```

Supported on: `doctor`, `volumes`, `firmlinks`, `symlinks`, `setuid`,
`world-writable`.

## How it works

### The two-volume synthetic root

```
            mounts at /                              mounts at /System/Volumes/Data
        ┌─────────────────────────────┐          ┌──────────────────────────────────┐
        │        System volume         │          │            Data volume            │
        │    (SSV — Signed,            │          │     (writable, user-modifiable)  │
        │     read-only,               │          │                                   │
        │     sealed at boot)          │          │  Users/  Library/  Applications/  │
        │                              │          │  opt/    private/  Volumes/       │
        │  bin/  sbin/  usr/  System/  │          │  cores/  AppleInternal/  ...      │
        └──────────────┬───────────────┘          └────────────────┬─────────────────┘
                       │                                            │
                       │       /usr/share/firmlinks (per-path)       │
                       └───────────────────┐    ┌────────────────────┘
                                           ▼    ▼
                                  ┌──────────────────┐
                                  │  synthetic root  │
                                  │       /          │  ← what `ls /` shows
                                  └──────────────────┘
```

A firmlink is a **kernel-level path bind** registered at boot time,
not a symlink. `ls -l /Applications` shows it as a regular directory,
not a link, but the bytes live on the Data volume. This is different
from the legacy compat symlinks (`/etc → /private/etc`, etc.), which
are real symlinks visible to `ls`, `readlink`, `stat`, and friends.

### Why your `git init /` failed

The seal verifies a Merkle tree over every block of the System volume.
Modifying any byte invalidates the seal, which is checked at every
boot. Even with SIP disabled, you can't just write to `/` — you'd have
to:

1. Boot to Recovery (`csrutil disable`).
2. Mount the SSV read-write (`mount -uw /`).
3. Modify the contents.
4. Re-sign the seal (`bless --folder ...` plus undocumented internals).
5. Reboot.

Realistically, no one does this except Apple's own update mechanism.
For your everyday `git init` needs, use your home directory or
`~/code`.

## Companion tools

`mac-anatomy` is part of an unrelated-by-name but stylistically-related
family of single-file macOS utilities I keep at `~/.local/bin/`:

| Tool                | Purpose                                                                |
| ------------------- | ---------------------------------------------------------------------- |
| `mac-doctor`        | Diagnose and recover from macOS performance pathologies                |
| `finder-doctor`     | Unstick a wedged Finder (zombie exit handler / XPC transactions)       |
| `disk-doctor`       | Reclaim disk space in safe, auditable waves with dry-run default       |
| `startup-doctor`    | Audit/disable startup apps across Login Items, LaunchAgents, BTM       |
| `monitor-info`      | Decode EDID to identify any attached display                           |
| `mac-anatomy`       | **(this tool)** map and audit the macOS root filesystem                |

Same conventions: bash 3.2 compatible, ANSI when on a TTY, dry-run
defaults for anything destructive (n/a here — `mac-anatomy` is
read-only), `--help` for everything, `*-doctor` style story-comment
headers.

## FAQ

**Q: Will this work on Intel Macs?**
A: Yes. Both Intel and Apple Silicon have used the sealed SSV layout
since Big Sur (macOS 11). Tested specifically on Apple Silicon; CI
covers macos-14 / macos-15 / macos-latest on GitHub's runners (which
were Intel until 2024 and arm64 since then).

**Q: Does it require root?**
A: No. Everything works as your regular user. The tool deliberately
does not invoke `sudo` for any check. If a check would need elevated
access, it reports what it can see and notes the limitation.

**Q: Does it modify anything?**
A: Only the optional HTML report file at a path you specify (or
`/tmp/mac-anatomy-<timestamp>.html` if you don't). And one
`touch`+`rm` of `/private/tmp/.mac-anatomy-write-test` during
`doctor` to verify the Data volume is reachable.

**Q: Why bash and not Python/Rust/Go?**
A: Every interesting macOS root-filesystem question is answered by a
combination of `mount`, `csrutil`, `diskutil`, `find`, and
`readlink`. A bash script with no runtime dependencies is the minimum
footprint that solves the problem, ships in one file, and audits in
one read.

**Q: Why bash 3.2?**
A: `/bin/bash` on macOS is 3.2.57 and won't update — Apple won't ship
GPLv3 software. Brew can install a modern bash, but requiring it just
to read a CLI tool is unfriendly. So we target 3.2: no associative
arrays, no `mapfile`, no `${var^^}`. The script will still run on
bash 5.x and bash 4 — it just doesn't *require* them.

**Q: What's the difference between `setuid` and `world-writable`?**
A: `setuid` lists binaries that grant their file owner's privileges to
the invoking user (e.g., `sudo`, `ping`, `mount`). Expected to be
non-empty and stable across macOS versions. `world-writable` lists
files with the 0002 perm bit set in critical system dirs. Expected to
be **empty**. If either subcommand surfaces something unexpected,
investigate.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). TL;DR: bash 3.2 compatible,
read-only by design, one file in `bin/`, tests via bats-core, CI on
macOS runners.

## Security

Read-only inspection tool with no privilege escalation. See
[SECURITY.md](SECURITY.md) for the threat model and how to report
vulnerabilities.

## License

[MIT](LICENSE) © 2026 Rohin Agrawal
