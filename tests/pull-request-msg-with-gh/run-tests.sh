#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load .env
if [ -f "$REPO_ROOT/.env" ]; then
    set -a
    # shellcheck source=/dev/null
    . "$REPO_ROOT/.env"
    set +a
fi

if [ -z "${OPENCODE_API_KEY:-}" ]; then
    echo "Error: OPENCODE_API_KEY is required for pull-request-msg-with-gh skill tests."
    echo "Set it in .env or environment."
    exit 1
fi

echo "========================================="
echo " PR Message Skill — Test Suite"
echo "========================================="
echo ""

# Build the base image
echo "Building base test image..."
docker build -t skill-test-base -f "$REPO_ROOT/tests/base/Dockerfile" "$REPO_ROOT/tests/base/"
echo ""

# Create temporary workspace
TMPDIR=$(mktemp -d)
trap 'docker run --rm -v "$TMPDIR:/cleanup" alpine rm -rf /cleanup 2>/dev/null; rm -rf "$TMPDIR" 2>/dev/null' EXIT

# Copy skills, verify script, and setup script
cp -r "$REPO_ROOT/skills" "$TMPDIR/skills"
cp "$SCRIPT_DIR/verify-skill.sh" "$TMPDIR/verify.sh"
cp "$SCRIPT_DIR/setup-fixture.sh" "$TMPDIR/setup.sh"
chmod +x "$TMPDIR/verify.sh" "$TMPDIR/setup.sh"

echo "Running agent test..."
echo ""

docker run --rm \
    -v "$TMPDIR:/workspace" \
    -e "OPENCODE_API_KEY=${OPENCODE_API_KEY}" \
    -e "EVAL_LLM_JUDGE=${EVAL_LLM_JUDGE:-}" \
    skill-test-base \
    --skill pull-request-msg-with-gh \
    --prompt "Use the pull-request-msg-with-gh skill to generate a PR_MESSAGE.md for the current changes on this branch. There is no associated GitHub issue — omit the Closes footer. Skip gh auth check since gh is not available." \
    --setup /workspace/setup.sh \
    --verify /workspace/verify.sh

EXIT_CODE=$?

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "========================================="
    echo " SKILL TEST PASSED: pull-request-msg-with-gh"
    echo "========================================="
else
    echo "========================================="
    echo " SKILL TEST FAILED: pull-request-msg-with-gh"
    echo "========================================="
fi

exit "$EXIT_CODE"
