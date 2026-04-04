---
name: actionlint
description: >
  Validate GitHub Actions workflow files for syntax errors, invalid
  references, and common mistakes. Auto-detects actionlint binary or
  guides installation. Checks project config or falls back to sensible
  defaults. Use when creating or modifying GitHub Actions workflows,
  validating CI/CD pipelines, or catching workflow errors before pushing.
---
<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Actionlint

Validate GitHub Actions workflow files (`.github/workflows/*.yml`) for
syntax errors, invalid references, expression mistakes, and security
issues. Catches errors that would otherwise only surface at runtime.

## What this skill does

1. Checks if `actionlint` is available; guides installation if missing.
2. Detects project-specific `.actionlintrc.yaml` or falls back to a
   sensible default config.
3. Validates workflow files for syntax, action references, expressions,
   shell scripts, and security issues.
4. Reports errors with specific rule categories and fixes.

## Installation check

```bash
actionlint --version 2>/dev/null
```

If not installed, install using one of:

```bash
# Go (requires Go 1.22+)
go install github.com/rhysd/actionlint/cmd/actionlint@latest

# Homebrew (macOS/Linux)
brew install actionlint

# Download binary (Linux amd64)
curl -sL "$(curl -sL https://api.github.com/repos/rhysd/actionlint/releases/latest \
  | grep browser_download_url | grep linux_amd64.tar.gz | cut -d'"' -f4)" \
  | tar xz -C /usr/local/bin actionlint
```

If installation fails, stop and report the issue with remediation steps.
Do **not** silently skip validation.

**Optional enhancement**: if `shellcheck` is installed, actionlint
automatically validates shell scripts in `run:` blocks. This is
recommended but not required.

## Config detection priority

1. `.actionlintrc.yaml` in project root
2. Default config (see `references/actionlint-config.yaml`)

If no project config exists, create a temporary `.actionlintrc.yaml`
using the default config from references before running validation.

## Validation workflow

```text
1. Check actionlint installation
   ├─ Installed → continue
   └─ Missing → install, then continue (fail if install fails)

2. Detect project config
   ├─ Found → use it
   └─ Not found → use default config from references/

3. Run validation
   ├─ All workflows:
   │    actionlint
   ├─ Specific files:
   │    actionlint .github/workflows/ci.yml
   └─ With config:
        actionlint -config-file .actionlintrc.yaml

4. Report results
   ├─ Valid → confirm and proceed
   └─ Invalid → show errors, suggest fixes, re-validate after correction
```

## Validation methods

### Validate all workflow files (auto-discovers `.github/workflows/`)

```bash
actionlint
```

### Validate specific files

```bash
actionlint .github/workflows/ci.yml .github/workflows/release.yml
```

### Validate with explicit config

```bash
actionlint -config-file .actionlintrc.yaml
```

### Validate from stdin (useful for generated workflows)

```bash
cat workflow.yml | actionlint -
```

## Error handling

### Install failure

If actionlint cannot be installed, report the error and provide
remediation steps. Do not proceed with validation.

### Validation failure

When validation fails, report each error with:

- The file and line number
- The error category (syntax, action, expression, runner, shell, etc.)
- What was wrong
- A concrete fix

Example:

```text
Validation failed:

1. .github/workflows/ci.yml:15:9
   action "actions/checkout@master" — use a commit hash or version tag
   Fix: actions/checkout@v4

2. .github/workflows/ci.yml:23:14
   expression error: property "repo" not defined in "github" context
   Fix: use "github.repository" instead of "github.repo"

3. .github/workflows/deploy.yml:8:5
   "push" event does not support "paths" filter with "tags" filter
   Fix: split into separate workflows or remove one filter
```

After reporting errors, suggest fixes and re-validate after correction.

## Rule reference

See `references/actionlint-rules.md` for the full rule reference,
common error categories, security checks, and fix examples.
