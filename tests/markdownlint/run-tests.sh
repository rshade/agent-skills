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
    echo "Error: OPENCODE_API_KEY is required for markdownlint skill tests."
    echo "Set it in .env or environment."
    exit 1
fi

echo "========================================="
echo " Markdownlint Skill — Test Suite"
echo "========================================="
echo ""

# Validate a test fixture with known lint errors to test the skill end-to-end
"$REPO_ROOT/tests/run-skill-test.sh" \
    markdownlint \
    "validate the markdown file at skills/markdownlint/evals/test-doc.md using the markdownlint skill" \
    tests/markdownlint/verify-skill.sh

exit $?
