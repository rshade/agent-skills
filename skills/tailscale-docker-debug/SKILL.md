---
name: tailscale-docker-debug
description: >
  Diagnose Tailscale connectivity and DNS failures inside Docker containers.
  Detects userspace vs kernel mode, DNS resolver conflicts, TUN interface
  issues, and multi-tailnet mismatches. Use when Tailscale peers connect
  by IP but MagicDNS names fail, or when containers fall back to userspace
  networking unexpectedly. Also use when a customer deploys Tailscale in
  Docker or Podman and reports DNS not working, or when migrating from
  docker run to docker compose breaks TUN functionality.
compatibility: >
  Requires Docker or Podman CLI. Container must run the
  tailscale/tailscale image or have Tailscale installed.
---

# Tailscale Docker Debug

Diagnose and fix Tailscale connectivity and DNS issues inside Docker
containers. Runs six sequential checks covering the full debugging
chain from container runtime mode through MagicDNS resolution.

## What this skill does

1. Detects whether the container runs in kernel or userspace mode.
2. Verifies the TUN interface exists with a Tailscale IP.
3. Checks the DNS resolver chain for misrouted queries.
4. Confirms 100.100.100.100 routes through the container's Tailscale.
5. Detects multi-tailnet conflicts between host and container.
6. Validates MagicDNS end-to-end with a name resolution test.

## Common triggers

- Customer reports "DNS doesn't work" inside Docker/Podman containers
- Host on one tailnet, containers on a different tailnet
- Compose file has `NET_ADMIN` and `/dev/net/tun` but Tailscale still
  runs in userspace mode
- Migration from `docker run` to `docker compose` breaks TUN

## Diagnostic workflow

Run each step in order. Stop at the first failure and apply the fix
before continuing — later steps depend on earlier ones.

### Step 1 — Detect container runtime mode

```bash
docker logs <container> 2>&1 | grep -iE "tun|userspace|netstack"
```

**Pass:** Logs show `tun "tailscale0"` — kernel mode. Proceed to step 2.

**Fail:** Logs show `--tun=userspace-networking`. The official
`tailscale/tailscale` image defaults to userspace via containerboot
regardless of capabilities.

**Fix:** Set `TS_USERSPACE=false` in environment. Use `devices:` (not
`volumes:`) for `/dev/net/tun`. Add `cap_add: [NET_ADMIN, SYS_MODULE]`.
See `references/compose-configuration-matrix.md` for the full config.

### Step 2 — Verify TUN interface exists

```bash
docker exec <container> ip addr show tailscale0
```

**Pass:** Interface shows a `100.x.y.z/32` address. Proceed to step 3.

**Fail:** No `tailscale0` interface even with `TS_USERSPACE=false`.

**Fix:** Change `/dev/net/tun` from `volumes:` to `devices:` in compose.
Verify the device exists in the container with major/minor `10, 200`.
Confirm `cap_add: [NET_ADMIN, SYS_MODULE]`.

### Step 3 — Check DNS resolver chain

```bash
docker exec <container> cat /etc/resolv.conf
```

Examine three things:

- `nameserver` — expect `127.0.0.11` (Docker embedded DNS)
- External servers — should forward to `100.100.100.100`
- `search` — should match the container's tailnet, not the host's

**Fail indicators:**

- `ExtServers: [host(127.0.0.53)]` — Docker forwards to host
  systemd-resolved instead of Tailscale
- Search domain belongs to a different tailnet

**Fix:** Add `dns: [100.100.100.100]` to each service in compose.
See `references/dns-resolver-chain.md` for the full resolution path.

### Step 4 — Verify 100.100.100.100 routing

```bash
docker exec <container> ip route get 100.100.100.100
```

**Pass:** Routes via `tailscale0` or a local interface.

**Fail:** Routes via `eth0` or Docker gateway (e.g., `via 172.18.0.1`)
— DNS queries escape to the host.

```bash
docker exec <container> ss -ulnp | grep 100.100
```

**Fix:** This is a symptom of step 1 (userspace mode) or step 2
(missing TUN). Fix those first.

### Step 5 — Detect multi-tailnet conflict

```bash
docker exec <container> tailscale status | head -1
docker exec <container> grep search /etc/resolv.conf
```

Compare the tailnet shown in `tailscale status` against the search
domain in resolv.conf.

**Fail:** Search domain (inherited from host) doesn't match the
container's tailnet. Example: host on `tucuxi-lungfish.ts.net`,
container on `tail9a660c.ts.net`.

**Fix:** Add `dns_search: [<correct-tailnet>.ts.net]` in compose, or
use FQDNs exclusively. Root cause is Docker inheriting the host's
resolv.conf search domain.

### Step 6 — Verify MagicDNS end-to-end

```bash
docker exec <container> tailscale dns status | head -3
```

**Pass:** Shows `Tailscale DNS: enabled`.

**Fail:** Shows `Tailscale DNS: disabled`.

**Fix:** Set `TS_ACCEPT_DNS=true` in environment.

**Final validation:**

```bash
docker exec <container> nslookup <peer>.<tailnet>.ts.net 100.100.100.100
docker exec <container> ping -c 1 <peer>.<tailnet>.ts.net
```

If both succeed, MagicDNS is working correctly inside the container.

## Error handling

Do not silently skip a failed check. Report the specific failure with
the fix before continuing. If a fix requires restarting the container,
instruct the user to recreate it (`docker compose up -d`) and rerun the
workflow from step 1.

The log message `getting OS base config is not supported` is non-fatal
— Tailscale cannot read the container's DNS config directly. Fix DNS
via the compose file instead.

## References

- `references/compose-configuration-matrix.md` — minimum compose config
  for kernel-mode Tailscale with MagicDNS, setting-by-setting breakdown
- `references/dns-resolver-chain.md` — full DNS resolution path through
  Docker embedded DNS, short name vs FQDN conflict
- `references/common-failures.md` — symptom-based lookup table with
  root causes and fixes
