<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
# Language Templates

Per-language package lists, shellHook contents, and common extras for
devShell generation. The agent should use these as the source of truth
for nixpkgs attribute names.

## Go

**Sentinel files:** `go.mod`, `go.sum`

**Packages:**

```nix
packages = with pkgs; [
  go           # or go_1_22 for pinned versions
  gopls        # LSP
  gotools      # goimports, etc.
  golines      # line-length formatter
  golangci-lint
  delve        # debugger
];
```

**Version mapping:**

| go.mod directive | nixpkgs attribute |
| --- | --- |
| `go 1.24` | `go` (latest, usually matches) |
| `go 1.23` | `go_1_23` |
| `go 1.22` | `go_1_22` |
| `go 1.21` | `go_1_21` |

**shellHook:**

```nix
shellHook = ''
  export GOPATH="$HOME/go"
  export PATH="$GOPATH/bin:$PATH"
'';
```

**Common extras:**

- `goreleaser` — if `goreleaser.yaml` or `.goreleaser.yml` exists
- `protobuf` + `protoc-gen-go` — if `.proto` files exist
- `mockgen` — if `//go:generate mockgen` appears in source

## Node.js

**Sentinel files:** `package.json`, `package-lock.json`, `yarn.lock`,
`pnpm-lock.yaml`, `bun.lockb`

**Packages:**

```nix
packages = with pkgs; [
  nodejs_22    # or nodejs_20, nodejs_18
  nodePackages.npm
  nodePackages.typescript
  nodePackages.typescript-language-server
];
```

**Version mapping:**

| engines.node | nixpkgs attribute |
| --- | --- |
| `>=22` or `^22` | `nodejs_22` |
| `>=20` or `^20` | `nodejs_20` |
| `>=18` or `^18` | `nodejs_18` |
| unspecified | `nodejs_22` (latest LTS) |

**Package manager detection:**

| Lock file | Package manager | nixpkgs attribute |
| --- | --- | --- |
| `package-lock.json` | npm | `nodePackages.npm` (included with nodejs) |
| `yarn.lock` | Yarn | `yarn` |
| `pnpm-lock.yaml` | pnpm | `nodePackages.pnpm` |
| `bun.lockb` | Bun | `bun` |

**shellHook:**

```nix
shellHook = ''
  export NODE_OPTIONS="--max-old-space-size=4096"
'';
```

The `NODE_OPTIONS` line is optional — include only for large projects
or when `package.json` scripts are memory-intensive.

**Common extras:**

- `nodePackages.eslint` — if `.eslintrc*` or `eslint.config.*` exists
- `nodePackages.prettier` — if `.prettierrc*` exists
- `playwright` — if `playwright.config.*` exists (note: Playwright
  needs additional browser binaries; add a comment about
  `npx playwright install`)

## Python

**Sentinel files:** `pyproject.toml`, `requirements.txt`, `setup.py`,
`setup.cfg`, `Pipfile`

**Packages:**

```nix
packages = with pkgs; [
  python312    # or python311, python310
  uv           # fast package manager + virtualenv
  ruff         # linter + formatter
];
```

**Version mapping:**

| requires-python | nixpkgs attribute |
| --- | --- |
| `>=3.12` | `python312` |
| `>=3.11` | `python311` |
| `>=3.10` | `python310` |
| unspecified | `python312` (latest stable) |

**shellHook:**

```nix
shellHook = ''
  # Activate venv if it exists (uv creates .venv by default)
  if [ -d .venv ]; then
    source .venv/bin/activate
  fi
'';
```

**Common extras:**

- `pyright` — if `pyrightconfig.json` exists or `pyright` is in
  dev-dependencies
- `mypy` — if `mypy.ini` or `[tool.mypy]` section in `pyproject.toml`
- `pre-commit` — if `.pre-commit-config.yaml` exists

**Virtual environment note:** Do **not** include Python project
dependencies in the Nix devShell. Use `uv` or `pip` inside the shell
to manage project dependencies in a virtualenv. The devShell provides
the Python interpreter and tools; the virtualenv provides the project's
packages.

## Rust

**Sentinel files:** `Cargo.toml`, `Cargo.lock`

**Packages:**

```nix
packages = with pkgs; [
  rustc
  cargo
  rust-analyzer
  clippy
  rustfmt
];
```

**Nightly / pinned toolchain:** If `rust-toolchain.toml` exists and
specifies `nightly` or a specific date, the nixpkgs Rust may not match.
Add a comment:

```nix
# Note: rust-toolchain.toml requests nightly/specific version.
# For exact version pinning, consider adding oxalica/rust-overlay
# as a flake input. See: github:oxalica/rust-overlay
```

**shellHook:**

```nix
shellHook = ''
  export RUST_SRC_PATH="${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}"
'';
```

**Common extras:**

- `pkg-config` + `openssl` — if `Cargo.toml` depends on crates that
  link to system libraries (e.g., `reqwest`, `openssl-sys`)
- `cargo-watch` — for development iteration
- `cargo-nextest` — modern test runner

## Multi-language projects

When multiple sentinel files are detected, merge all packages into a
single `packages` list and combine shellHooks:

```nix
packages = with pkgs; [
  # Go
  go gopls gotools

  # Node.js
  nodejs_22 nodePackages.npm

  # Python
  python312 uv ruff
];

shellHook = ''
  # Go
  export GOPATH="$HOME/go"
  export PATH="$GOPATH/bin:$PATH"

  # Python
  if [ -d .venv ]; then
    source .venv/bin/activate
  fi
'';
```

Group packages by language with comments for readability. Order
languages alphabetically.

## Generic (no language detected)

When no sentinel files are found and the user does not specify a
language, create a minimal shell:

```nix
packages = with pkgs; [
  gnumake
  curl
  jq
];
```

No shellHook needed.
