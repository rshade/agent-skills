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
    echo "Error: OPENCODE_API_KEY is required for roadmap skill tests."
    echo "Set it in .env or environment."
    exit 1
fi

echo "========================================="
echo " Roadmap Skill — Test Suite"
echo "========================================="
echo ""

# Build the base image first, then the roadmap image with mock gh CLI
echo "Ensuring base test image..."
"$REPO_ROOT/tests/base/ensure-base-image.sh"
echo "Building roadmap test image..."
docker build -t skill-test-roadmap "$SCRIPT_DIR"
echo ""

# Create a temporary workspace
TMPDIR=$(mktemp -d)
trap 'docker run --rm -v "$TMPDIR:/cleanup" alpine rm -rf /cleanup 2>/dev/null; rm -rf "$TMPDIR" 2>/dev/null' EXIT

# Copy skills (includes eval fixtures)
cp -r "$REPO_ROOT/skills" "$TMPDIR/skills"

# Copy fixtures to workspace root so the skill finds them naturally
cp "$REPO_ROOT/skills/roadmap/evals/CONTEXT.md" "$TMPDIR/CONTEXT.md"
cp "$REPO_ROOT/skills/roadmap/evals/ROADMAP.md" "$TMPDIR/ROADMAP.md"

cp "$SCRIPT_DIR/verify-skill.sh" "$TMPDIR/verify.sh"
chmod +x "$TMPDIR/verify.sh"

echo "Running agent test (status mode)..."
echo ""

docker run --rm \
    -v "$TMPDIR:/workspace" \
    -e "OPENCODE_API_KEY=${OPENCODE_API_KEY}" \
    -e "EVAL_LLM_JUDGE=${EVAL_LLM_JUDGE:-}" \
    skill-test-roadmap \
    --skill roadmap \
    --prompt "use the roadmap skill in status mode to summarize the current roadmap state" \
    --verify /workspace/verify.sh

EXIT_CODE=$?

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "========================================="
    echo " SKILL TEST PASSED: roadmap"
    echo "========================================="
else
    echo "========================================="
    echo " SKILL TEST FAILED: roadmap"
    echo "========================================="
fi

exit "$EXIT_CODE"
