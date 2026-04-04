#!/bin/bash
set -euo pipefail

# Verify that the actionlint skill produced validation output with
# error categories and fix suggestions.
# Checks /tmp/agent-output.txt saved by test-skill.sh.

PASS=0
FAIL=0

pass() { echo "[verify:actionlint] PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "[verify:actionlint] FAIL: $1"; FAIL=$((FAIL + 1)); }

OUTPUT_FILE="/tmp/agent-output.txt"

if [ ! -f "$OUTPUT_FILE" ]; then
    fail "No agent output file found"
    echo "[verify:actionlint] === Verification: ${PASS} passed, ${FAIL} failed ==="
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

# Check 2: Workflow errors referenced
RULE_PATTERN="actionlint\|workflow.*error\|workflow.*valid"
RULE_PATTERN="${RULE_PATTERN}\|syntax.*error\|expression.*error"
RULE_PATTERN="${RULE_PATTERN}\|action.*checkout\|runner.*label"
RULE_PATTERN="${RULE_PATTERN}\|github\.repo\|github\.repository"
RULE_PATTERN="${RULE_PATTERN}\|ubunut\|ubuntu\|runs-on"
RULE_PATTERN="${RULE_PATTERN}\|shell.*inject\|untrusted.*input"
RULE_PATTERN="${RULE_PATTERN}\|matrix\|permission"
if echo "$OUTPUT" | grep -qi "$RULE_PATTERN"; then
    pass "Output references workflow validation errors"
else
    fail "No workflow validation errors found in output"
fi

# Check 3: Fix suggestions present
FIX_PATTERN="fix\|suggest\|correct\|should be\|instead\|replace"
FIX_PATTERN="${FIX_PATTERN}\|checkout@v4\|checkout@v\|version.*tag"
FIX_PATTERN="${FIX_PATTERN}\|ubuntu-latest\|github\.repository"
FIX_PATTERN="${FIX_PATTERN}\|environment.*variable\|env:"
if echo "$OUTPUT" | grep -qi "$FIX_PATTERN"; then
    pass "Output contains fix suggestions"
else
    fail "No fix suggestions found in output"
fi

echo ""
echo "[verify:actionlint] === Verification: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
