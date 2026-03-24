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
    echo "Error: OPENCODE_API_KEY is required for decide skill tests."
    echo "Set it in .env or environment."
    exit 1
fi

echo "========================================="
echo " Decide Skill — Test Suite"
echo "========================================="
echo ""

# Simple binary decision to minimize token usage
"$REPO_ROOT/tests/run-skill-test.sh" \
    decide \
    "Use the decide skill: should our team use red or blue as the primary brand color for a developer tools startup?" \
    tests/decide/verify-skill.sh

exit $?
