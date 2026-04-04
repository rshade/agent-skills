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
    echo "Error: OPENCODE_API_KEY is required for hadolint skill tests."
    echo "Set it in .env or environment."
    exit 1
fi

echo "========================================="
echo " Hadolint Skill — Test Suite"
echo "========================================="
echo ""

# Validate a test fixture with known Dockerfile errors to test the skill end-to-end
"$REPO_ROOT/tests/run-skill-test.sh" \
    hadolint \
    "validate the Dockerfile at skills/hadolint/evals/Dockerfile.test using the hadolint skill" \
    tests/hadolint/verify-skill.sh

exit $?
