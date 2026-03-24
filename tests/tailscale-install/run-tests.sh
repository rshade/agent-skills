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
echo " Tailscale Install Skill — Test Suite"
echo "========================================="
echo ""

if [ -n "${TS_AUTHKEY:-}" ]; then
    echo "TS_AUTHKEY is set — running Tier 1 + 2 + 3 (install, daemon, connect)"
    echo "Containers will join your test tailnet with ephemeral keys."
else
    echo "TS_AUTHKEY is not set — running Tier 1 + 2 only (install, daemon)"
    echo "Set TS_AUTHKEY in .env or environment to enable Tier 3."
fi
echo ""

# Build all containers
echo "Building test containers..."
docker compose build

# Run all containers in parallel for peer discovery
echo ""
echo "Running tests..."
echo ""

if [ -n "${TS_AUTHKEY:-}" ]; then
    # Tier 3: run all containers together so they can discover peers.
    # Use 'up' without --abort-on-container-exit so all containers
    # have time to find each other. They self-terminate after testing.
    docker compose up --timeout 120 || true

    EXIT_CODE=0
    echo ""
    for distro in ubuntu fedora alpine; do
        # Check container exit code from docker inspect
        CONTAINER="tailscale-install-test-${distro}-1"
        CODE=$(docker inspect --format='{{.State.ExitCode}}' "$CONTAINER" 2>/dev/null || echo "unknown")
        if [ "$CODE" = "0" ]; then
            echo "--- ${distro}: PASSED ---"
        else
            echo "--- ${distro}: FAILED (exit code ${CODE}) ---"
            EXIT_CODE=1
        fi
    done
else
    # Tier 1-2: run each container independently
    EXIT_CODE=0
    for distro in ubuntu fedora alpine; do
        echo "--- Testing ${distro} ---"
        if docker compose run --rm "test-${distro}"; then
            echo "--- ${distro}: PASSED ---"
        else
            echo "--- ${distro}: FAILED ---"
            EXIT_CODE=1
        fi
        echo ""
    done
fi

# Cleanup
docker compose down --remove-orphans 2>/dev/null || true

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "========================================="
    echo " TIER 1-3 PASSED"
    echo "========================================="
else
    echo "========================================="
    echo " TIER 1-3: SOME TESTS FAILED"
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
        tailscale-install \
        "install tailscale on this machine" \
        tests/tailscale-install/verify-skill.sh; then
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
