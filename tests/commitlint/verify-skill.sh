#!/bin/bash
set -euo pipefail

# Verify that the commitlint skill produced validation output with
# rule violations and fix suggestions.
# Checks /tmp/agent-output.txt saved by test-skill.sh.

PASS=0
FAIL=0

pass() { echo "[verify:commitlint] PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "[verify:commitlint] FAIL: $1"; FAIL=$((FAIL + 1)); }

OUTPUT_FILE="/tmp/agent-output.txt"

if [ ! -f "$OUTPUT_FILE" ]; then
    fail "No agent output file found"
    echo "[verify:commitlint] === Verification: ${PASS} passed, ${FAIL} failed ==="
    exit 1
fi

OUTPUT=$(cat "$OUTPUT_FILE")
OUTPUT_LEN=${#OUTPUT}

# Check 1: Output is substantive
if [ "$OUTPUT_LEN" -gt 100 ]; then
    pass "Output is substantive (${OUTPUT_LEN} chars)"
else
    fail "Output too short (${OUTPUT_LEN} chars, expected >100)"
fi

# Check 2: Rule violations referenced
RULE_PATTERN="type-enum\|type-empty\|subject-empty\|header-max-length"
RULE_PATTERN="${RULE_PATTERN}\|subject-case\|type-case\|scope-case"
RULE_PATTERN="${RULE_PATTERN}\|conventional\|commit.*valid\|commit.*invalid"
RULE_PATTERN="${RULE_PATTERN}\|violation\|rule.*fail\|does not match"
if echo "$OUTPUT" | grep -qi "$RULE_PATTERN"; then
    pass "Output references rule violations"
else
    fail "No rule violations found in output"
fi

# Check 3: Fix suggestions present
FIX_PATTERN="feat\|fix\|docs\|chore\|refactor\|style\|perf\|test\|build\|ci"
FIX_PATTERN="${FIX_PATTERN}\|suggest\|correct\|should be\|instead\|allowed"
FIX_PATTERN="${FIX_PATTERN}\|format.*type.*scope\|type(scope)"
if echo "$OUTPUT" | grep -qi "$FIX_PATTERN"; then
    pass "Output contains fix suggestions"
else
    fail "No fix suggestions found in output"
fi

echo ""
echo "[verify:commitlint] === Verification: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
