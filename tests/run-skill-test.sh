#!/bin/bash
set -euo pipefail

# ── Run AI Agent Skill Test ───────────────────────────────────────────
#
# Tests a skill by having OpenCode discover and execute it end-to-end.
#
# Usage:
#   ./tests/run-skill-test.sh <skill-name> "<prompt>" [verify-script]
#
# Examples:
#   ./tests/run-skill-test.sh tailscale-install "install tailscale on this machine" tests/tailscale-install/verify-skill.sh
#   ./tests/run-skill-test.sh decide "should we use postgres or mongodb for a blog?" tests/decide/verify-skill.sh
#   ./tests/run-skill-test.sh markdownlint "validate all markdown files in this project"
#
# Environment:
#   OPENCODE_API_KEY  — Required. Set in .env or environment.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load .env
if [ -f "$REPO_ROOT/.env" ]; then
    set -a
    # shellcheck source=/dev/null
    . "$REPO_ROOT/.env"
    set +a
fi

SKILL_NAME="${1:-}"
PROMPT="${2:-}"
VERIFY_SCRIPT="${3:-}"

if [ -z "$SKILL_NAME" ] || [ -z "$PROMPT" ]; then
    echo "Usage: $0 <skill-name> \"<prompt>\" [verify-script]"
    echo ""
    echo "Examples:"
    echo "  $0 tailscale-install \"install tailscale on this machine\" tests/tailscale-install/verify-skill.sh"
    echo "  $0 decide \"should we use postgres or mongodb?\" tests/decide/verify-skill.sh"
    exit 1
fi

if [ -z "${OPENCODE_API_KEY:-}" ]; then
    echo "Error: OPENCODE_API_KEY is not set."
    echo "Add it to .env or export it in your environment."
    exit 1
fi

echo "========================================="
echo " Skill Test: ${SKILL_NAME}"
echo "========================================="
echo "Prompt: ${PROMPT}"
echo ""

# Build the base image if not already built
echo "Building base test image..."
docker build -t skill-test-base -f "$SCRIPT_DIR/base/Dockerfile" "$SCRIPT_DIR/base/"

# Create a temporary directory with writable workspace contents
TMPDIR=$(mktemp -d)
trap 'docker run --rm -v "$TMPDIR:/cleanup" alpine rm -rf /cleanup 2>/dev/null; rm -rf "$TMPDIR" 2>/dev/null' EXIT

# Copy skills and verify script to temp workspace
cp -r "${REPO_ROOT}/skills" "$TMPDIR/skills"
if [ -n "$VERIFY_SCRIPT" ] && [ -f "$REPO_ROOT/$VERIFY_SCRIPT" ]; then
    cp "$REPO_ROOT/$VERIFY_SCRIPT" "$TMPDIR/verify.sh"
    chmod +x "$TMPDIR/verify.sh"
fi

# Prepare docker run args
DOCKER_ARGS=(
    --rm
    -v "${TMPDIR}:/workspace"
    -e "OPENCODE_API_KEY=${OPENCODE_API_KEY}"
    --cap-add NET_ADMIN
    --cap-add NET_RAW
)

VERIFY_ARG=""
if [ -f "$TMPDIR/verify.sh" ]; then
    VERIFY_ARG="--verify /workspace/verify.sh"
fi

# Pass through TS_AUTHKEY if available (for tailscale skills)
if [ -n "${TS_AUTHKEY:-}" ]; then
    DOCKER_ARGS+=(-e "TS_AUTHKEY=${TS_AUTHKEY}")
fi

echo "Running agent test..."
echo ""

# shellcheck disable=SC2086
docker run "${DOCKER_ARGS[@]}" skill-test-base \
    --skill "$SKILL_NAME" \
    --prompt "$PROMPT" \
    $VERIFY_ARG

EXIT_CODE=$?

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "========================================="
    echo " SKILL TEST PASSED: ${SKILL_NAME}"
    echo "========================================="
else
    echo "========================================="
    echo " SKILL TEST FAILED: ${SKILL_NAME}"
    echo "========================================="
fi

exit "$EXIT_CODE"
