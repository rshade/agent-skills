#!/bin/bash
set -euo pipefail

# Verify the go-fix skill modernized the fixture correctly.
# Mechanical checks against the workspace fixture files mutated by the
# agent, plus transcript checks against /tmp/agent-output.txt.

PASS=0
FAIL=0

pass() { echo "[verify:go-fix] PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "[verify:go-fix] FAIL: $1"; FAIL=$((FAIL + 1)); }

FIXTURE="/workspace/skills/go-fix/evals/fixture"
MAIN="$FIXTURE/main.go"
GEN="$FIXTURE/generated.go"
OUTPUT_FILE="/tmp/agent-output.txt"

if [ ! -f "$MAIN" ] || [ ! -f "$GEN" ]; then
    fail "Fixture files missing under $FIXTURE"
    echo "[verify:go-fix] === Verification: ${PASS} passed, ${FAIL} failed ==="
    exit 1
fi

# Check 1: interface{} modernized to any in main.go
if grep -q "interface{}" "$MAIN"; then
    fail "main.go still contains interface{} (any fixer did not run)"
else
    pass "main.go: interface{} replaced with any"
fi

# Check 2: 3-clause loop modernized (rangeint)
if grep -qE "for i := 0; i < len" "$MAIN"; then
    fail "main.go still contains a 3-clause for loop (rangeint did not run)"
else
    pass "main.go: 3-clause for loop replaced with range"
fi

# Check 3: strings.Index + slice modernized to strings.Cut
if grep -q "strings.Index" "$MAIN"; then
    fail "main.go still uses strings.Index (stringscut did not run)"
else
    pass "main.go: strings.Index pattern replaced with strings.Cut"
fi

# Check 4: fixed point reached — second-pass minmax collapse applied
if grep -qE "min\(max\(" "$MAIN"; then
    pass "main.go: clamp collapsed to min(max(...)) — go fix ran to fixed point"
else
    fail "main.go: clamp not fully collapsed (go fix likely ran only once)"
fi

# Check 5: generated file untouched
if grep -q "interface{}" "$GEN" && grep -qE "for i := 0; i < len" "$GEN"; then
    pass "generated.go left unmodified (DO NOT EDIT respected)"
else
    fail "generated.go was modified — generated files must not be rewritten"
fi

# Check 6: module still builds on Go 1.26
if (cd "$FIXTURE" && go build ./... >/dev/null 2>&1); then
    pass "fixture still builds after fixes"
else
    fail "fixture does not build after fixes"
fi

# Check 7: agent verified the toolchain version before fixing
if [ -f "$OUTPUT_FILE" ] && grep -qiE "go1\.26|GOVERSION|1\.26" "$OUTPUT_FILE"; then
    pass "agent output references the Go 1.26 toolchain requirement"
else
    fail "no evidence the agent checked for Go 1.26+ before running"
fi

echo ""
echo "[verify:go-fix] === Verification: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
