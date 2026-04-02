# Policy Routing and Table 52

## Why Tailscale uses a separate routing table

Tailscale needs to install routes for subnet CIDRs (e.g.,
`10.100.0.0/24 via tailscale0`) without conflicting with existing
routes in the main routing table. If the host already has a route for
`10.100.0.0/24` via a physical interface, adding a conflicting route
to the main table would break local network access.

Tailscale solves this with **policy routing** — a Linux kernel feature
that supports multiple routing tables evaluated by priority-based
rules.

## Table 52

Tailscale installs subnet routes into routing table 52:

```bash
ip route show table 52
```

Example output:

```text
10.100.0.0/24 dev tailscale0
192.168.1.0/24 dev tailscale0
```

The main routing table (`ip route` with no table argument) will **not**
show these routes. This is the single most common source of confusion
when debugging subnet routers — users run `ip route`, see no subnet
route, and conclude the route isn't installed.

## IP rules

Tailscale adds `ip rule` entries that direct traffic matching certain
criteria to table 52:

```bash
ip rule show
```

Example output:

```text
0:      from all lookup local
5210:   from all fwmark 0x80000/0xff0000 lookup main
5230:   from all fwmark 0x80000/0xff0000 lookup default
5250:   from all fwmark 0x80000/0xff0000 lookup 52
5270:   from all lookup 52
32766:  from all lookup main
32767:  from all lookup default
```

The kernel evaluates rules in priority order (lower number = higher
priority). The `lookup 52` rules direct matching traffic to table 52
for route resolution.

## VRF analogy

For network engineers familiar with Cisco or MPLS terminology, table
52 is analogous to a **VRF (Virtual Routing and Forwarding)** instance.
It provides an isolated forwarding domain that coexists with the
default routing domain without interference.

The difference is that Linux policy routing uses priority-based rule
matching rather than interface-based VRF assignment, so traffic can
fall through to the main table if no match is found in table 52.

## Debugging checklist

1. **Always use `ip route show table 52`** — never rely on `ip route`
   alone
2. **Check `ip rule show`** — verify Tailscale's rules exist and have
   appropriate priority
3. **Check for conflicts** — if the same CIDR appears in both the main
   table and table 52, the rule priority determines which wins
4. **After Tailscale restart** — rules and routes are re-added
   automatically, but verify they appear
5. **In containers** — table 52 operates within the container's network
   namespace; check from inside the container, not the host

## Interaction with Docker networking

When Tailscale runs inside a Docker container with its own network
namespace, table 52 exists inside that namespace. Running
`ip route show table 52` on the host will not show the container's
routes. Use:

```bash
docker exec <container> ip route show table 52
docker exec <container> ip rule show
```
