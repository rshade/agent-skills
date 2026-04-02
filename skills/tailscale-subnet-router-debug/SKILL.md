---
name: tailscale-subnet-router-debug
description: >
  Diagnose Tailscale subnet router connectivity failures. Traces the full
  route lifecycle: advertisement, approval, client acceptance, policy
  routing (table 52), and IP forwarding. Use when clients can reach
  Tailscale peers by IP but not devices on advertised subnets, or when
  subnet routes appear approved but traffic doesn't flow. Also use when
  Docker containers fail to advertise routes, when `ip route` shows no
  subnet route (it's in table 52), or when traffic flows one way but
  responses don't return.
---

# Tailscale Subnet Router Debug

Diagnose and fix Tailscale subnet router connectivity failures. Runs
seven sequential checks covering the full route lifecycle from
advertisement through return path verification.

## What this skill does

1. Verifies the subnet router advertises the route.
2. Confirms the route is approved (admin console or autoApprovers).
3. Checks that clients accept subnet routes (`--accept-routes`).
4. Inspects policy routing table 52 for installed routes.
5. Validates IP forwarding is enabled on the subnet router.
6. Tests that the subnet router can reach the target directly.
7. Verifies the return path for response traffic.

## Common triggers

- Client can ping the subnet router but not devices on the advertised subnet
- Route shows approved in admin console but `ip route` is empty
- Docker containers fail to advertise routes via `TS_ROUTES`
- Traffic flows to the target but responses never come back
- "It works from the router itself but not from other clients"

## Diagnostic workflow

Run each step in order. Stop at the first failure and apply the fix
before continuing — later steps depend on earlier ones.

### Step 1 — Verify route is advertised

```bash
tailscale status --json | jq '.Self.AllowedIPs'
```

**Pass:** Subnet CIDR appears in AllowedIPs (e.g., `10.100.0.0/24`).

**Fail:** Only Tailscale IPs shown. Route not advertised.

**Fix:** `tailscale set --advertise-routes=<CIDR>`. In Docker, check
`TS_ROUTES` env var — it may not take effect if auth failed on first
boot. Fall back to `tailscale set` at runtime.

### Step 2 — Verify route is approved

Check admin console, or from a **peer node**:

```bash
tailscale status --json | jq '.Peer[] | select(.HostName=="<router>") | .AllowedIPs'
```

**Pass:** Subnet CIDR appears in the peer's view of the router's AllowedIPs.

**Fail:** Only Tailscale IPs shown from peer perspective. Route is
pending approval.

**Fix:** Approve in admin console, or add `autoApprovers` to ACL:

```json
"autoApprovers": {
  "routes": { "10.100.0.0/24": ["tag:subnet"] }
}
```

### Step 3 — Verify client accepts routes

```bash
tailscale debug prefs | grep -i route
```

**Fail:** `--accept-routes` is false (the default). Clients ignore
advertised subnet routes even when approved.

**Fix:** `tailscale set --accept-routes=true`. In Docker, add
`--accept-routes` to `TS_EXTRA_ARGS`. Do not use `tailscale down` in
Docker — it kills containerboot. Use `tailscale set` instead.

### Step 4 — Verify route in policy routing table

```bash
ip route show table 52
```

**Pass:** Shows route for subnet CIDR via `dev tailscale0`.

**Fail:** Table 52 is empty or missing the subnet route.

**Critical:** `ip route` (no table) only shows the main table. Tailscale
uses policy routing table 52 — routes will NOT appear in default output.
This is the most common false negative.

Also check:

```bash
ip rule show
```

See `references/policy-routing.md` for details on table 52 and how
Tailscale's policy routing works.

### Step 5 — Verify IP forwarding on the subnet router

```bash
cat /proc/sys/net/ipv4/ip_forward
```

**Pass:** Returns `1`.

**Fail:** Returns `0`. Kernel drops forwarded packets silently.

**Fix:** `sysctl -w net.ipv4.ip_forward=1`. In Docker Compose, set
`sysctls: [net.ipv4.ip_forward=1]`. For persistence on Linux hosts,
add to `/etc/sysctl.d/`.

### Step 6 — Verify network path from subnet router to target

From the subnet router:

```bash
ping <target-ip>
ip addr show
```

**Pass:** Router can reach the target and has an interface on the
advertised subnet.

**Fail:** Router cannot reach the target. This is a local network issue
(firewall, VLAN, routing) — not Tailscale.

### Step 7 — Verify return path

The target must route responses back through the subnet router. If the
target's default gateway is not the subnet router, return traffic takes
a different path and gets dropped.

**Fix:** Add a static route on the target (or its gateway) for
`100.64.0.0/10` pointing to the subnet router's internal IP. Or enable
masquerading:

```bash
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
```

Tailscale 1.64+ enables `--snat-subnet-routes` by default, which
handles this automatically.

## Error handling

Do not silently skip a failed check. Report the specific failure with
the fix before continuing. If a fix requires restarting Tailscale or
recreating a container, instruct the user to do so and rerun from
step 1.

## References

- `references/route-lifecycle.md` — full 7-stage route lifecycle from
  advertisement through return path
- `references/policy-routing.md` — table 52, ip rule, VRF analogy,
  and why `ip route` misses Tailscale routes
- `references/common-failures.md` — symptom-based lookup table with
  root causes and fixes
