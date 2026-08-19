#!/usr/bin/env bash
# Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0.
# SPDX-License-Identifier: Apache-2.0
#
# Run Snyk Agent Scan over skills/ and write the raw JSON report.
#
# Usage: tests/security/run-scan.sh [OUTPUT_JSON]
#
# Requires SNYK_TOKEN (https://app.snyk.io/account) and uv/uvx.

set -euo pipefail

# Pinned deliberately. v0.6 replaces W* issue codes with scored "risk
# indicators" and changes the JSON root shape, which would silently break
# baseline.json. Bump only alongside check-baseline.py.
SCANNER_VERSION="0.5.17"

ROOT="$(git rev-parse --show-toplevel)"
OUTPUT="${1:-${ROOT}/scan-results.json}"

if [ -z "${SNYK_TOKEN:-}" ]; then
    echo "ERROR: SNYK_TOKEN is not set." >&2
    echo "Get a token at https://app.snyk.io/account (API Token -> KEY)." >&2
    exit 1
fi

if ! command -v uvx >/dev/null 2>&1; then
    echo "ERROR: uvx not found. Install uv: https://docs.astral.sh/uv/getting-started/installation/" >&2
    exit 1
fi

echo "Scanning ${ROOT}/skills with snyk-agent-scan@${SCANNER_VERSION}..."

# --json sends only the JSON document to stdout. --ci is deliberately not
# used: it requires --dangerously-run-mcp-servers, which executes MCP server
# commands. This repo ships no MCP configs, and check-baseline.py owns the
# exit code anyway.
uvx "snyk-agent-scan@${SCANNER_VERSION}" --json "${ROOT}/skills" >"${OUTPUT}"

echo "Wrote ${OUTPUT}"
