---
name: nix-devshell-init
description: >
  Scaffold a reproducible Nix devShell for a project. Detects project
  language(s) from sentinel files (go.mod, package.json, pyproject.toml,
  Cargo.toml), generates a flake.nix with appropriate packages and
  tooling, creates an .envrc for direnv integration, and verifies the
  shell builds. Use when onboarding to a project that needs reproducible
  dev dependencies, adding Nix to an existing repo, or setting up a new
  project with pinned tooling.
compatibility: >
  Requires Nix with flakes enabled (see nix-install skill). Works on
  any platform where Nix runs (Linux, macOS, WSL2). Optional: direnv
  and nix-direnv for automatic shell activation.
---
<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Nix DevShell Init

Scaffold a reproducible `flake.nix` and `.envrc` for a project based on
detected languages and tooling needs.

## What this skill does

1. Detects project language(s) from sentinel files in the working
   directory.
2. Selects the appropriate devShell packages for each language.
3. Generates a `flake.nix` with a `devShells.default` output.
4. Creates an `.envrc` with `use flake` for direnv integration.
5. Adds `.direnv/` to `.gitignore` (direnv cache directory).
6. Verifies the generated flake evaluates cleanly.

## Language detection

Scan the project root for these sentinel files. Multiple matches
produce a combined multi-language devShell.

```text
Sentinel file(s)           → Language    → Primary packages
─────────────────────────────────────────────────────────
go.mod                     → Go          → go, gopls, gotools
package.json               → Node.js     → nodejs, npm
pyproject.toml              → Python      → python3, uv
requirements.txt           → Python      → python3, uv
Cargo.toml                 → Rust        → rustc, cargo, rust-analyzer
Makefile (alone)           → Generic     → gnumake
```

If no sentinel files are found, ask the user which language(s) to
support and proceed with that selection.

### Version inference

When possible, infer the language version from project metadata:

- **Go**: parse `go` directive from `go.mod`
  (e.g., `go 1.22` → `go_1_22` if available in nixpkgs)
- **Node**: parse `engines.node` from `package.json`
  (e.g., `>=18` → `nodejs_18`)
- **Python**: parse `requires-python` from `pyproject.toml`
  (e.g., `>=3.11` → `python311`)
- **Rust**: if `rust-toolchain.toml` exists, note the channel but use
  the nixpkgs Rust (pinning Rust nightly requires an overlay — suggest
  `oxalica/rust-overlay` in a comment)

When the exact version is unavailable in nixpkgs, default to the latest
stable and add a comment noting the requested version.

## Flake generation

Generate `flake.nix` at the project root. The structure follows:

```nix
{
  description = "<project-name> development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      # Support both x86_64 and aarch64 for Linux and Darwin
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux" "aarch64-linux"
        "x86_64-darwin" "aarch64-darwin"
      ];
    in
    {
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # <detected packages here>
            ];

            shellHook = ''
              # <language-specific shell hooks>
            '';
          };
        }
      );
    };
}
```

For per-language package lists and shellHook contents, see
`references/language-templates.md`.

### Multi-platform support

Always use `forAllSystems` (or `flake-utils.lib.eachDefaultSystem`)
rather than hardcoding a single system string. This ensures the flake
works on both Linux and macOS, x86_64 and aarch64. If the project is
exclusively Linux, add a comment noting the restriction rather than
removing other systems.

## .envrc generation

Create `.envrc` at the project root:

```bash
use flake
```

If `.envrc` already exists, append `use flake` only if it is not
already present.

## .gitignore updates

Add these entries to `.gitignore` if not already present:

```text
# Nix / direnv
.direnv/
result
```

Do **not** add `flake.lock` to `.gitignore` — the lock file pins
package versions and **must** be committed for reproducibility.

## Verification

After generating the flake, verify it evaluates:

```bash
nix flake check --no-build
```

If `nix flake check` fails, read the error and fix the `flake.nix`.
Common issues:

- **Missing attribute** — a package name was wrong for nixpkgs.
  Search with `nix search nixpkgs <name>`.
- **Infinite recursion** — usually a `let` binding that references
  itself. Check for circular definitions.
- **IFD (import-from-derivation)** — avoid in devShells; use
  `pkgs.mkShell` with static package lists only.

If direnv is installed, run:

```bash
direnv allow
```

## Existing flake handling

If `flake.nix` already exists in the project:

1. Read it and report what it currently provides.
2. Ask the user whether to replace, extend, or leave it unchanged.
3. **Never overwrite an existing flake.nix without confirmation.**

If `flake.lock` exists without `flake.nix`, the lock file is orphaned.
Note this to the user and proceed with generation.

## Error handling

- **Nix not installed** — stop and suggest the `nix-install` skill.
- **Flakes not enabled** — stop and suggest enabling flakes (see
  `nix-install` references for the config command).
- **No sentinel files and no user input** — create a minimal generic
  shell with `gnumake`, `curl`, `jq` and inform the user.
- **flake check fails** — do not leave a broken flake. Fix or remove
  it before finishing. Report what failed and why.

## References

- `references/language-templates.md` — per-language package lists,
  shellHook contents, and common extras (LSPs, formatters, linters).
- `references/flake-anatomy.md` — annotated flake.nix structure
  explaining each section for users new to Nix.
