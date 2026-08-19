#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load .env from repo root if it exists
if [ -f "$REPO_ROOT/.env" ]; then
    echo "Loading .env from repo root..."
    set -a
    # shellcheck source=/dev/null
    . "$REPO_ROOT/.env"
    set +a
fi

cd "$SCRIPT_DIR"

echo "========================================="
echo " Nix Install Skill — Test Suite"
echo "========================================="
echo ""

# Build all containers
echo "Building test containers..."
docker compose build

echo ""
echo "Running tests..."
echo ""

EXIT_CODE=0
for distro in ubuntu fedora; do
    echo "--- Testing ${distro} ---"
    if docker compose run --rm "test-${distro}"; then
        echo "--- ${distro}: PASSED ---"
    else
        echo "--- ${distro}: FAILED ---"
        EXIT_CODE=1
    fi
    echo ""
done

# Cleanup
docker compose down --remove-orphans 2>/dev/null || true

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "========================================="
    echo " TIER 1-2 PASSED"
    echo "========================================="
else
    echo "========================================="
    echo " TIER 1-2: SOME TESTS FAILED"
    echo "========================================="
    exit "$EXIT_CODE"
fi

# ── Tier 4: AI Agent Skill Test (requires OPENCODE_API_KEY) ──────────

if [ -z "${OPENCODE_API_KEY:-}" ]; then
    echo ""
    echo "Tier 4: SKIPPED (no OPENCODE_API_KEY set)"
    echo "Set OPENCODE_API_KEY in .env to test skill with an AI agent."
else
    echo ""
    echo "========================================="
    echo " Tier 4: AI Agent Skill Test"
    echo "========================================="
    echo ""
    if "$REPO_ROOT/tests/run-skill-test.sh" \
        nix-install \
        "install nix on this machine" \
        tests/nix-install/verify-skill.sh; then
        echo "--- Tier 4: PASSED ---"
    else
        echo "--- Tier 4: FAILED ---"
        EXIT_CODE=1
    fi
fi

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "========================================="
    echo " ALL TESTS PASSED"
    echo "========================================="
else
    echo "========================================="
    echo " SOME TESTS FAILED"
    echo "========================================="
fi

exit "$EXIT_CODE"
