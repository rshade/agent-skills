# Common Subnet Router Failures

Symptom-based lookup table. Find the symptom, identify the root cause,
and jump to the corresponding diagnostic step in SKILL.md.

## Quick reference

| Symptom | Root cause | Step |
|---|---|---|
| Client pings router but not subnet IPs | `--accept-routes` not set on client | 3 |
| `ip route` shows no subnet route | Routes are in table 52, not main table | 4 |
| Route approved but peers don't see it | Propagation delay, or client needs `--accept-routes` | 2-3 |
| `TS_ROUTES` didn't take effect | Auth failed on first boot, route advertisement skipped | 1 |
| IP forwarding is 1 but traffic drops | Return path issue — target can't route back | 7 |
| `tailscale down` killed the container | Containerboot exits on `tailscale down` — use `tailscale set` | 3 |
| Route in AllowedIPs but wget hangs | IP forwarding off, or firewall on subnet router | 5-6 |
| `requested tags are invalid` on startup | Auth key missing tag, or tag not in tagOwners ACL | Pre-req |
| Route pending approval indefinitely | No autoApprovers, admin must approve manually | 2 |

## Detailed failure scenarios

### "I approved the route but users can't reach the subnet"

**Root cause:** `--accept-routes` is false on client devices (Step 3).

Route approval is a server-side action. Each client must independently
opt in with `tailscale set --accept-routes=true`. This defaults to
false and is the most commonly missed step.

### "I can see the route in admin console but `ip route` is empty"

**Root cause:** Tailscale uses policy routing table 52 (Step 4).

Run `ip route show table 52` instead. The main table (`ip route`)
does not contain Tailscale subnet routes by design — this prevents
conflicts with existing network configuration.

### "It works from the router but not from clients"

**Root cause:** Combination of Steps 3-4.

If the subnet router itself can reach the target, the issue is on the
client side: either `--accept-routes` is off, or table 52 doesn't have
the route installed. Check both.

### "Traffic flows one way but responses don't come back"

**Root cause:** Missing return path (Step 7).

The target device sends responses to its default gateway, which doesn't
know about Tailscale IPs. The subnet router needs to masquerade
(SNAT) so the target sees the router's LAN IP as the source.

Tailscale 1.64+ enables `--snat-subnet-routes` by default. If running
an older version, either upgrade or add an iptables masquerade rule.

### "Docker containers fail to advertise routes"

**Root cause:** Auth failure on first boot (Step 1).

When containerboot starts, it authenticates and then advertises routes.
If authentication fails (expired key, invalid tags), the route
advertisement step is skipped. Subsequent container restarts may
re-auth but not re-advertise.

**Fix:** Verify auth key validity, check for `requested tags are
invalid` in logs, then use `tailscale set --advertise-routes=<CIDR>`
at runtime.

### "Route pending approval indefinitely"

**Root cause:** No autoApprovers configured (Step 2).

Without `autoApprovers` in the ACL, every subnet route requires manual
admin approval. For automated deployments, add:

```json
"autoApprovers": {
  "routes": {
    "10.100.0.0/24": ["tag:subnet-router"]
  }
}
```

### "`requested tags are invalid` on startup"

**Root cause:** Pre-requisite issue before Step 1.

The auth key specifies tags that either don't exist in the ACL
`tagOwners` section, or the key's owner isn't listed as a tag owner.

**Fix:** Verify the tag exists in ACL `tagOwners` and that the key
creator is authorized for that tag. Generate a new auth key if needed.
