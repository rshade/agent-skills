# Subnet Route Lifecycle

A subnet route passes through seven stages before traffic flows
end-to-end. A failure at any stage breaks connectivity silently —
later stages have no error to report because packets never arrive.

## Stage 1 — Advertise

The subnet router tells the coordination server it can route to a CIDR.

```bash
tailscale set --advertise-routes=10.100.0.0/24
```

In Docker, `TS_ROUTES=10.100.0.0/24` in the environment. This only
takes effect if the initial auth succeeds — if the auth key is invalid
or expired, containerboot skips route advertisement without a clear
error.

Verify:

```bash
tailscale status --json | jq '.Self.AllowedIPs'
```

The advertised CIDR must appear alongside the node's Tailscale IP.

## Stage 2 — Approve

An admin (or ACL autoApprover) grants permission for the route.

- **Manual:** Admin console → device → Subnets → approve
- **Automatic:** ACL `autoApprovers` section:

```json
"autoApprovers": {
  "routes": {
    "10.100.0.0/24": ["tag:subnet-router"]
  }
}
```

Until approved, the route exists only on the advertising node. Peers
cannot see it.

## Stage 3 — Distribute

The coordination server pushes the approved route to all peers. The
subnet router's AllowedIPs — as seen by peers — now includes the
subnet CIDR.

This stage is automatic and usually instant, but can take 30-60 seconds
on large tailnets or when the coordination server is under load.

Verify from a peer:

```bash
tailscale status --json | jq '.Peer[] | select(.HostName=="<router>") | .AllowedIPs'
```

## Stage 4 — Accept

Each client must opt in to using subnet routes. The default is **off**.

```bash
tailscale set --accept-routes=true
```

In Docker, add `--accept-routes` to `TS_EXTRA_ARGS`.

This is the most commonly missed step. The route is approved and
distributed, but clients silently ignore it because `--accept-routes`
defaults to false.

Verify:

```bash
tailscale debug prefs | grep -i route
```

## Stage 5 — Install

The client installs the route into its local policy routing table.
Tailscale uses **table 52** — not the main routing table.

```bash
ip route show table 52
```

The route appears as something like:

```text
10.100.0.0/24 dev tailscale0
```

Tailscale also adds `ip rule` entries that direct matching traffic to
table 52. See `policy-routing.md` for the full explanation.

## Stage 6 — Forward

The subnet router receives packets from the tailnet and forwards them
to the target on the physical network. This requires:

- **IP forwarding enabled:** `net.ipv4.ip_forward=1`
- **Network access:** The subnet router must have an interface on (or
  a route to) the advertised subnet
- **No firewall blocking:** iptables/nftables must permit forwarding

## Stage 7 — Return

The target device sends its response. The response must reach the
subnet router so it can relay back through the tailnet.

If the subnet router is **not** the target's default gateway, return
traffic goes to the real gateway, which doesn't know about Tailscale
IPs (100.x.y.z) and drops the packet.

Solutions:

- **SNAT/masquerade** on the subnet router — the target sees the
  router's LAN IP as the source, so responses naturally return to it.
  Tailscale 1.64+ enables `--snat-subnet-routes` by default.
- **Static route** on the target or its gateway for `100.64.0.0/10`
  pointing to the subnet router's internal IP.

## Quick reference

| Stage | Who acts | Default | Verify command |
|---|---|---|---|
| Advertise | Subnet router | Off | `tailscale status --json \| jq '.Self.AllowedIPs'` |
| Approve | Admin / ACL | Pending | Admin console or peer's view of AllowedIPs |
| Distribute | Coordination server | Automatic | Peer's `tailscale status --json` |
| Accept | Each client | **Off** | `tailscale debug prefs \| grep route` |
| Install | Client OS | Automatic | `ip route show table 52` |
| Forward | Subnet router kernel | Off | `cat /proc/sys/net/ipv4/ip_forward` |
| Return | Target network | Varies | Ping from client through subnet router |
