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
    echo "Error: OPENCODE_API_KEY is required for shellcheck skill tests."
    echo "Set it in .env or environment."
    exit 1
fi

echo "========================================="
echo " Shellcheck Skill — Test Suite"
echo "========================================="
echo ""

# Validate a test fixture with known shell script errors to test the skill end-to-end
"$REPO_ROOT/tests/run-skill-test.sh" \
    shellcheck \
    "validate the shell script at skills/shellcheck/evals/test-script.sh using the shellcheck skill" \
    tests/shellcheck/verify-skill.sh

exit $?
