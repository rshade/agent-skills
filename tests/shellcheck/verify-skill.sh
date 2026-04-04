#!/bin/bash
set -euo pipefail

# Verify that the shellcheck skill produced validation output with
# SC codes and fix suggestions.
# Checks /tmp/agent-output.txt saved by test-skill.sh.

PASS=0
FAIL=0

pass() { echo "[verify:shellcheck] PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "[verify:shellcheck] FAIL: $1"; FAIL=$((FAIL + 1)); }

OUTPUT_FILE="/tmp/agent-output.txt"

if [ ! -f "$OUTPUT_FILE" ]; then
    fail "No agent output file found"
    echo "[verify:shellcheck] === Verification: ${PASS} passed, ${FAIL} failed ==="
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

# Check 2: SC codes referenced
RULE_PATTERN="SC2086\|SC2164\|SC2155\|SC2012\|SC2034\|SC2046\|shellcheck\|shell.*error\|shell.*valid"
RULE_PATTERN="${RULE_PATTERN}\|quoting\|unquoted\|double.*quote\|globbing\|word.*split"
RULE_PATTERN="${RULE_PATTERN}\|cd.*exit\|cd.*||"
if echo "$OUTPUT" | grep -qi "$RULE_PATTERN"; then
    pass "Output references shellcheck SC codes"
else
    fail "No SC codes found in output"
fi

# Check 3: Fix suggestions present
FIX_PATTERN="fix\|suggest\|correct\|should\|instead\|replace"
FIX_PATTERN="${FIX_PATTERN}\|quote\|double.*quote\|cd.*exit\|cd.*||"
FIX_PATTERN="${FIX_PATTERN}\|echo.*\$\|local.*result"
if echo "$OUTPUT" | grep -qi "$FIX_PATTERN"; then
    pass "Output contains fix suggestions"
else
    fail "No fix suggestions found in output"
fi

echo ""
echo "[verify:shellcheck] === Verification: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
