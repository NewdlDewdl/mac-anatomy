# Shared bats helpers. Source this from each .bats file via:
#   load test_helper

# Find the bin under test relative to the bats file.
MAC_ANATOMY_BIN="${MAC_ANATOMY_BIN:-${BATS_TEST_DIRNAME}/../bin/mac-anatomy}"
export MAC_ANATOMY_BIN

# Convenience wrapper. Tests use:
#   run macanatomy <subcommand> [args]
macanatomy() {
  "$MAC_ANATOMY_BIN" "$@"
}

# Assert a string contains a substring, with helpful failure output.
assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "Expected output to contain: $needle"
    echo "Actual output:"
    echo "$haystack"
    return 1
  fi
}

# Assert JSON parses with python3 (always available on macOS runners).
assert_valid_json() {
  local input="$1"
  if ! printf '%s' "$input" | python3 -c 'import json, sys; json.load(sys.stdin)' 2>/dev/null; then
    echo "Output is not valid JSON:"
    echo "$input"
    return 1
  fi
}
