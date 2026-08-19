<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
# Platform Install Commands

Exhaustive install and uninstall commands for both Nix installers across
all supported platforms. The agent should use platform detection results
from SKILL.md to select the correct section.

## Determinate Systems — All Platforms (Linux, macOS, WSL2)

The Determinate installer is platform-agnostic. The same command works
on every supported OS.

### Interactive install

```bash
curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix | sh -s -- install
```

### Unattended install

```bash
curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix \
  | sh -s -- install --no-confirm
```

### Useful flags

| Flag | Effect |
| --- | --- |
| `--no-confirm` | Skip the interactive prompt (CI / automation) |
| `--determinate` | Install Determinate Nix distribution (paid features) |
| `--init systemd` | Force systemd init (Linux) |
| `--init none` | Skip init system integration (containers) |
| `--no-modify-profile` | Do not edit shell profile files |
| `--explain` | Print what the installer will do without running |

### Uninstall

```bash
/nix/nix-installer uninstall
```

## Upstream — Linux (multi-user, recommended)

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

The multi-user install:

- Creates `nixbld1`..`nixbld32` build users.
- Creates the `nixbld` group.
- Installs systemd unit `nix-daemon.service` and socket
  `nix-daemon.socket`.
- Writes `/etc/profile.d/nix.sh` for shell profile sourcing.

After install, start a new shell or run:

```bash
. /etc/profile.d/nix.sh
```

## Upstream — Linux (single-user)

Use only when sudo is unavailable (HPC nodes, restricted environments):

```bash
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

The single-user install puts everything under `~/.nix-profile`. There is
no daemon and no build users.

## Upstream — macOS

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

The macOS install is sensitive to System Integrity Protection (SIP) and
the read-only system volume. The installer creates a separate APFS
volume mounted at `/nix`. **If the APFS volume creation fails, prefer
the Determinate installer** — manual recovery on macOS is fragile.

For Apple Silicon (M1/M2/M3):

```bash
# Ensure Rosetta is not interfering — install in native arm64 shell
arch
# Should print: arm64
```

## WSL2

WSL2 supports both installers without modification. Use the same
commands as Linux. Multi-user install with the upstream installer
requires systemd in WSL2 (Ubuntu 22.04+ supports this; enable in
`/etc/wsl.conf`):

```ini
[boot]
systemd=true
```

After editing `/etc/wsl.conf`, restart WSL from PowerShell:

```powershell
wsl --shutdown
```

If systemd is not available, use the single-user upstream install or
the Determinate installer with `--init none`.

## Per-distro prerequisites

### Debian / Ubuntu

```bash
sudo apt-get update
sudo apt-get install -y curl xz-utils sudo
```

### Fedora / RHEL / CentOS

```bash
sudo dnf install -y curl xz sudo
```

SELinux note: the upstream installer may trip SELinux denials. The
Determinate installer handles SELinux contexts automatically. If using
the upstream installer:

```bash
# Temporarily set permissive (re-enable after install)
sudo setenforce 0
# Install
sh <(curl -L https://nixos.org/nix/install) --daemon
# Re-enable
sudo setenforce 1
```

### Arch / Manjaro

```bash
sudo pacman -S --needed curl xz sudo
```

### Alpine

```bash
sudo apk add bash curl xz sudo
```

Alpine uses BusyBox by default; the Nix installer requires real bash.
Alpine also uses OpenRC, not systemd — multi-user installs may need
manual daemon setup.

### openSUSE / SUSE

```bash
sudo zypper install -y curl xz sudo
```

## Containers (Docker)

Most container images do not have systemd, so multi-user installs fail.
Use the single-user upstream installer or the Determinate installer with
`--init none`:

```bash
# In a Dockerfile
RUN curl --proto '=https' --tlsv1.2 -sSf -L \
      https://install.determinate.systems/nix \
      | sh -s -- install --no-confirm --init none
```

For reproducible builds, prefer the official `nixos/nix` image rather
than installing into a stock distro image.

## Uninstall — upstream

See `references/installer-comparison.md` for the manual upstream
uninstall steps. The upstream installer does not bundle an uninstaller.
