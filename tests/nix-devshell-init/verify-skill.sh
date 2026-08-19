#!/bin/bash
# Verify that the nix-devshell-init skill worked end-to-end.
# Called by run-skill-test.sh after the agent finishes.
# Expects to run in a directory where the agent was asked to
# scaffold a devShell for a Go project.

set -euo pipefail

PASS=0
FAIL=0

pass() { echo "[verify:nix-devshell-init] PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "[verify:nix-devshell-init] FAIL: $1"; FAIL=$((FAIL + 1)); }

# Check 1: flake.nix was created
if [ -f flake.nix ]; then
    pass "flake.nix exists"
else
    fail "flake.nix not created"
fi

# Check 2: .envrc was created with 'use flake'
if [ -f .envrc ] && grep -q "use flake" .envrc; then
    pass ".envrc contains 'use flake'"
elif [ -f .envrc ]; then
    fail ".envrc exists but missing 'use flake'"
else
    fail ".envrc not created"
fi

# Check 3: flake.nix contains devShells output
if [ -f flake.nix ] && grep -q "devShells" flake.nix; then
    pass "flake.nix contains devShells output"
else
    fail "flake.nix missing devShells output"
fi

# Check 4: flake.nix contains language-appropriate packages
# (we're in a Go project fixture, so expect 'go' or 'gopls')
if [ -f flake.nix ] && grep -qE "go|gopls" flake.nix; then
    pass "flake.nix contains Go packages"
else
    fail "flake.nix missing expected Go packages"
fi

# Check 5: flake evaluates cleanly (if nix is available)
if command -v nix >/dev/null 2>&1 && [ -f flake.nix ]; then
    if nix flake check --no-build 2>&1; then
        pass "nix flake check passes"
    else
        fail "nix flake check failed"
    fi
else
    echo "[verify:nix-devshell-init] SKIP: nix not available for flake check"
fi

echo ""
echo "[verify:nix-devshell-init] === Verification: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
