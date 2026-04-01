# Common Failures

Symptom-based lookup table for Tailscale-in-Docker issues. Find the
symptom that matches, then follow the root cause to the fix.

## Symptom table

| Symptom | Root Cause | Fix |
| --- | --- | --- |
| IP works, MagicDNS fails | DNS escaping to host | Steps 3-6 |
| `tailscale ping` ok, `ping` by name fails | Docker DNS resolves to bridge IP | Use FQDN or `dns: [100.100.100.100]` |
| `--tun=userspace-networking` in logs | Default containerboot behavior | `TS_USERSPACE=false` |
| No `tailscale0` interface | Userspace or TUN not passed | Steps 1-2 |
| `nslookup` wrong tailnet results | Host Tailscale answers DNS | Steps 4-5 |
| `getting OS base config...` in logs | Non-fatal container DNS read | Informational; use `dns:` |
| `Tailscale DNS: disabled` | `--accept-dns` not set | `TS_ACCEPT_DNS=true` |
| All traffic through DERP | Same-host container behavior | Not a bug in lab envs |

## Detailed failure scenarios

### Userspace fallback (most common)

**What happens:** The `tailscale/tailscale` Docker image runs
`containerboot` as its entrypoint. Containerboot defaults to
`--tun=userspace-networking` unless `TS_USERSPACE=false` is explicitly
set. This is true even if the container has `NET_ADMIN` and
`/dev/net/tun` — capabilities alone do not switch the mode.

**Symptoms:**

- Container logs show `--tun=userspace-networking`
- No `tailscale0` interface (`ip addr` shows only `eth0` and `lo`)
- `tailscale ping <peer>` works (userspace networking handles this)
- Regular `ping <peer>` by IP fails (no kernel routes)
- DNS queries to 100.100.100.100 escape to host

**Fix:** Add `TS_USERSPACE=false` to environment variables and ensure
`devices:` (not `volumes:`) for `/dev/net/tun`.

### volumes vs devices for /dev/net/tun

**What happens:** Using `volumes:` to mount `/dev/net/tun` copies the
file but does not pass the character device. The container sees a
regular file where it expects a device node.

**Symptoms:**

- `ls -la /dev/net/tun` shows a regular file, not `c` (character
  device) with major 10, minor 200
- Container may fall back to userspace mode silently
- Works with `docker run --device=/dev/net/tun` but breaks in compose
  with `volumes:`

**Fix:** Change from `volumes:` to `devices:` in compose:

```yaml
# Wrong
volumes:
  - /dev/net/tun:/dev/net/tun

# Correct
devices:
  - /dev/net/tun:/dev/net/tun
```

### Multi-tailnet DNS mismatch

**What happens:** The Docker host runs Tailscale on one tailnet (e.g.,
a corporate tailnet). Containers run Tailscale on a different tailnet
(e.g., a lab tailnet). Docker inherits the host's resolv.conf search
domain, so short name lookups use the wrong tailnet suffix.

**Symptoms:**

- `nslookup <peer>` returns NXDOMAIN or resolves to wrong IP
- `nslookup <peer>.<correct-tailnet>.ts.net 100.100.100.100` works
- `grep search /etc/resolv.conf` shows host's tailnet, not container's
- `tailscale status` shows the container is on a different tailnet than
  the search domain

**Fix:** Add `dns_search: [<correct-tailnet>.ts.net]` to the service in
compose. Alternatively, always use FQDNs.

### Docker DNS intercepts container names

**What happens:** Docker's embedded DNS resolves container names (from
the compose file) to Docker bridge IPs before the query reaches
Tailscale. If a Tailscale hostname matches a compose service name,
Docker answers with the bridge IP instead of the Tailscale IP.

**Symptoms:**

- `ping <service-name>` resolves to `172.18.x.x` (bridge IP)
- `ping <service-name>.<tailnet>.ts.net` resolves to `100.x.y.z`
  (correct Tailscale IP)
- Traffic between containers uses Docker bridge instead of Tailscale
  encrypted tunnel

**Fix:** Use FQDNs for Tailscale communication. If containers need to
communicate exclusively over Tailscale, give them different
`TS_HOSTNAME` values than their compose service names.

### DERP relay for same-host containers

**What happens:** Two containers on the same Docker host, both on the
same tailnet, may route traffic through a DERP relay. This is expected
behavior — direct WireGuard connections between containers on the same
host may use the Docker bridge IP as the endpoint, which Tailscale
sometimes reports as a DERP connection.

**Symptoms:**

- `tailscale ping <peer>` shows `via DERP(xxx)` instead of direct
- Latency is higher than expected for same-host communication
- `tailscale status` shows the peer with a DERP indicator

**Resolution:** This is not a bug. In lab environments, DERP relay
between same-host containers is expected. Performance impact is minimal
for development and testing. If direct connections are required, the
containers need separate network namespaces with routable IPs.
