<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
# Installer Comparison: Determinate Systems vs Upstream

Two installers exist for Nix on Linux, macOS, and WSL2. They produce
the same `/nix` store layout and run the same Nix binaries, but differ
in install behavior, defaults, and uninstall support.

## At a glance

| Aspect | Determinate Systems | Upstream nixos.org |
| --- | --- | --- |
| Source | `install.determinate.systems/nix` | `nixos.org/nix/install` |
| Maintainer | Determinate Systems (commercial) | NixOS Foundation (community) |
| Flakes default | Enabled | Disabled |
| Uninstall | `/nix/nix-installer uninstall` | Manual file removal |
| macOS APFS volume | Automatic | Automatic since 2.4, fragile |
| Receipt file | `/nix/receipt.json` | None |
| Error messages | Detailed remediation hints | Generic Nix errors |
| Telemetry | Opt-in | None |
| License | LGPL-2.1 | LGPL-2.1 |

## When to choose Determinate Systems

- New installs on developer machines (most common case).
- macOS, especially Apple Silicon — APFS volume management is more
  reliable.
- Systems where flakes will be used (saves a manual config step).
- When clean uninstall matters (CI runners, ephemeral test environments,
  shared workstations).
- When error messages need to be actionable (less Nix experience on the
  team).

## When to choose upstream

- Compliance or audit requirements that mandate the canonical NixOS
  Foundation installer.
- Air-gapped or restricted environments where the Determinate domain is
  blocked but `nixos.org` is allowed.
- When following published documentation that assumes the upstream
  installer (e.g., older NixOS guides, certain academic HPC setups).
- When telemetry must be provably absent (Determinate's telemetry is
  opt-in, but some policies forbid even the option).

## Migration between installers

The `/nix` store is interchangeable. To switch installers without losing
your store:

1. Back up `/nix/store` (it can be very large — consider `nix-collect-garbage -d` first).
2. Note your installed packages: `nix-env -q` and any flake-based profiles.
3. Uninstall the current installer (see Uninstall sections below).
4. Install the other installer.
5. Reinstall packages.

In practice, switching is rarely worth it unless you're moving from
upstream to Determinate to gain clean uninstall.

## Uninstall — Determinate Systems

```bash
/nix/nix-installer uninstall
```

This reads `/nix/receipt.json` to remove all files the installer created
(including `/etc/profile.d/nix.sh`, `~/.nix-*` symlinks, daemon units,
and the `/nix` directory itself).

## Uninstall — upstream

The upstream installer does not bundle an uninstaller. Manual removal:

```bash
# Stop the daemon (multi-user)
sudo systemctl stop nix-daemon.socket nix-daemon.service
sudo systemctl disable nix-daemon.socket nix-daemon.service
sudo rm /etc/systemd/system/nix-daemon.{service,socket}

# Remove store
sudo rm -rf /nix /etc/nix /etc/profile.d/nix.sh

# Remove user state
rm -rf ~/.nix-profile ~/.nix-defexpr ~/.nix-channels ~/.config/nix

# Remove build users (multi-user only)
for i in $(seq 1 32); do sudo userdel "nixbld$i" 2>/dev/null; done
sudo groupdel nixbld 2>/dev/null
```

On macOS, the upstream uninstall is more involved (APFS volume removal,
synthetic.conf edits) — consult the official Nix uninstall guide.

## Recommendation

For new installations on developer machines, use **Determinate Systems**
unless a compliance constraint requires upstream. For server-side or
audited environments, use **upstream** with the multi-user installer
(`--daemon`).
