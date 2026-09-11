#!/usr/bin/env bash
# Golden tests: diff mytools against real bedtools.
# Usage: ./tests/run_golden.sh
set -uo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
MYTOOLS=${MYTOOLS:-"$REPO/mytools"}
DATA="$REPO/data"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0

report() {
  local name=$1 got_rc=$2 want_rc=$3
  if [[ $got_rc -ne $want_rc ]]; then
    echo "FAIL $name (exit $got_rc, bedtools gave $want_rc)"
    sed 's/^/      /' "$tmp/got.err" | head -3
    (( fail++ )); return
  fi
  if diff -q "$tmp/want" "$tmp/got" >/dev/null; then
    echo "ok   $name"; (( pass++ ))
  else
    echo "FAIL $name"
    diff -u "$tmp/want" "$tmp/got" | sed 's/^/      /' | head -20
    (( fail++ ))
  fi
}

# check <name> -- <args...>
#   runs "$MYTOOLS <args>" and "bedtools <args>", diffs them
check() {
  local name=$1; shift; shift        # drop the literal --
  "$MYTOOLS" "$@" > "$tmp/got"  2>"$tmp/got.err"
  local got_rc=$?
  bedtools   "$@" > "$tmp/want" 2>/dev/null
  local want_rc=$?
  report "$name" "$got_rc" "$want_rc"
}

# check_stdin <name> <input-file> -- <args...>
#   same, but pipes <input-file> to both commands' stdin
check_stdin() {
  local name=$1 infile=$2; shift; shift; shift   # drop the literal --
  "$MYTOOLS" "$@" < "$infile" > "$tmp/got"  2>"$tmp/got.err"
  local got_rc=$?
  bedtools   "$@" < "$infile" > "$tmp/want" 2>/dev/null
  local want_rc=$?
  report "$name" "$got_rc" "$want_rc"
}

check       "sort a.bed"       -- sort -i "$DATA/a.bed"
check_stdin "sort a.bed stdin" "$DATA/a.bed" -- sort -i -

# Add the rest here as subcommands land.
# Suggested next cases:
#   merge (default), merge -d 10, intersect, intersect -u/-v/-wa,
#   subtract, closest, closest -d, and each command reading from stdin.

echo "---"
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
