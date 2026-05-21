# Security policy

## Supported versions

The latest tagged release is supported. There is no LTS branch.

## Surface area

`mac-anatomy` is read-only by design. It never writes to the root
filesystem — every subcommand inspects existing state via standard
macOS utilities (`mount`, `csrutil`, `diskutil`, `find`, `readlink`,
`sw_vers`, `scutil`, `plutil`). The only file it can create is the
optional HTML report at a user-specified or `/tmp`-defaulted path.

It does not require root privileges and explicitly does not invoke
`sudo` for any of its checks. If a system inspection would require
elevated access (e.g., reading restricted snapshot metadata), the tool
reports what it can see and notes the limitation rather than escalating.

## Reporting a vulnerability

If you find a security issue — for example, a way to coerce
`mac-anatomy` into writing to the filesystem, executing user-controlled
input, or leaking sensitive content into the HTML report — please open
a private security advisory on GitHub:

  https://github.com/NewdlDewdl/mac-anatomy/security/advisories/new

Or email `rohin.agrawal@gmail.com` with subject prefix `[mac-anatomy
security]`.

Please do not open a public issue for security-relevant findings
until a fix has shipped.

## Known limitations

- The HTML report subcommand embeds verbatim output from each
  subcommand. If you intentionally feed the tool a hostile environment
  (e.g., maliciously named files in the root listing), that text will
  appear in the HTML report. We HTML-escape every embedded string with
  `sed`-driven `&`/`<`/`>` substitution before insertion, so a hostile
  filename should render as text rather than execute as markup. If you
  find a bypass, please report it via the channels above.

- The `setuid` and `world-writable` subcommands accept the output of
  `find` at face value. If `find` itself has been compromised on the
  host, results will reflect that compromise. `mac-anatomy` does not
  verify the integrity of the standard tools it calls — that's the job
  of SIP and the SSV seal, which the `doctor` subcommand reports on
  separately.
