#!/usr/bin/env bats
#
# Each subcommand runs without crashing and emits its sentinel section
# heading. Output content varies by host, so we check for headers and
# known structural strings rather than exact values.

load test_helper

@test "overview runs and mentions sealed SSV" {
  run macanatomy --no-color overview
  [ "$status" -eq 0 ]
  assert_contains "$output" "Boot volume"
  assert_contains "$output" "Disk space"
  assert_contains "$output" "SIP"
}

@test "volumes runs and shows APFS information" {
  run macanatomy --no-color volumes
  [ "$status" -eq 0 ]
  assert_contains "$output" "APFS"
}

@test "firmlinks runs and shows the synthetic-root explanation" {
  run macanatomy --no-color firmlinks
  [ "$status" -eq 0 ]
  assert_contains "$output" "/System/Volumes/Data"
  assert_contains "$output" "How firmlinks work"
}

@test "symlinks runs and shows /etc → private/etc" {
  run macanatomy --no-color symlinks
  [ "$status" -eq 0 ]
  assert_contains "$output" "private/etc"
}

@test "sip runs and shows status + protection categories" {
  run macanatomy --no-color sip
  [ "$status" -eq 0 ]
  assert_contains "$output" "System Integrity Protection"
  assert_contains "$output" "Filesystem"
  assert_contains "$output" "Kexts"
}

@test "setuid runs and finds at least sudo" {
  run macanatomy --no-color setuid
  [ "$status" -eq 0 ]
  assert_contains "$output" "/usr/bin/sudo"
}

@test "world-writable runs (ww alias too)" {
  run macanatomy --no-color world-writable
  [ "$status" -eq 0 ]
  assert_contains "$output" "critical system dirs"

  run macanatomy --no-color ww
  [ "$status" -eq 0 ]
  assert_contains "$output" "critical system dirs"
}

@test "tree runs with default depth" {
  run macanatomy --no-color tree
  [ "$status" -eq 0 ]
  assert_contains "$output" "Root tree"
}

@test "tree rejects invalid depth" {
  run macanatomy --no-color tree banana
  [ "$status" -ne 0 ]
  assert_contains "$output" "tree depth must be"
}

@test "tree rejects out-of-range depth" {
  run macanatomy --no-color tree 99
  [ "$status" -ne 0 ]
  assert_contains "$output" "tree depth must be"
}

@test "doctor runs and prints status" {
  run macanatomy --no-color doctor
  [ "$status" -ge 0 ] && [ "$status" -le 2 ]
  assert_contains "$output" "Status:"
}

@test "report writes an HTML file" {
  outfile="$(mktemp -t mac-anatomy-test-XXXXXX).html"
  run macanatomy --no-color report "$outfile"
  [ "$status" -eq 0 ]
  [ -s "$outfile" ]
  run cat "$outfile"
  assert_contains "$output" "<!DOCTYPE html>"
  assert_contains "$output" "mac-anatomy report"
  rm -f "$outfile"
}
