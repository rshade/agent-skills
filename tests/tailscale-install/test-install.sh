#!/bin/bash
set -euo pipefail

DISTRO="${DISTRO:-unknown}"
HOSTNAME="test-${DISTRO}"
PASS=0
FAIL=0

log() { echo "[${DISTRO}] $*"; }
pass() { log "PASS: $1"; PASS=$((PASS + 1)); }
fail() { log "FAIL: $1"; FAIL=$((FAIL + 1)); }

# ── Tier 1: Install ──────────────────────────────────────────────────

log "=== Tier 1: Installation ==="

log "Installing Tailscale package..."

# Install via package manager directly (not install.sh) because the
# official installer calls systemctl which doesn't exist in containers.
case "${DISTRO}" in
    ubuntu|debian)
        curl -fsSL "https://pkgs.tailscale.com/stable/${DISTRO}/$(. /etc/os-release && echo "$VERSION_CODENAME").noarmor.gpg" \
            | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
        curl -fsSL "https://pkgs.tailscale.com/stable/${DISTRO}/$(. /etc/os-release && echo "$VERSION_CODENAME").tailscale-keyring.list" \
            | tee /etc/apt/sources.list.d/tailscale.list
        apt-get update && apt-get install -y tailscale
        ;;
    fedora)
        dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
        dnf install -y tailscale
        ;;
    alpine)
        apk add --no-cache tailscale
        ;;
    *)
        curl -fsSL https://tailscale.com/install.sh | sh || true
        ;;
esac

if tailscale version >/dev/null 2>&1; then
    pass "Package installed"
else
    fail "Package installation failed"
    log "Results: ${PASS} passed, ${FAIL} failed"
    exit 1
fi

VERSION=$(tailscale version | head -1)
pass "Binary available: ${VERSION}"

# ── Tier 2: Daemon Start ─────────────────────────────────────────────

log "=== Tier 2: Daemon Start ==="

log "Starting tailscaled with userspace networking..."
tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state &
DAEMON_PID=$!

log "Waiting for daemon to be ready..."
READY=0
for i in $(seq 1 10); do
    if tailscale status 2>&1 >/dev/null; then
        READY=1
        break
    fi
    sleep 1
done

if kill -0 "$DAEMON_PID" 2>/dev/null; then
    pass "tailscaled is running (PID: ${DAEMON_PID})"
else
    fail "tailscaled failed to start"
    log "Results: ${PASS} passed, ${FAIL} failed"
    exit 1
fi

STATUS_OUTPUT=$(tailscale status 2>&1 || true)
if echo "$STATUS_OUTPUT" | grep -qi "logged out\|NeedsLogin\|stopped"; then
    pass "tailscale status reports not connected (expected before auth)"
else
    log "Unexpected status output: $(echo "$STATUS_OUTPUT" | head -3)"
    fail "tailscale status returned unexpected result"
fi

# ── Tier 3: Connect (requires TS_AUTHKEY) ─────────────────────────────

if [ -z "${TS_AUTHKEY:-}" ]; then
    log "=== Tier 3: SKIPPED (no TS_AUTHKEY set) ==="
    log "Set TS_AUTHKEY to enable connection and peer tests"
else
    log "=== Tier 3: Connection ==="

    log "Connecting to tailnet as ${HOSTNAME}..."
    if tailscale up --authkey="${TS_AUTHKEY}" --hostname="${HOSTNAME}"; then
        pass "Connected to tailnet"
    else
        fail "Failed to connect to tailnet"
        log "Results: ${PASS} passed, ${FAIL} failed"
        exit 1
    fi

    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
    if [ -n "${TAILSCALE_IP}" ]; then
        pass "Got Tailscale IP: ${TAILSCALE_IP}"
    else
        fail "No Tailscale IPv4 address assigned"
    fi

    CONN_STATUS=$(tailscale status 2>&1 || true)
    if echo "$CONN_STATUS" | grep -q "100\."; then
        pass "Device is connected (visible in tailscale status)"
    else
        fail "Device not visible in tailscale status"
    fi

    # ── Peer connectivity (wait for peers, then ping) ─────────────

    log "Waiting for peers to appear..."
    PEER_WAIT=0
    PEER_MAX_WAIT=60
    PEERS_FOUND=0
    while [ $PEER_WAIT -lt $PEER_MAX_WAIT ]; do
        PEERS_FOUND=$( (tailscale status 2>/dev/null || true) | grep -c "test-" || true)
        # Subtract 1 for self
        OTHER_PEERS=$((PEERS_FOUND > 1 ? PEERS_FOUND - 1 : 0))
        if [ "$OTHER_PEERS" -gt 0 ]; then
            log "Found ${OTHER_PEERS} other test peer(s)"
            break
        fi
        sleep 5
        PEER_WAIT=$((PEER_WAIT + 5))
    done

    if [ "$OTHER_PEERS" -gt 0 ]; then
        pass "Discovered ${OTHER_PEERS} peer(s)"

        # Ping each peer
        PEER_LIST=$(tailscale status --json 2>/dev/null \
            | grep -o '"HostName":"test-[^"]*"' \
            | sed 's/"HostName":"//;s/"//' \
            | grep -v "${HOSTNAME}" || true)

        for PEER in $PEER_LIST; do
            log "Pinging ${PEER}..."
            if tailscale ping -c 3 "${PEER}" 2>/dev/null; then
                pass "Ping ${PEER} succeeded"
            else
                fail "Ping ${PEER} failed"
            fi
        done
    else
        log "No other test peers found within ${PEER_MAX_WAIT}s (may be first container)"
    fi

    # Clean disconnect
    tailscale down 2>/dev/null || true
fi

# ── Summary ───────────────────────────────────────────────────────────

kill "$DAEMON_PID" 2>/dev/null || true
wait "$DAEMON_PID" 2>/dev/null || true

echo ""
log "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
