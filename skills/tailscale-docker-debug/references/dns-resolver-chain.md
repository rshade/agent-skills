# DNS Resolver Chain

How DNS queries travel from an application inside a Docker container
through to Tailscale's MagicDNS resolver, and where they can go wrong.

## Full resolution path

```text
Application DNS query (e.g., ping lab-node-b.tail9a660c.ts.net)
  |
  v
/etc/resolv.conf nameserver (127.0.0.11 — Docker embedded DNS)
  |
  v
Docker embedded DNS: is this a container name on the compose network?
  |                                          |
  YES                                        NO
  |                                          |
  v                                          v
Resolve to Docker bridge IP           Forward to ExtServers
(172.18.x.x) — WRONG for Tailscale         |
                                            |
                          +-----------------+-----------------+
                          |                                   |
              dns: set in compose                 dns: NOT set in compose
              ExtServers = 100.100.100.100        ExtServers = host(127.0.0.53)
                          |                                   |
                          v                                   v
              Routes to container's              Host systemd-resolved
              tailscale0?                        doesn't know Tailscale names
                |              |                              |
                YES            NO                             v
                |              |                         NXDOMAIN
                v              v
           MagicDNS       Host's Tailscale
           resolves        answers instead
                |              |
                v              |
              Done       Same tailnet?
                          |          |
                          YES        NO
                          |          |
                          v          v
                       Resolves   NXDOMAIN
```

## Key decision points

### Docker embedded DNS (127.0.0.11)

Docker always sets `nameserver 127.0.0.11` in container resolv.conf.
This is Docker's built-in DNS server, not a system resolver. It handles
two things:

1. **Container name resolution** — resolves names of other containers on
   the same compose network to their bridge IPs.
2. **External forwarding** — forwards everything else to the configured
   external servers (ExtServers).

The external servers come from the `dns:` directive in compose, or from
the host's resolv.conf if `dns:` is not set.

### ExtServers configuration

Without `dns:` in compose, Docker inherits the host's DNS. On most
Linux systems this is `127.0.0.53` (systemd-resolved), which knows
nothing about Tailscale MagicDNS names.

With `dns: [100.100.100.100]`, Docker forwards non-container queries to
Tailscale's MagicDNS resolver. But the query still needs to reach the
container's own Tailscale instance — if 100.100.100.100 routes through
the Docker gateway to the host, the host's Tailscale answers instead.

### The 100.100.100.100 routing problem

100.100.100.100 is Tailscale's magic DNS IP. In kernel mode with a
working TUN interface, the container's route table sends this to
`tailscale0`. In userspace mode (or without a TUN interface), the
container has no route for 100.100.100.100 and it falls through to the
default route — out `eth0`, through the Docker bridge, to the host.

If the host also runs Tailscale, the host's Tailscale instance answers
the DNS query. This works if host and container are on the same tailnet,
but returns NXDOMAIN if they are on different tailnets.

## Short name vs FQDN conflict

Docker's embedded DNS resolves short hostnames (like `node-b`) to
Docker bridge IPs before Tailscale ever sees the query. This happens
because Docker treats any name matching a container on the compose
network as an internal resolution.

**Example:**

- Compose defines services `node-a` and `node-b`
- `ping node-b` from `node-a` resolves to `172.18.0.3` (Docker bridge)
- `ping node-b.tail9a660c.ts.net` goes to ExtServers and reaches MagicDNS

Only FQDNs (`<hostname>.<tailnet>.ts.net`) bypass Docker's internal
DNS. Short names always resolve to bridge IPs when a matching container
exists on the network.

**Workaround:** Always use FQDNs for Tailscale communication between
containers on the same compose network, or use Tailscale IPs directly.

## Search domain inheritance

Docker copies the host's resolv.conf `search` domain into the
container's resolv.conf. If the host is on `tucuxi-lungfish.ts.net` and
the container is on `tail9a660c.ts.net`, short name lookups append the
wrong tailnet suffix.

**Example:**

- Host resolv.conf: `search tucuxi-lungfish.ts.net`
- Container resolv.conf inherits: `search tucuxi-lungfish.ts.net`
- `ping node-b` tries `node-b.tucuxi-lungfish.ts.net` — wrong tailnet

**Fix:** Set `dns_search: [<correct-tailnet>.ts.net]` in compose to
override the inherited search domain.
