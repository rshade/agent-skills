#!/bin/bash
set -euo pipefail

# Verify that the scout skill produced structured improvement output.
# Checks /tmp/agent-output.txt saved by test-skill.sh.

PASS=0
FAIL=0

pass() { echo "[verify:scout] PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "[verify:scout] FAIL: $1"; FAIL=$((FAIL + 1)); }

OUTPUT_FILE="/tmp/agent-output.txt"

if [ ! -f "$OUTPUT_FILE" ]; then
    fail "No agent output file found"
    echo "[verify:scout] === Verification: ${PASS} passed, ${FAIL} failed ==="
    exit 1
fi

OUTPUT=$(cat "$OUTPUT_FILE")
OUTPUT_LEN=${#OUTPUT}

# Check 1: Output is substantive
if [ "$OUTPUT_LEN" -gt 300 ]; then
    pass "Output is substantive (${OUTPUT_LEN} chars)"
else
    fail "Output too short (${OUTPUT_LEN} chars, expected >300)"
fi

# Check 2: Top-3 format (table rows with 1/2/3, or numbered items)
if echo "$OUTPUT" | grep -qE '(\| *[123] *\|)|(^[123]\.)|(^[123]\s)'; then
    pass "Top-3 format detected in output"
else
    fail "No top-3 format found in output (expected numbered table rows or list items)"
fi

# Check 3: Scout categories referenced
CATEGORY_PATTERN="dead.code\|naming\|magic.value\|deprecated\|simplif"
if echo "$OUTPUT" | grep -qi "$CATEGORY_PATTERN"; then
    pass "Scout categories referenced in output"
else
    fail "No scout categories found in output (expected: dead-code, naming, magic-values, deprecated-patterns, or simplification)"
fi

# Check 4: Scoring present (Impact x Low-Risk or composite score)
SCORE_PATTERN="[Ii]mpact\|[Ll]ow.Risk\|[0-9][×x][0-9]\|[Ss]core\|I=[0-9]\|R=[0-9]"
if echo "$OUTPUT" | grep -qE "$SCORE_PATTERN"; then
    pass "Scoring present in output"
else
    fail "No scoring found in output (expected Impact/Low-Risk scores)"
fi

# Check 5: Code context (snippets or line references)
CODE_PATTERN="def |import |class |:[0-9]|fixture\.py\|getUserId\|process_data\|old_handler\|3\.14\|TIMEOUT"
if echo "$OUTPUT" | grep -qE "$CODE_PATTERN"; then
    pass "Code context present in output"
else
    fail "No code context found in output (expected snippets or line references from fixture.py)"
fi

echo ""
echo "[verify:scout] === Structural checks: ${PASS} passed, ${FAIL} failed ==="

# ── LLM-as-judge (gated by EVAL_LLM_JUDGE=1) ─────────────────────────────────

if [ "${EVAL_LLM_JUDGE:-}" != "1" ]; then
    echo ""
    echo "[verify:scout] LLM judge SKIPPED (set EVAL_LLM_JUDGE=1 to enable)"
    if [ "$FAIL" -gt 0 ]; then
        exit 1
    fi
    exit 0
fi

echo ""
echo "[verify:scout] Running LLM-as-judge evaluation..."

FIXTURE_ISSUES="Known issues in fixture.py:
- Unused imports: json (and possibly sys/os) -> dead-code
- Inconsistent naming: getUserId vs get_user_name -> naming
- Magic values: 3.14159, 42, TIMEOUT=30 -> magic-values
- Dead function: old_handler with completed TODO (Q3 2024) -> dead-code / deprecated-patterns
- Nested conditionals: triple-nested if in process_data -> simplification
- range(len(d)) anti-pattern -> simplification"

JUDGE_PROMPT="You are a strict evaluator for an AI skill called 'scout'.
The scout skill identifies the top 3 highest-impact improvement opportunities in code files.

${FIXTURE_ISSUES}

Evaluate the following output on four criteria (score each 1-5):
  1. Relevance: Suggestions address real issues in the fixture (5=all real, 1=generic)
  2. Actionability: Concrete code snippets showing the improvement (5=specific snippets, 1=vague)
  3. Category accuracy: Assigned categories match actual issue types (5=all correct, 1=wrong)
  4. Effort accuracy: Effort estimates are realistic for the change size (5=accurate, 1=wildly off)

Output to evaluate:
${OUTPUT}

Respond in exactly this format (one per line, nothing else):
RELEVANCE: <1-5>
ACTIONABILITY: <1-5>
CATEGORY_ACCURACY: <1-5>
EFFORT_ACCURACY: <1-5>
VERDICT: PASS or FAIL"

JUDGE_OUTPUT=$(opencode run "$JUDGE_PROMPT" 2>&1) || true
echo "$JUDGE_OUTPUT"
echo ""

JUDGE_FAIL=0

for criterion in RELEVANCE ACTIONABILITY CATEGORY_ACCURACY EFFORT_ACCURACY; do
    SCORE=$(echo "$JUDGE_OUTPUT" | grep -i "^${criterion}:" | grep -oE '[0-9]+' | head -1)
    if [ -z "$SCORE" ]; then
        fail "LLM judge: Could not parse ${criterion} score"
        JUDGE_FAIL=$((JUDGE_FAIL + 1))
        continue
    fi
    if [ "$SCORE" -ge 3 ]; then
        pass "LLM judge: ${criterion} = ${SCORE}/5"
    else
        fail "LLM judge: ${criterion} = ${SCORE}/5 (below threshold of 3)"
        JUDGE_FAIL=$((JUDGE_FAIL + 1))
    fi
done

if echo "$JUDGE_OUTPUT" | grep -qi "VERDICT: PASS"; then
    pass "LLM judge: Overall verdict PASS"
else
    fail "LLM judge: Overall verdict FAIL"
fi

echo ""
echo "[verify:scout] === All checks: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
