#!/bin/bash
set -euo pipefail

# Verify that the roadmap skill (status mode) produced a structured
# summary referencing roadmap items and progress metrics.
# Checks /tmp/agent-output.txt saved by test-skill.sh.

PASS=0
FAIL=0

pass() { echo "[verify:roadmap] PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "[verify:roadmap] FAIL: $1"; FAIL=$((FAIL + 1)); }

OUTPUT_FILE="/tmp/agent-output.txt"

if [ ! -f "$OUTPUT_FILE" ]; then
    fail "No agent output file found"
    echo "[verify:roadmap] === Verification: ${PASS} passed, ${FAIL} failed ==="
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

# Check 2: Roadmap items referenced
ITEMS_PATTERN="init\|config\|plugin\|shell.complet\|project.setup"
if echo "$OUTPUT" | grep -qi "$ITEMS_PATTERN"; then
    pass "Roadmap items referenced in output"
else
    fail "No roadmap items found in output (expected: init, config, plugin, etc.)"
fi

# Check 3: Status indicators present (counts, progress, numbers)
STATUS_PATTERN="[0-9].*open|[0-9].*closed|[0-9].*complete|[0-9].*done|progress|[0-9].*total|[0-9].*item|[0-9].*issue|[0-9]/[0-9]"
if echo "$OUTPUT" | grep -qiE "$STATUS_PATTERN"; then
    pass "Status indicators present in output"
else
    fail "No status indicators found in output (expected counts or progress metrics)"
fi

# Check 4: Structured format (tables or organized sections)
if echo "$OUTPUT" | grep -qE '(\|.*\|)|^##|Summary|Status|Metric|Category|Effort|Focus'; then
    pass "Structured format detected in output"
else
    fail "No structured format found in output (expected tables or section headings)"
fi

echo ""
echo "[verify:roadmap] === Structural checks: ${PASS} passed, ${FAIL} failed ==="

# ── LLM-as-judge (gated by EVAL_LLM_JUDGE=1) ─────────────────────────

if [ "${EVAL_LLM_JUDGE:-}" != "1" ]; then
    echo ""
    echo "[verify:roadmap] LLM judge SKIPPED (set EVAL_LLM_JUDGE=1 to enable)"
    if [ "$FAIL" -gt 0 ]; then
        exit 1
    fi
    exit 0
fi

echo ""
echo "[verify:roadmap] Running LLM-as-judge evaluation..."

FIXTURE_CONTEXT="Test fixtures:
- CONTEXT.md: CLI tool for managing development workflows. Boundaries: no GUI, no cloud hosting.
- ROADMAP.md: 4 open items (init command #1, config validation #2, plugin system #3, shell completions #4), 1 completed (project setup in 2025-Q1).
- gh CLI returns empty results (mock), so GitHub data is unavailable."

JUDGE_PROMPT="You are a strict evaluator for an AI skill called 'roadmap' (status mode).
The roadmap status mode summarizes the current state of a project roadmap.

${FIXTURE_CONTEXT}

Evaluate the following output on four criteria (score each 1-5):
  1. Completeness: Mentions all roadmap items from ROADMAP.md (5=all items, 1=none)
  2. Accuracy: Counts and status indicators are correct (5=all correct, 1=wrong)
  3. Structure: Uses tables or organized sections (5=well-structured, 1=unformatted)
  4. Boundary awareness: Does not suggest GUI or cloud features (5=respects boundaries, 1=violates)

Output to evaluate:
${OUTPUT}

Respond in exactly this format (one per line, nothing else):
COMPLETENESS: <1-5>
ACCURACY: <1-5>
STRUCTURE: <1-5>
BOUNDARY_AWARENESS: <1-5>
VERDICT: PASS or FAIL"

JUDGE_OUTPUT=$(opencode run "$JUDGE_PROMPT" 2>&1) || true
echo "$JUDGE_OUTPUT"
echo ""

for criterion in COMPLETENESS ACCURACY STRUCTURE BOUNDARY_AWARENESS; do
    SCORE=$(echo "$JUDGE_OUTPUT" | grep -i "^${criterion}:" | grep -oE '[0-9]+' | head -1)
    if [ -z "$SCORE" ]; then
        fail "LLM judge: Could not parse ${criterion} score"
        continue
    fi
    if [ "$SCORE" -ge 3 ]; then
        pass "LLM judge: ${criterion} = ${SCORE}/5"
    else
        fail "LLM judge: ${criterion} = ${SCORE}/5 (below threshold of 3)"
    fi
done

if echo "$JUDGE_OUTPUT" | grep -qi "VERDICT: PASS"; then
    pass "LLM judge: Overall verdict PASS"
else
    fail "LLM judge: Overall verdict FAIL"
fi

echo ""
echo "[verify:roadmap] === All checks: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
