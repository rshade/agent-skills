#!/bin/bash
set -euo pipefail

# Verify that the go-nolint-audit skill produced structured audit output.
# Checks /tmp/agent-output.txt saved by test-skill.sh.

PASS=0
FAIL=0

pass() { echo "[verify:go-nolint-audit] PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "[verify:go-nolint-audit] FAIL: $1"; FAIL=$((FAIL + 1)); }

OUTPUT_FILE="/tmp/agent-output.txt"

if [ ! -f "$OUTPUT_FILE" ]; then
    fail "No agent output file found"
    echo "[verify:go-nolint-audit] === Verification: ${PASS} passed, ${FAIL} failed ==="
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

# Check 2: Phase 1 classification present (stale or active)
if echo "$OUTPUT" | grep -qi "stale\|active\|phase 1\|mechanical"; then
    pass "Phase 1 classification present"
else
    fail "No Phase 1 classification found (expected stale/active)"
fi

# Check 3: Phase 2 debate structure (Red/Blue/White references)
DEBATE_PATTERN="[Rr]ed\|[Bb]lue\|[Ww]hite\|debate\|verdict"
if echo "$OUTPUT" | grep -qE "$DEBATE_PATTERN"; then
    pass "Phase 2 debate structure present"
else
    fail "No Phase 2 debate structure found (expected Red/Blue/White or verdict)"
fi

# Check 4: Scoring present (fixability + justification quality)
SCORE_PATTERN="[Ff]ixability|[Jj]ustification.*[Qq]uality|[Ss]core|[0-9] *[×xX*] *[0-9]"
if echo "$OUTPUT" | grep -qE "$SCORE_PATTERN"; then
    pass "Scoring present in output"
else
    fail "No scoring found (expected fixability and justification quality scores)"
fi

# Check 5: A verdict is given
if echo "$OUTPUT" | grep -qiE "REMOVE|KEEP|REWRITE"; then
    pass "Verdict present in output"
else
    fail "No verdict found (expected REMOVE, KEEP, or REWRITE)"
fi

echo ""
echo "[verify:go-nolint-audit] === Structural checks: ${PASS} passed, ${FAIL} failed ==="

# ── LLM-as-judge (gated by EVAL_LLM_JUDGE=1) ─────────────────────────────────

if [ "${EVAL_LLM_JUDGE:-}" != "1" ]; then
    echo ""
    echo "[verify:go-nolint-audit] LLM judge SKIPPED (set EVAL_LLM_JUDGE=1 to enable)"
    if [ "$FAIL" -gt 0 ]; then
        exit 1
    fi
    exit 0
fi

echo ""
echo "[verify:go-nolint-audit] Running LLM-as-judge evaluation..."

FIXTURE_CONTEXT="Test fixture (skills/go-nolint-audit/evals/fixture/main.go) had these directives:
- Line with fmt.Println: //nolint:errcheck — STALE (errcheck ignores fmt.* by default)
- Line with compute(): //nolint (bare) — BARE, no specific rule named
- Line with os.ReadFile: //nolint:errcheck — ACTIVE (error genuinely discarded), vague justification"

JUDGE_PROMPT="You are a strict evaluator for an AI skill called 'go-nolint-audit'.
The skill audits //nolint directives through two phases:
  Phase 1: mechanical verification using golangci-lint (stale vs active classification)
  Phase 2: adversarial Red/Blue/White team debate on the top candidates

${FIXTURE_CONTEXT}

Evaluate the following skill output on four criteria (score each 1-5):
  1. Debate depth: Red and Blue sides cite specific code details, not just generalities (5=specific code citations, 1=generic)
  2. Diff quality: Red team provides applicable, concrete code diffs (5=applicable diffs, 1=pseudocode or no diff)
  3. Justification challenge: Blue adds reasoning beyond the existing comment (5=new reasoning added, 1=just repeats comment)
  4. Verdict reasoning: White explains tradeoffs with evidence (5=evidenced tradeoffs, 1=bare verdict)

Output to evaluate:
${OUTPUT}

Respond in exactly this format (one per line, nothing else):
DEBATE_DEPTH: <1-5>
DIFF_QUALITY: <1-5>
JUSTIFICATION_CHALLENGE: <1-5>
VERDICT_REASONING: <1-5>
VERDICT: PASS or FAIL"

JUDGE_OUTPUT=$(opencode run "$JUDGE_PROMPT" 2>&1) || true
echo "$JUDGE_OUTPUT"
echo ""

for criterion in DEBATE_DEPTH DIFF_QUALITY JUSTIFICATION_CHALLENGE VERDICT_REASONING; do
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
echo "[verify:go-nolint-audit] === All checks: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
