#!/bin/bash
set -euo pipefail

# ── Generic Skill Test Runner ─────────────────────────────────────────
#
# Tests that an AI agent can discover and execute a skill end-to-end.
#
# Usage:
#   test-skill --skill <name> --prompt <text> [--verify <script>] [--setup <script>]
#
# Environment:
#   OPENCODE_API_KEY   — Required. LLM API key for OpenCode.
#   SKILL_DIR          — Path to the skill source (default: /workspace/skills/<name>)
#
# The runner:
#   1. Copies the skill into OpenCode's discovery path
#   2. Optionally runs a setup script (install dependencies, etc.)
#   3. Invokes OpenCode with the prompt
#   4. Optionally runs a verification script to check the outcome
#   5. Reports pass/fail

SKILL_NAME=""
PROMPT=""
VERIFY_SCRIPT=""
SETUP_SCRIPT=""
SKILL_DIR=""
MAX_TURNS="${MAX_TURNS:-15}"

usage() {
    echo "Usage: test-skill --skill <name> --prompt <text> [--verify <script>] [--setup <script>]"
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        --skill)  SKILL_NAME="$2"; shift 2 ;;
        --prompt) PROMPT="$2"; shift 2 ;;
        --verify) VERIFY_SCRIPT="$2"; shift 2 ;;
        --setup)  SETUP_SCRIPT="$2"; shift 2 ;;
        --skill-dir) SKILL_DIR="$2"; shift 2 ;;
        --max-turns) MAX_TURNS="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

if [ -z "$SKILL_NAME" ] || [ -z "$PROMPT" ]; then
    echo "Error: --skill and --prompt are required"
    usage
fi

if [ -z "${OPENCODE_API_KEY:-}" ]; then
    echo "Error: OPENCODE_API_KEY is not set"
    exit 1
fi

PASS=0
FAIL=0

log()  { echo "[skill-test:${SKILL_NAME}] $*"; }
pass() { log "PASS: $1"; PASS=$((PASS + 1)); }
fail() { log "FAIL: $1"; FAIL=$((FAIL + 1)); }

# ── Step 1: Install skill into discovery path ─────────────────────────

SKILL_DIR="${SKILL_DIR:-/workspace/skills/${SKILL_NAME}}"
INSTALL_DIR="/workspace/.opencode/skills/${SKILL_NAME}"

log "Installing skill from ${SKILL_DIR}..."

if [ ! -f "${SKILL_DIR}/SKILL.md" ]; then
    fail "SKILL.md not found at ${SKILL_DIR}/SKILL.md"
    exit 1
fi

mkdir -p "$INSTALL_DIR"
cp -r "${SKILL_DIR}"/* "$INSTALL_DIR/"

if [ -f "${INSTALL_DIR}/SKILL.md" ]; then
    pass "Skill installed to ${INSTALL_DIR}"
else
    fail "Skill installation failed"
    exit 1
fi

# ── Step 2: Run optional setup script ─────────────────────────────────

if [ -n "$SETUP_SCRIPT" ] && [ -f "$SETUP_SCRIPT" ]; then
    log "Running setup script: ${SETUP_SCRIPT}"
    if bash "$SETUP_SCRIPT"; then
        pass "Setup completed"
    else
        fail "Setup script failed"
        exit 1
    fi
fi

# ── Step 3: Initialize git repo (OpenCode requires it) ────────────────

if [ ! -d "/workspace/.git" ]; then
    git config --global user.email "test@test.local"
    git config --global user.name "Test"
    git init /workspace >/dev/null 2>&1
fi

# ── Step 4: Run OpenCode with the prompt ──────────────────────────────

log "Running OpenCode with prompt: ${PROMPT}"
log "Max turns: ${MAX_TURNS}"

AGENT_OUTPUT=$(opencode run "${PROMPT}" 2>&1) || true
AGENT_EXIT=$?

# Save output for debugging
echo "$AGENT_OUTPUT" > /tmp/agent-output.txt

if [ $AGENT_EXIT -eq 0 ]; then
    pass "OpenCode completed successfully"
else
    log "OpenCode exited with code ${AGENT_EXIT}"
    log "Output (last 20 lines):"
    echo "$AGENT_OUTPUT" | tail -20
    fail "OpenCode exited with non-zero code"
fi

# ── Step 5: Run verification script ───────────────────────────────────

if [ -n "$VERIFY_SCRIPT" ] && [ -f "$VERIFY_SCRIPT" ]; then
    log "Running verification: ${VERIFY_SCRIPT}"
    if bash "$VERIFY_SCRIPT"; then
        pass "Verification passed"
    else
        fail "Verification failed"
    fi
elif [ -n "$VERIFY_SCRIPT" ]; then
    log "Warning: verify script '${VERIFY_SCRIPT}' not found, skipping"
fi

# ── Summary ───────────────────────────────────────────────────────────

echo ""
log "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
