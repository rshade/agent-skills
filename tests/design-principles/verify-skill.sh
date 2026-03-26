#!/bin/bash
set -euo pipefail

# Verify that the design-principles skill produced structured audit output.
# Checks /tmp/agent-output.txt saved by run-skill-test.sh.

PASS=0
FAIL=0

pass() { echo "[verify:design-principles] PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "[verify:design-principles] FAIL: $1"; FAIL=$((FAIL + 1)); }

OUTPUT_FILE="/tmp/agent-output.txt"

if [ ! -f "$OUTPUT_FILE" ]; then
    fail "No agent output file found"
    echo "[verify:design-principles] === Verification: ${PASS} passed, ${FAIL} failed ==="
    exit 1
fi

OUTPUT=$(cat "$OUTPUT_FILE")
OUTPUT_LEN=${#OUTPUT}

# Check 1: Output is substantive
if [ "$OUTPUT_LEN" -gt 500 ]; then
    pass "Output is substantive (${OUTPUT_LEN} chars)"
else
    fail "Output too short (${OUTPUT_LEN} chars, expected >500)"
fi

# Check 2: Contains principle names
PRINCIPLE_PATTERN="SOLID\|Single Responsibility\|Open.Closed\|DRY\|YAGNI\|KISS"
PRINCIPLE_PATTERN="${PRINCIPLE_PATTERN}\|Dependency Inversion\|Interface Segregation"
PRINCIPLE_PATTERN="${PRINCIPLE_PATTERN}\|Law of Demeter\|Separation of Concerns"
if echo "$OUTPUT" | grep -qi "$PRINCIPLE_PATTERN"; then
    pass "Output references design principles"
else
    fail "No design principle names found in output"
fi

# Check 3: Contains finding structure (file:line references or evidence)
FINDING_PATTERN="Finding\|violation\|evidence\|file:\|\.go:\|\.ts:\|\.py:\|Impact\|Effort"
if echo "$OUTPUT" | grep -qi "$FINDING_PATTERN"; then
    pass "Output contains structured findings"
else
    fail "No structured findings found in output"
fi

# Check 4: Contains scoring or prioritization
SCORE_PATTERN="Score\|Priority\|P1\|P2\|HIGH\|MEDIUM\|LOW\|CRITICAL\|Remediation"
if echo "$OUTPUT" | grep -qi "$SCORE_PATTERN"; then
    pass "Output contains scoring or prioritization"
else
    fail "No scoring or prioritization found in output"
fi

# Check 5: DESIGN_AUDIT.md was generated
WORKSPACE_DIR="/workspace"
if [ -f "$WORKSPACE_DIR/DESIGN_AUDIT.md" ]; then
    pass "DESIGN_AUDIT.md was generated"
    AUDIT_SIZE=$(wc -c < "$WORKSPACE_DIR/DESIGN_AUDIT.md")
    if [ "$AUDIT_SIZE" -gt 200 ]; then
        pass "DESIGN_AUDIT.md is substantive (${AUDIT_SIZE} bytes)"
    else
        fail "DESIGN_AUDIT.md too small (${AUDIT_SIZE} bytes, expected >200)"
    fi
else
    fail "DESIGN_AUDIT.md was not generated in workspace"
fi

echo ""
echo "[verify:design-principles] === Verification: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
