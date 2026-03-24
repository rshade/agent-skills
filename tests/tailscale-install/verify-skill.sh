#!/bin/bash
# Verify that the tailscale-install skill worked end-to-end.
# Called by test-skill after OpenCode finishes.

set -euo pipefail

PASS=0
FAIL=0

pass() { echo "[verify:tailscale-install] PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "[verify:tailscale-install] FAIL: $1"; FAIL=$((FAIL + 1)); }

# Check 1: tailscale binary exists
if tailscale version >/dev/null 2>&1; then
    VERSION=$(tailscale version | head -1)
    pass "tailscale binary installed: ${VERSION}"
else
    fail "tailscale binary not found"
fi

# Check 2: tailscaled can start (userspace networking for containers)
tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state &
DAEMON_PID=$!
sleep 3

if kill -0 "$DAEMON_PID" 2>/dev/null; then
    pass "tailscaled starts successfully"
else
    fail "tailscaled failed to start"
fi

# Check 3: tailscale status responds (daemon is functional)
STATUS_OUTPUT=$(tailscale status 2>&1 || true)
if echo "$STATUS_OUTPUT" | grep -qi "logged out\|NeedsLogin\|stopped"; then
    pass "tailscale daemon is functional"
else
    fail "tailscale daemon not responding properly"
fi

# Cleanup
kill "$DAEMON_PID" 2>/dev/null || true
wait "$DAEMON_PID" 2>/dev/null || true

echo ""
echo "[verify:tailscale-install] === Verification: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
