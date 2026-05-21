#!/usr/bin/env bats
#
# Every subcommand that advertises --json must emit syntactically valid
# JSON to stdout, with no leading log lines, color codes, or headers.

load test_helper

@test "doctor --json is valid JSON with status + findings keys" {
  run macanatomy doctor --json
  assert_valid_json "$output"
  assert_contains "$output" '"status"'
  assert_contains "$output" '"findings"'
}

@test "firmlinks --json is a valid JSON array of {path, data_target}" {
  run macanatomy firmlinks --json
  [ "$status" -eq 0 ]
  assert_valid_json "$output"
  assert_contains "$output" '"path"'
  assert_contains "$output" '"data_target"'
}

@test "symlinks --json is a valid JSON array of {name, target}" {
  run macanatomy symlinks --json
  [ "$status" -eq 0 ]
  assert_valid_json "$output"
  # /etc is essentially universal on macOS
  assert_contains "$output" '"etc"'
}

@test "setuid --json is a valid JSON array" {
  run macanatomy setuid --json
  [ "$status" -eq 0 ]
  assert_valid_json "$output"
}

@test "ww --json has count + hits keys" {
  run macanatomy ww --json
  [ "$status" -eq 0 ]
  assert_valid_json "$output"
  assert_contains "$output" '"count"'
  assert_contains "$output" '"hits"'
}

@test "volumes --json parses as JSON (via plutil)" {
  run macanatomy volumes --json
  [ "$status" -eq 0 ]
  assert_valid_json "$output"
}
