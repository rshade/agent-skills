<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
# Flake Anatomy

Annotated walkthrough of a devShell `flake.nix` for users new to Nix.
Reference this when explaining the generated flake to the user.

## Minimal example

```nix
{
  # 1. Description — human-readable, shown by `nix flake metadata`
  description = "my-project development environment";

  # 2. Inputs — external dependencies, pinned by flake.lock
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  # 3. Outputs — what this flake provides
  outputs = { nixpkgs, ... }:
    let
      # 4. forAllSystems — generate outputs for every platform
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux" "aarch64-linux"
        "x86_64-darwin" "aarch64-darwin"
      ];
    in
    {
      # 5. devShells — the development environment
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
          # 6. default — activated by `nix develop` or `use flake`
          default = pkgs.mkShell {
            # 7. packages — tools available in the shell
            packages = with pkgs; [
              go
              gopls
            ];

            # 8. shellHook — runs when the shell activates
            shellHook = ''
              echo "Welcome to the dev shell"
            '';
          };
        }
      );
    };
}
```

## Section-by-section

### 1. `description`

A human-readable string. Shown by `nix flake metadata` and
`nix flake show`. Use the project name and "development environment"
as a convention.

### 2. `inputs`

External flakes this flake depends on. The most common input is
`nixpkgs` — the package repository. The URL format is:

```text
github:NixOS/nixpkgs/nixos-unstable   # Rolling, latest packages
github:NixOS/nixpkgs/nixos-24.05       # Stable release branch
github:NixOS/nixpkgs/<commit-sha>      # Exact commit pin
```

`nixos-unstable` is the standard choice for development. Despite the
name, it is well-tested. The `flake.lock` file pins the exact commit
so builds are reproducible regardless of the branch name.

Additional inputs can provide overlays, tools, or language-specific
helpers:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  rust-overlay.url = "github:oxalica/rust-overlay";
  rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
};
```

The `follows` directive ensures `rust-overlay` uses the same nixpkgs
as the flake, avoiding version conflicts.

### 3. `outputs`

A function that takes the resolved inputs and returns an attribute set.
For devShells, the relevant output is `devShells.<system>.default`.

### 4. `forAllSystems`

A helper that generates outputs for multiple platforms. Without it,
you would write:

```nix
devShells.x86_64-linux.default = ...;
devShells.aarch64-darwin.default = ...;
```

`forAllSystems` avoids this repetition. An alternative is
`flake-utils.lib.eachDefaultSystem`, but it adds an extra input.
Using `nixpkgs.lib.genAttrs` keeps dependencies minimal.

### 5. `devShells`

The attribute that `nix develop` and `direnv use flake` look for.
Each entry is a `mkShell` derivation.

### 6. `default`

The shell activated when running `nix develop` without specifying a
name. Named shells (e.g., `devShells.<system>.ci`) can coexist for
specialized environments.

### 7. `packages`

A list of packages from nixpkgs to make available in the shell.
`with pkgs;` lets you reference packages without the `pkgs.` prefix.

To find package names:

```bash
nix search nixpkgs <name>
```

### 8. `shellHook`

A bash script that runs when the shell activates. Common uses:

- Set environment variables (`export GOPATH=...`)
- Activate virtualenvs (`source .venv/bin/activate`)
- Print status messages

Keep shellHooks minimal — heavy setup should be in Makefiles or
scripts, not in the flake.

## flake.lock

Generated automatically by `nix flake update` (or the first
`nix develop`). This file pins the exact nixpkgs commit used.
**Always commit flake.lock** — it is the mechanism that makes builds
reproducible across machines.

To update:

```bash
nix flake update
```

To update a specific input:

```bash
nix flake lock --update-input nixpkgs
```

## Useful commands

| Command | Purpose |
| --- | --- |
| `nix develop` | Enter the devShell interactively |
| `nix flake check` | Validate the flake (no build) |
| `nix flake show` | List all outputs |
| `nix flake metadata` | Show inputs, lock status, description |
| `nix flake update` | Update all inputs to latest |
| `nix search nixpkgs <pkg>` | Find a package name |
