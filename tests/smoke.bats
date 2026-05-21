#!/usr/bin/env bats
#
# Basic invocation tests: the script runs, version/help work, unknown
# flags fail loudly. These should pass on any Mac with bash 3+.

load test_helper

@test "script is executable" {
  [ -x "$MAC_ANATOMY_BIN" ]
}

@test "--version prints expected pattern" {
  run macanatomy --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^mac-anatomy\ v[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "--help prints USAGE block" {
  run macanatomy --help
  [ "$status" -eq 0 ]
  assert_contains "$output" "USAGE"
  assert_contains "$output" "SUBCOMMANDS"
  assert_contains "$output" "EXAMPLES"
}

@test "-h alias works the same as --help" {
  run macanatomy -h
  [ "$status" -eq 0 ]
  assert_contains "$output" "USAGE"
}

@test "unknown flag exits non-zero with a helpful message" {
  run macanatomy --bogus
  [ "$status" -ne 0 ]
  assert_contains "$output" "unknown flag"
}

@test "unknown subcommand exits non-zero with a helpful message" {
  run macanatomy not-a-real-subcommand
  [ "$status" -ne 0 ]
  assert_contains "$output" "unknown subcommand"
}

@test "default subcommand is overview" {
  run macanatomy --no-color
  [ "$status" -eq 0 ]
  assert_contains "$output" "macOS"
  assert_contains "$output" "Boot volume"
}

@test "--no-color suppresses ANSI escapes" {
  run macanatomy --no-color overview
  [ "$status" -eq 0 ]
  # No ESC byte (0x1b) in output
  [[ ! "$output" =~ $'\e' ]]
}
