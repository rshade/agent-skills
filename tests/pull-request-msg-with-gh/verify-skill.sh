#!/bin/bash
set -euo pipefail

# Verify that the pull-request-msg-with-gh skill produced a valid PR_MESSAGE.md.
# Checks both the generated file and /tmp/agent-output.txt saved by test-skill.sh.

PASS=0
FAIL=0

pass() { echo "[verify:pr-msg] PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "[verify:pr-msg] FAIL: $1"; FAIL=$((FAIL + 1)); }

# ── Check 1: PR_MESSAGE.md exists ────────────────────────────────────

PR_FILE=""
for candidate in /workspace/PR_MESSAGE.md /tmp/PR_MESSAGE.md; do
    if [ -f "$candidate" ]; then
        PR_FILE="$candidate"
        break
    fi
done

if [ -n "$PR_FILE" ]; then
    pass "PR_MESSAGE.md exists at ${PR_FILE}"
else
    fail "PR_MESSAGE.md not found in /workspace or /tmp"
    echo "[verify:pr-msg] === Verification: ${PASS} passed, ${FAIL} failed ==="
    exit 1
fi

CONTENT=$(cat "$PR_FILE")
FIRST_LINE=$(head -1 "$PR_FILE")

# ── Check 2: Conventional commit subject ─────────────────────────────

COMMIT_TYPE_PATTERN="^(feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert)(\(.+\))?!?: .+"
if echo "$FIRST_LINE" | grep -qE "$COMMIT_TYPE_PATTERN"; then
    pass "First line is conventional commit format: ${FIRST_LINE}"
else
    fail "First line is not conventional commit format: '${FIRST_LINE}'"
fi

# ── Check 3: Summary section ─────────────────────────────────────────

if echo "$CONTENT" | grep -qi "## Summary\|## Overview"; then
    pass "Summary/Overview section present"
else
    fail "No ## Summary or ## Overview section found"
fi

# ── Check 4: Test plan section ────────────────────────────────────────

if echo "$CONTENT" | grep -qi "## Test plan\|## Test Plan\|## Testing"; then
    pass "Test plan section present"
else
    fail "No ## Test plan section found"
fi

# ── Check 5: Changes section ─────────────────────────────────────────

if echo "$CONTENT" | grep -qi "## Changes\|### New files\|### Modified files"; then
    pass "Changes section present"
else
    fail "No ## Changes section found"
fi

# ── Check 6: Trailing newline ─────────────────────────────────────────

if [ -n "$(tail -c 1 "$PR_FILE")" ]; then
    fail "File does not end with a trailing newline"
else
    pass "File ends with trailing newline"
fi

# ── Check 7: No Commit Message section (critical rule) ───────────────

if echo "$CONTENT" | grep -qi "## Commit Message"; then
    fail "File contains a '## Commit Message' section (forbidden by skill rules)"
else
    pass "No forbidden '## Commit Message' section"
fi

# ── Check 8: Content is substantive ──────────────────────────────────

CONTENT_LEN=${#CONTENT}
if [ "$CONTENT_LEN" -gt 200 ]; then
    pass "Content is substantive (${CONTENT_LEN} chars)"
else
    fail "Content too short (${CONTENT_LEN} chars, expected >200)"
fi

echo ""
echo "[verify:pr-msg] === Structural checks: ${PASS} passed, ${FAIL} failed ==="

# ── LLM-as-judge (gated by EVAL_LLM_JUDGE=1) ────────────────────────

if [ "${EVAL_LLM_JUDGE:-}" != "1" ]; then
    echo ""
    echo "[verify:pr-msg] LLM judge SKIPPED (set EVAL_LLM_JUDGE=1 to enable)"
    if [ "$FAIL" -gt 0 ]; then
        exit 1
    fi
    exit 0
fi

echo ""
echo "[verify:pr-msg] Running LLM-as-judge evaluation..."

FIXTURE_CONTEXT="The git fixture had:
- Branch: feat/add-user-auth (2 commits ahead of main)
- Commit 1: feat: add user authentication and logout (auth.py with authenticate/logout functions)
- Commit 2: test: add unit tests for auth module (tests.py with 4 test functions)
- No associated GitHub issue"

JUDGE_PROMPT="You are a strict evaluator for an AI skill called 'pull-request-msg-with-gh'.
The skill generates a PR_MESSAGE.md file with: conventional commit subject, summary, test plan, and changes.

${FIXTURE_CONTEXT}

Evaluate the following PR_MESSAGE.md content on four criteria (score each 1-5):
  1. Subject quality: Conventional commit format, concise, accurate type (5=perfect format+type, 1=missing or wrong)
  2. Summary depth: Adds context beyond the commit subject, not redundant (5=rich context, 1=just restates subject)
  3. Test plan completeness: Lists concrete validation steps (5=specific actionable items, 1=vague or missing)
  4. Changes accuracy: Lists files with descriptions matching actual changes (5=all files correct, 1=wrong or missing)

PR_MESSAGE.md content:
${CONTENT}

Respond in exactly this format (one per line, nothing else):
SUBJECT_QUALITY: <1-5>
SUMMARY_DEPTH: <1-5>
TEST_PLAN_COMPLETENESS: <1-5>
CHANGES_ACCURACY: <1-5>
VERDICT: PASS or FAIL"

JUDGE_OUTPUT=$(opencode run "$JUDGE_PROMPT" 2>&1) || true
echo "$JUDGE_OUTPUT"
echo ""

for criterion in SUBJECT_QUALITY SUMMARY_DEPTH TEST_PLAN_COMPLETENESS CHANGES_ACCURACY; do
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
echo "[verify:pr-msg] === All checks: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
