#!/usr/bin/env bash
# install.sh — symlink mac-anatomy and its man page into a local install
# prefix. Default prefix is $HOME/.local, matching the convention used
# by mac-doctor, finder-doctor, disk-doctor, startup-doctor, and
# monitor-info in the same family.
#
# Usage:
#   ./install.sh                    # symlink into $HOME/.local
#   PREFIX=/usr/local ./install.sh  # symlink into /usr/local
#   ./install.sh --uninstall        # remove the symlinks

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="$REPO_DIR/bin/mac-anatomy"
MAN_SRC="$REPO_DIR/man/mac-anatomy.1"

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"
MAN_DIR="$PREFIX/share/man/man1"

uninstall() {
  rm -f "$BIN_DIR/mac-anatomy" "$MAN_DIR/mac-anatomy.1"
  echo "Removed: $BIN_DIR/mac-anatomy"
  echo "         $MAN_DIR/mac-anatomy.1"
}

if [[ "${1:-}" == "--uninstall" || "${1:-}" == "-u" ]]; then
  uninstall
  exit 0
fi

[[ -x "$BIN_SRC" ]] || { echo "missing or not executable: $BIN_SRC" >&2; exit 1; }
[[ -f "$MAN_SRC" ]] || { echo "missing: $MAN_SRC" >&2; exit 1; }

mkdir -p "$BIN_DIR" "$MAN_DIR"
ln -sfn "$BIN_SRC" "$BIN_DIR/mac-anatomy"
ln -sfn "$MAN_SRC" "$MAN_DIR/mac-anatomy.1"

echo "Installed:"
echo "  $BIN_DIR/mac-anatomy → $BIN_SRC"
echo "  $MAN_DIR/mac-anatomy.1 → $MAN_SRC"
echo

# Help the user wire up PATH/MANPATH if needed.
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "Note: $BIN_DIR is not in PATH. Add to your shell rc:"
     echo "  export PATH=\"$BIN_DIR:\$PATH\""
     echo ;;
esac

case ":${MANPATH:-}:" in
  *":$PREFIX/share/man:"*) ;;
  *) echo "Note: $PREFIX/share/man is not in MANPATH. Add to your shell rc:"
     echo "  export MANPATH=\"$PREFIX/share/man:\$MANPATH\""
     echo ;;
esac

echo "Try it:  mac-anatomy --version"
