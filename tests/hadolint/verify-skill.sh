#!/bin/bash
set -euo pipefail

# Verify that the hadolint skill produced validation output with
# DL/SC rule codes and fix suggestions.
# Checks /tmp/agent-output.txt saved by test-skill.sh.

PASS=0
FAIL=0

pass() { echo "[verify:hadolint] PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "[verify:hadolint] FAIL: $1"; FAIL=$((FAIL + 1)); }

OUTPUT_FILE="/tmp/agent-output.txt"

if [ ! -f "$OUTPUT_FILE" ]; then
    fail "No agent output file found"
    echo "[verify:hadolint] === Verification: ${PASS} passed, ${FAIL} failed ==="
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

# Check 2: Dockerfile/hadolint errors referenced
RULE_PATTERN="hadolint\|Dockerfile.*error\|Dockerfile.*valid"
RULE_PATTERN="${RULE_PATTERN}\|DL3006\|DL3008\|DL3009\|DL3015"
RULE_PATTERN="${RULE_PATTERN}\|DL4000\|DL4006\|DL3020\|DL3025\|DL3013"
RULE_PATTERN="${RULE_PATTERN}\|SC2086\|image.*tag\|pin.*version"
RULE_PATTERN="${RULE_PATTERN}\|apt-get\|package.*pin\|base.*image"
if echo "$OUTPUT" | grep -qi "$RULE_PATTERN"; then
    pass "Output references Dockerfile validation errors (DL/SC codes)"
else
    fail "No Dockerfile validation errors found in output"
fi

# Check 3: Fix suggestions present
FIX_PATTERN="fix\|suggest\|correct\|should be\|instead\|replace"
FIX_PATTERN="${FIX_PATTERN}\|ubuntu:22.04\|ubuntu:[0-9]\|LABEL maintainer"
FIX_PATTERN="${FIX_PATTERN}\|COPY\|--no-install-recommends"
FIX_PATTERN="${FIX_PATTERN}\|rm.*var.*lib.*apt\|pipefail"
FIX_PATTERN="${FIX_PATTERN}\|from.*tag\|add.*version"
if echo "$OUTPUT" | grep -qi "$FIX_PATTERN"; then
    pass "Output contains fix suggestions"
else
    fail "No fix suggestions found in output"
fi

echo ""
echo "[verify:hadolint] === Verification: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
