#!/bin/bash
set -euo pipefail

# Verify that the decide skill produced structured debate output.
# Checks /tmp/agent-output.txt saved by test-skill.sh.

PASS=0
FAIL=0

pass() { echo "[verify:decide] PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "[verify:decide] FAIL: $1"; FAIL=$((FAIL + 1)); }

OUTPUT_FILE="/tmp/agent-output.txt"

if [ ! -f "$OUTPUT_FILE" ]; then
    fail "No agent output file found"
    echo "[verify:decide] === Verification: ${PASS} passed, ${FAIL} failed ==="
    exit 1
fi

OUTPUT=$(cat "$OUTPUT_FILE")
OUTPUT_LEN=${#OUTPUT}

# Check 1: Output is substantive
if [ "$OUTPUT_LEN" -gt 200 ]; then
    pass "Output is substantive (${OUTPUT_LEN} chars)"
else
    fail "Output too short (${OUTPUT_LEN} chars, expected >200)"
fi

# Check 2: Contains structured debate indicators
DEBATE_PATTERN="consensus\|position\|agree\|disagree\|risk\|recommend"
DEBATE_PATTERN="${DEBATE_PATTERN}\|trade-off\|tradeoff\|advantage\|disadvantage"
DEBATE_PATTERN="${DEBATE_PATTERN}\|argument\|red.*team\|blue.*team\|white.*team"
if echo "$OUTPUT" | grep -qi "$DEBATE_PATTERN"; then
    pass "Output contains debate structure indicators"
else
    fail "No debate structure found in output"
fi

# Check 3: Both sides referenced
if echo "$OUTPUT" | grep -qi "red\|blue"; then
    pass "Both sides of debate represented"
else
    fail "Missing representation of both debate sides"
fi

echo ""
echo "[verify:decide] === Verification: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
