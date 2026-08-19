---
name: nix-install
description: >
  Install the Nix package manager across platforms with a choice of installer
  (Determinate Systems or upstream). Detects OS, distro, and environment
  (including WSL2), verifies any existing installation, performs a
  platform-appropriate install, enables flakes, and verifies the result.
  Use when setting up Nix on a new machine, onboarding to a Nix-based
  project, or troubleshooting a broken Nix installation.
compatibility: >
  Requires sudo/admin access for multi-user installs. Works on Linux
  (Ubuntu, Debian, Fedora, RHEL, Arch, Alpine, openSUSE), macOS (Intel and
  Apple Silicon), and WSL2. Native Windows is not supported by Nix —
  Windows users must install inside WSL2.
---
<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Nix Install

Install the Nix package manager and prepare it for development use.
Handles platform detection, installer selection, installation,
post-install verification, and flake enablement.

## What this skill does

1. Detects the platform (OS, distro, WSL2, container).
2. Checks for an existing Nix installation.
3. Selects an installer (Determinate Systems or upstream nixos.org).
4. Installs Nix using the appropriate command for the platform.
5. Verifies the installation, daemon, and flake support.

## Platform detection

Detect the environment before selecting an install method. Unlike
Tailscale, Nix runs *inside* WSL2 cleanly — no host bridging needed.

```text
1. Check WSL2 (informational — install path is unchanged)
   ├─ grep -qi microsoft /proc/version 2>/dev/null
   └─ AND [ ! -f /.dockerenv ]

2. Check OS
   ├─ uname -s → Linux  → continue
   ├─ uname -s → Darwin → macOS (DetSys handles APFS automatically)
   └─ Windows native    → STOP. Nix requires WSL2 on Windows.

3. Confirm prerequisites
   ├─ curl, sudo, xz are required by both installers
   ├─ bash is required (Alpine: install bash before running installer)
   └─ Fedora/RHEL: SELinux may need adjustment (see error handling)
```

## Existing install check

Before installing, check whether Nix is already present:

```bash
nix --version 2>/dev/null
```

If installed: report the version, check daemon status (multi-user only,
`systemctl status nix-daemon`), check flakes
(`nix flake --help >/dev/null`), and run a functional test
(`nix-shell -p hello --run hello`). Stop here unless the user requests
reinstall or repair. If not installed, proceed to installer selection.

## Installer selection

Two installers are supported. Default to **Determinate Systems** unless
the user explicitly asks for the upstream installer or has a compliance
constraint.

### Determinate Systems installer (default)

Enables flakes by default, supports clean uninstall via
`/nix/receipt.json`, and produces actionable error messages.

```bash
curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix | sh -s -- install
```

For unattended runs, add `--no-confirm` after `install`.

### Upstream nixos.org installer

Use when an organization requires the canonical Nix installer (audit,
compliance) or when the Determinate installer is unavailable.

```bash
# Multi-user (recommended for shared machines)
sh <(curl -L https://nixos.org/nix/install) --daemon

# Single-user (only when sudo is unavailable)
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

For installer trade-offs, see `references/installer-comparison.md`.

## Installation

Run the chosen installer command (above) for the platform. The same
command works across Linux distros, macOS, and WSL2 — the installers
handle platform specifics internally (APFS on macOS, daemon setup on
Linux). After install, **start a new shell** so the Nix profile is
sourced. For per-distro prerequisites and uninstall commands, see
`references/platform-install-commands.md`.

## Post-install verification

After installation, verify four things in order. Stop and remediate if
any check fails.

### 1. Binary is available

```bash
nix --version
```

If not found, the shell has not sourced the Nix profile. Open a new
terminal or run:

```bash
. /etc/profile.d/nix.sh    # multi-user
# or
. ~/.nix-profile/etc/profile.d/nix.sh    # single-user
```

### 2. Daemon is running (multi-user only)

```bash
# Linux
systemctl status nix-daemon

# macOS
sudo launchctl print system/org.nixos.nix-daemon
```

Single-user installs do not have a daemon — skip this check.

### 3. Flakes are enabled

```bash
nix flake --help >/dev/null && echo "flakes enabled" || echo "flakes NOT enabled"
```

The Determinate installer enables flakes by default. The upstream
installer does **not** — see "Enabling flakes" below.

### 4. Functional test

```bash
nix-shell -p hello --run hello
# Expected output: "Hello, world!"
```

This verifies the substituter (cache.nixos.org) is reachable, signature
verification works, and the store is writable.

## Enabling flakes

If flakes are not enabled (upstream installer default):

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" \
  >> ~/.config/nix/nix.conf
```

For system-wide flake enablement on multi-user installs, use
`/etc/nix/nix.conf` — see `references/post-install-checklist.md`.

## Error handling

Do **not** silently skip a failed installation. Report the error with a
specific remediation step.

- **Permission denied** — multi-user install requires sudo. Re-run with
  privileges or use `--no-daemon` for single-user.
- **xz: command not found** (Alpine, minimal containers) — install
  `xz-utils` (Debian/Ubuntu) or `xz` (Alpine/Arch) before retrying.
- **SELinux denials on Fedora/RHEL** — the Determinate installer handles
  this; the upstream installer may need
  `setenforce 0` temporarily, then re-enable.
- **macOS APFS volume creation failed** — use the Determinate installer,
  which handles this. With the upstream installer on macOS, see
  `references/platform-install-commands.md` for manual volume setup.
- **`nix --version` not found after install** — shell not yet sourcing
  the Nix profile. Open a new terminal or source
  `/etc/profile.d/nix.sh`.
- **Substituter unreachable** (`unable to download cache.nixos.org`) —
  check network, proxy, and corporate TLS interception. Test with
  `curl -fI https://cache.nixos.org`.
- **Existing /nix directory** — a previous install left state. Use
  `/nix/nix-installer uninstall` (Determinate) or follow
  `references/installer-comparison.md` for upstream uninstall.

## References

- `references/installer-comparison.md` — Determinate Systems vs upstream
  installer trade-offs and migration notes.
- `references/platform-install-commands.md` — exhaustive per-platform
  install and uninstall commands for both installers.
- `references/post-install-checklist.md` — flakes config, channels,
  substituters, trusted-users, and first-run troubleshooting.
