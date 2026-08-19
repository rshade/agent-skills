#!/bin/bash
# Verify that the nix-install skill worked end-to-end.
# Called by run-skill-test.sh after the agent finishes.

set -euo pipefail

PASS=0
FAIL=0

pass() { echo "[verify:nix-install] PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "[verify:nix-install] FAIL: $1"; FAIL=$((FAIL + 1)); }

# Source the Nix profile if present
# shellcheck source=/dev/null
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null \
    || . /etc/profile.d/nix.sh 2>/dev/null \
    || true

# Check 1: nix binary exists
if command -v nix >/dev/null 2>&1; then
    VERSION=$(nix --version)
    pass "nix binary installed: ${VERSION}"
else
    fail "nix binary not found"
fi

# Check 2: /nix store directory exists
if [ -d /nix/store ]; then
    pass "/nix/store directory present"
else
    fail "/nix/store directory missing"
fi

# Check 3: Functional install (nix-shell can fetch and run a package)
if HELLO_OUTPUT=$(nix-shell -p hello --run hello 2>&1); then
    if echo "$HELLO_OUTPUT" | grep -q "Hello, world"; then
        pass "nix-shell -p hello succeeds"
    else
        fail "nix-shell -p hello returned unexpected output"
    fi
else
    fail "nix-shell -p hello failed"
fi

# Check 4: Either Determinate receipt OR upstream profile present
# (the agent may have chosen either installer)
if [ -f /nix/receipt.json ]; then
    pass "Determinate Systems installer detected (/nix/receipt.json)"
elif [ -f /etc/profile.d/nix.sh ]; then
    pass "Upstream installer detected (/etc/profile.d/nix.sh)"
else
    fail "Neither installer signature found"
fi

echo ""
echo "[verify:nix-install] === Verification: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
