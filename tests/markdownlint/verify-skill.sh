#!/bin/bash
set -euo pipefail

# Verify that the markdownlint skill produced validation output with
# rule violations and fix guidance.
# Checks /tmp/agent-output.txt saved by test-skill.sh.

PASS=0
FAIL=0

pass() { echo "[verify:markdownlint] PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "[verify:markdownlint] FAIL: $1"; FAIL=$((FAIL + 1)); }

OUTPUT_FILE="/tmp/agent-output.txt"

if [ ! -f "$OUTPUT_FILE" ]; then
    fail "No agent output file found"
    echo "[verify:markdownlint] === Verification: ${PASS} passed, ${FAIL} failed ==="
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

# Check 2: MD rule IDs referenced
RULE_PATTERN="MD018\|MD022\|MD004\|MD047\|MD012\|MD032\|MD041"
RULE_PATTERN="${RULE_PATTERN}\|no-missing-space\|blanks-around-headings\|ul-style"
RULE_PATTERN="${RULE_PATTERN}\|single-trailing-newline\|no-multiple-blanks\|blanks-around-lists"
RULE_PATTERN="${RULE_PATTERN}\|markdownlint\|markdown.*lint\|formatting.*error\|lint.*error"
if echo "$OUTPUT" | grep -qi "$RULE_PATTERN"; then
    pass "Output references markdownlint rules or errors"
else
    fail "No markdownlint rule references found in output"
fi

# Check 3: Fix guidance present
FIX_PATTERN="--fix\|auto.fix\|markdownlint.*fix"
FIX_PATTERN="${FIX_PATTERN}\|add.*blank.*line\|add.*space\|add.*newline\|trailing.*newline"
FIX_PATTERN="${FIX_PATTERN}\|suggest\|correct\|should be\|fix.*issue\|resolve"
FIX_PATTERN="${FIX_PATTERN}\|manual.*fix\|manual.*correct"
if echo "$OUTPUT" | grep -qi "$FIX_PATTERN"; then
    pass "Output contains fix guidance"
else
    fail "No fix guidance found in output"
fi

echo ""
echo "[verify:markdownlint] === Verification: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
