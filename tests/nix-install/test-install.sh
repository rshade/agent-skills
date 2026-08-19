#!/bin/bash
set -euo pipefail

DISTRO="${DISTRO:-unknown}"
PASS=0
FAIL=0

log() { echo "[${DISTRO}] $*"; }
pass() { log "PASS: $1"; PASS=$((PASS + 1)); }
fail() { log "FAIL: $1"; FAIL=$((FAIL + 1)); }

# ── Tier 1: Install ──────────────────────────────────────────────────

log "=== Tier 1: Installation ==="

log "Installing Nix via Determinate Systems installer (init=none)..."

# Containers do not run systemd, so we use --init none.
# This still installs Nix correctly; just no daemon.
curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix \
    | sh -s -- install linux --no-confirm --init none

# Source the Nix profile so subsequent commands find `nix`
# shellcheck source=/dev/null
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null \
    || . /etc/profile.d/nix.sh 2>/dev/null \
    || true

if command -v nix >/dev/null 2>&1; then
    pass "nix binary installed"
else
    fail "nix binary not found after install"
    log "Results: ${PASS} passed, ${FAIL} failed"
    exit 1
fi

VERSION=$(nix --version)
pass "Binary available: ${VERSION}"

# Verify the receipt file exists (Determinate-specific)
if [ -f /nix/receipt.json ]; then
    pass "/nix/receipt.json present (Determinate installer signature)"
else
    fail "/nix/receipt.json missing"
fi

# ── Tier 2: Functional test ──────────────────────────────────────────

log "=== Tier 2: Functional verification ==="

# Flakes should be enabled by default with the Determinate installer
if nix flake --help >/dev/null 2>&1; then
    pass "Flakes enabled by default"
else
    fail "Flakes not enabled (expected with Determinate installer)"
fi

# Functional test: nix-shell with hello
log "Running nix-shell -p hello..."
if HELLO_OUTPUT=$(nix-shell -p hello --run hello 2>&1); then
    if echo "$HELLO_OUTPUT" | grep -q "Hello, world"; then
        pass "nix-shell hello works: ${HELLO_OUTPUT}"
    else
        fail "nix-shell hello returned unexpected output: ${HELLO_OUTPUT}"
    fi
else
    fail "nix-shell -p hello failed"
fi

# ── Summary ───────────────────────────────────────────────────────────

echo ""
log "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
