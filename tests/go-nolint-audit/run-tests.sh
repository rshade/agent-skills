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
    echo "Error: OPENCODE_API_KEY is required for go-nolint-audit skill tests."
    echo "Set it in .env or environment."
    exit 1
fi

echo "========================================="
echo " Go Nolint Audit Skill — Test Suite"
echo "========================================="
echo ""

# Build the base image first, then the Go-enabled image that extends it
echo "Ensuring base test image..."
"$REPO_ROOT/tests/base/ensure-base-image.sh"
echo "Building go-nolint-audit test image..."
docker build -t skill-test-go-nolint-audit "$SCRIPT_DIR"
echo ""

# Create a temporary workspace
TMPDIR=$(mktemp -d)
trap 'docker run --rm -v "$TMPDIR:/cleanup" alpine rm -rf /cleanup 2>/dev/null; rm -rf "$TMPDIR" 2>/dev/null' EXIT

# Copy skills (includes the fixture at skills/go-nolint-audit/evals/fixture/)
cp -r "$REPO_ROOT/skills" "$TMPDIR/skills"
cp "$SCRIPT_DIR/verify-skill.sh" "$TMPDIR/verify.sh"
chmod +x "$TMPDIR/verify.sh"

echo "Running agent test..."
echo ""

docker run --rm \
    -v "$TMPDIR:/workspace" \
    -e "OPENCODE_API_KEY=${OPENCODE_API_KEY}" \
    -e "EVAL_LLM_JUDGE=${EVAL_LLM_JUDGE:-}" \
    skill-test-go-nolint-audit \
    --skill go-nolint-audit \
    --prompt "Use the go-nolint-audit skill to audit the nolint directives in the Go project at skills/go-nolint-audit/evals/fixture" \
    --verify /workspace/verify.sh

EXIT_CODE=$?

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "========================================="
    echo " SKILL TEST PASSED: go-nolint-audit"
    echo "========================================="
else
    echo "========================================="
    echo " SKILL TEST FAILED: go-nolint-audit"
    echo "========================================="
fi

exit "$EXIT_CODE"
