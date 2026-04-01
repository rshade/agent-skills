# Compose Configuration Matrix

Minimum Docker Compose configuration for kernel-mode Tailscale with
working MagicDNS. Every setting listed here is required — removing any
one introduces a specific failure mode.

## Minimum working configuration

```yaml
services:
  node:
    image: tailscale/tailscale:latest
    hostname: my-node
    dns:
      - 100.100.100.100
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_HOSTNAME=my-node
      - TS_EXTRA_ARGS=--advertise-tags=tag:lab
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_ACCEPT_DNS=true
      - TS_USERSPACE=false
    volumes:
      - node-state:/var/lib/tailscale
    devices:
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - NET_ADMIN
      - SYS_MODULE

volumes:
  node-state:
```

## Setting breakdown

| Setting | Purpose | Without it |
| --- | --- | --- |
| `TS_USERSPACE=false` | Kernel-mode TUN | Userspace fallback, no routes |
| `TS_ACCEPT_DNS=true` | Accept coordination DNS | MagicDNS disabled |
| `dns: [100.100.100.100]` | Forward DNS to Tailscale | Forwards to host resolver |
| `devices:` for TUN | Device node passthrough | `volumes:` copies file only |
| `NET_ADMIN` | Create TUN, modify routes | Cannot create `tailscale0` |
| `SYS_MODULE` | Load kernel modules | May fail on some hosts |
| `TS_STATE_DIR` | Persist state on restart | Re-authenticates each time |
| `TS_AUTHKEY` | Automated auth | Manual web UI approval needed |

## devices vs volumes for /dev/net/tun

This is the most common misconfiguration. The difference:

**`volumes:` (wrong)**

```yaml
volumes:
  - /dev/net/tun:/dev/net/tun
```

Bind-mounts the file. The container sees a regular file, not a character
device. `TS_USERSPACE=false` silently falls back to userspace because
the TUN device node is not functional.

**`devices:` (correct)**

```yaml
devices:
  - /dev/net/tun:/dev/net/tun
```

Passes the device node with correct major/minor numbers (`10, 200`).
The container can create a real TUN interface.

Verify inside the container:

```bash
ls -la /dev/net/tun
# Expected: crw-rw-rw- 1 root root 10, 200 ...
```

## Multi-node compose example

When running multiple Tailscale containers (e.g., a lab with several
nodes), each service needs its own auth key and state volume:

```yaml
services:
  node-a:
    image: tailscale/tailscale:latest
    hostname: lab-node-a
    dns: [100.100.100.100]
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY_A}
      - TS_HOSTNAME=lab-node-a
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_ACCEPT_DNS=true
      - TS_USERSPACE=false
    volumes:
      - node-a-state:/var/lib/tailscale
    devices:
      - /dev/net/tun:/dev/net/tun
    cap_add: [NET_ADMIN, SYS_MODULE]

  node-b:
    image: tailscale/tailscale:latest
    hostname: lab-node-b
    dns: [100.100.100.100]
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY_B}
      - TS_HOSTNAME=lab-node-b
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_ACCEPT_DNS=true
      - TS_USERSPACE=false
    volumes:
      - node-b-state:/var/lib/tailscale
    devices:
      - /dev/net/tun:/dev/net/tun
    cap_add: [NET_ADMIN, SYS_MODULE]

volumes:
  node-a-state:
  node-b-state:
```

Each node authenticates independently. Use separate auth keys or a
reusable key with appropriate tags.
