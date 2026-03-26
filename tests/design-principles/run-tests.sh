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
    echo "Error: OPENCODE_API_KEY is required for design-principles skill tests."
    echo "Set it in .env or environment."
    exit 1
fi

echo "========================================="
echo " Design Principles Skill — Test Suite"
echo "========================================="
echo ""

# Audit the agent-skills repo itself against design principles
"$REPO_ROOT/tests/run-skill-test.sh" \
    design-principles \
    "Use the design-principles skill to audit the current codebase for design principle violations." \
    tests/design-principles/verify-skill.sh

exit $?
