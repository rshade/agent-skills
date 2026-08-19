#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load .env from repo root if it exists
if [ -f "$REPO_ROOT/.env" ]; then
    echo "Loading .env from repo root..."
    set -a
    # shellcheck source=/dev/null
    . "$REPO_ROOT/.env"
    set +a
fi

echo "========================================="
echo " Nix DevShell Init Skill — Test Suite"
echo "========================================="
echo ""

# ── Tier 1-2: Fixture-based validation ───────────────────────────────

PASS=0
FAIL=0
EXIT_CODE=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); EXIT_CODE=1; }

# Check if nix is available (required for flake verification)
if ! command -v nix >/dev/null 2>&1; then
    echo "Nix not installed — skipping Tier 1-2 tests"
    echo "Install Nix to run these tests locally"
    EXIT_CODE=0
else
    echo "--- Tier 1: Go project fixture ---"
    TMPDIR_GO=$(mktemp -d)
    trap 'rm -rf "$TMPDIR_GO" "$TMPDIR_NODE" "$TMPDIR_PY" "$TMPDIR_MULTI" 2>/dev/null' EXIT
    echo 'module example.com/test' > "$TMPDIR_GO/go.mod"
    echo 'go 1.22' >> "$TMPDIR_GO/go.mod"

    # Generate a known-good flake for Go to validate the pattern
    cat > "$TMPDIR_GO/flake.nix" <<'GOFLAKE'
{
  description = "test-go development environment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux" "aarch64-linux"
        "x86_64-darwin" "aarch64-darwin"
      ];
    in {
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          default = pkgs.mkShell {
            packages = with pkgs; [ go gopls gotools ];
          };
        });
    };
}
GOFLAKE

    if (cd "$TMPDIR_GO" && nix flake check --no-build 2>&1); then
        pass "Go flake template evaluates cleanly"
    else
        fail "Go flake template failed evaluation"
    fi

    echo ""
    echo "--- Tier 1: Node.js project fixture ---"
    TMPDIR_NODE=$(mktemp -d)
    echo '{"name":"test-node","engines":{"node":">=20"}}' \
        > "$TMPDIR_NODE/package.json"

    cat > "$TMPDIR_NODE/flake.nix" <<'NODEFLAKE'
{
  description = "test-node development environment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux" "aarch64-linux"
        "x86_64-darwin" "aarch64-darwin"
      ];
    in {
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          default = pkgs.mkShell {
            packages = with pkgs; [ nodejs_20 nodePackages.npm ];
          };
        });
    };
}
NODEFLAKE

    if (cd "$TMPDIR_NODE" && nix flake check --no-build 2>&1); then
        pass "Node.js flake template evaluates cleanly"
    else
        fail "Node.js flake template failed evaluation"
    fi

    echo ""
    echo "--- Tier 1: Python project fixture ---"
    TMPDIR_PY=$(mktemp -d)
    cat > "$TMPDIR_PY/pyproject.toml" <<'PYTOML'
[project]
name = "test-python"
requires-python = ">=3.12"
PYTOML

    cat > "$TMPDIR_PY/flake.nix" <<'PYFLAKE'
{
  description = "test-python development environment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux" "aarch64-linux"
        "x86_64-darwin" "aarch64-darwin"
      ];
    in {
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          default = pkgs.mkShell {
            packages = with pkgs; [ python312 uv ruff ];
          };
        });
    };
}
PYFLAKE

    if (cd "$TMPDIR_PY" && nix flake check --no-build 2>&1); then
        pass "Python flake template evaluates cleanly"
    else
        fail "Python flake template failed evaluation"
    fi

    echo ""
    echo "--- Tier 1: Multi-language project fixture ---"
    TMPDIR_MULTI=$(mktemp -d)
    echo 'module example.com/multi' > "$TMPDIR_MULTI/go.mod"
    echo '{"name":"multi"}' > "$TMPDIR_MULTI/package.json"

    cat > "$TMPDIR_MULTI/flake.nix" <<'MULTIFLAKE'
{
  description = "multi development environment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux" "aarch64-linux"
        "x86_64-darwin" "aarch64-darwin"
      ];
    in {
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              go gopls gotools
              nodejs_22 nodePackages.npm
            ];
          };
        });
    };
}
MULTIFLAKE

    if (cd "$TMPDIR_MULTI" && nix flake check --no-build 2>&1); then
        pass "Multi-language flake template evaluates cleanly"
    else
        fail "Multi-language flake template failed evaluation"
    fi

    echo ""
    echo "--- Tier 1-2 Results: ${PASS} passed, ${FAIL} failed ---"
fi

# ── Tier 4: AI Agent Skill Test (requires OPENCODE_API_KEY) ──────────

if [ -z "${OPENCODE_API_KEY:-}" ]; then
    echo ""
    echo "Tier 4: SKIPPED (no OPENCODE_API_KEY set)"
    echo "Set OPENCODE_API_KEY in .env to test skill with an AI agent."
else
    echo ""
    echo "========================================="
    echo " Tier 4: AI Agent Skill Test"
    echo "========================================="
    echo ""
    if "$REPO_ROOT/tests/run-skill-test.sh" \
        nix-devshell-init \
        "initialize a nix devshell for this go project" \
        tests/nix-devshell-init/verify-skill.sh; then
        echo "--- Tier 4: PASSED ---"
    else
        echo "--- Tier 4: FAILED ---"
        EXIT_CODE=1
    fi
fi

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "========================================="
    echo " ALL TESTS PASSED"
    echo "========================================="
else
    echo "========================================="
    echo " SOME TESTS FAILED"
    echo "========================================="
fi

exit "$EXIT_CODE"
