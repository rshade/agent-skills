<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
# Post-Install Checklist

Steps to verify a Nix installation, enable flakes, configure caches,
and troubleshoot first-run issues.

## Verification

### 1. Binary in PATH

```bash
nix --version
```

Expected: `nix (Nix) 2.X.X` or similar. If not found, the shell has not
sourced the Nix profile. Open a new terminal or source manually:

```bash
# Multi-user
. /etc/profile.d/nix.sh

# Single-user
. ~/.nix-profile/etc/profile.d/nix.sh
```

### 2. Daemon running (multi-user only)

```bash
# Linux
systemctl status nix-daemon
systemctl is-active nix-daemon       # Returns "active"

# macOS
sudo launchctl print system/org.nixos.nix-daemon
```

Single-user installs have no daemon — skip this check.

### 3. Functional test

```bash
nix-shell -p hello --run hello
# Expected: "Hello, world!"
```

This exercises substituter access (cache.nixos.org), signature
verification, store writes, and shell environment setup.

### 4. Flake support

```bash
nix flake --help >/dev/null 2>&1 && echo "flakes ok"
```

If "flakes ok" prints, you're done. Otherwise, see "Enabling flakes".

## Enabling flakes

Flakes are enabled by default with the Determinate Systems installer.
The upstream installer requires manual config.

### Per-user (most common)

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" \
  >> ~/.config/nix/nix.conf
```

Verify in a new shell:

```bash
nix flake --help >/dev/null && echo "ok"
```

### System-wide (multi-user installs)

```bash
echo "experimental-features = nix-command flakes" \
  | sudo tee -a /etc/nix/nix.conf
sudo systemctl restart nix-daemon
```

System-wide config affects all users on the machine. Use this for shared
build servers and CI runners.

## Channel configuration

The upstream installer subscribes you to the `nixpkgs-unstable` channel
by default. The Determinate installer does not subscribe to a channel —
it relies on flakes for package sourcing.

### Check current channel

```bash
nix-channel --list
```

### Update channel

```bash
nix-channel --update
```

### Switch to a stable channel

```bash
nix-channel --add https://nixos.org/channels/nixos-24.05 nixpkgs
nix-channel --update
```

For flakes-first workflows, channels are not needed — pin nixpkgs in
your `flake.nix` instead.

## Substituter (cache) configuration

The default substituter is `https://cache.nixos.org`. To add additional
caches (e.g., a Cachix cache for your project):

```bash
# Per-user
mkdir -p ~/.config/nix
cat >> ~/.config/nix/nix.conf <<'EOF'
substituters = https://cache.nixos.org https://my-cache.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
EOF
```

For system-wide caches in a multi-user install, use `/etc/nix/nix.conf`
and add the user to `trusted-users`:

```bash
echo "trusted-users = root @wheel <username>" \
  | sudo tee -a /etc/nix/nix.conf
sudo systemctl restart nix-daemon
```

## First-run troubleshooting

### "error: cannot connect to socket"

The daemon is not running. Start it:

```bash
sudo systemctl start nix-daemon
```

### "unable to download cache.nixos.org"

Network or proxy issue. Test:

```bash
curl -fI https://cache.nixos.org
```

If a corporate proxy is intercepting TLS, configure Nix to trust the
corporate CA:

```bash
echo "ssl-cert-file = /etc/ssl/certs/ca-certificates.crt" \
  >> ~/.config/nix/nix.conf
```

### "permission denied" on `/nix/store`

Single-user install on a multi-user system, or store ownership corrupt.
Verify:

```bash
ls -ld /nix/store
```

Should be owned by `root:nixbld` (multi-user) or your user (single-user).

### Slow first download

The Nix substituter is global; first downloads can be slow if your
region is far from the CDN. Subsequent downloads are cached locally in
`/nix/store` and are essentially free.

## Next steps

After verification:

- For per-project devShells: install `direnv` and `nix-direnv`, then add
  `use flake` to a project's `.envrc`.
- For user-level package management: consider Home Manager
  ([nix-community/home-manager](https://github.com/nix-community/home-manager)).
- For declarative system config (NixOS): see the NixOS manual.
