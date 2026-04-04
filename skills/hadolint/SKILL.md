---
name: hadolint
description: >
  Validate Dockerfiles against best practices for syntax errors, image
  tagging, package pinning, and shell script issues in RUN commands.
  Auto-detects hadolint binary or Docker image fallback. Checks project
  config or falls back to sensible defaults. Use when creating or
  modifying Dockerfiles, reviewing container images, or catching
  Dockerfile anti-patterns before building.
---
<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Hadolint

Validate Dockerfiles for syntax errors, best practice violations, and
embedded shell script issues. Checks image tagging, package pinning,
cleanup, COPY vs ADD, shell script issues in RUN commands, and
deprecated instructions. Catches errors that would cause build failures
or runtime issues.

## What this skill does

1. Checks if `hadolint` is available; provides installation guidance if
   missing (system binary first, Docker fallback).
2. Detects project-specific `.hadolint.yaml` or falls back to sensible
   default config.
3. Validates Dockerfile(s) for syntax, best practices, and shell script
   issues in RUN commands.
4. Reports errors with DL (Dockerfile) and SC (shell) rule codes and
   concrete fixes.

## Installation check

```bash
hadolint --version 2>/dev/null
```

If not installed, try system installation:

```bash
# Apt (Debian/Ubuntu)
sudo apt-get install hadolint

# Homebrew (macOS/Linux)
brew install hadolint

# Direct download (Linux amd64)
wget -O /usr/local/bin/hadolint \
  https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64
chmod +x /usr/local/bin/hadolint
```

If system install fails or is unavailable, fall back to Docker:

```bash
docker run --rm hadolint/hadolint hadolint --version 2>/dev/null
```

If both system binary and Docker are unavailable, stop and report the
issue with remediation steps. Do **not** silently skip validation.

## Config detection priority

1. `.hadolint.yaml` in project root
2. `.hadolint.yaml` in home directory (`~/.hadolint.yaml`)
3. `$XDG_CONFIG_HOME/hadolint.yaml` (XDG standard)
4. Default config from `references/hadolint-config.yaml`

If no project config exists and using system binary, create a temporary
`.hadolint.yaml` using the default config from references before running
validation. For Docker mode, mount the config file if it exists.

## Validation workflow

```text
1. Check hadolint installation
   ├─ System binary available → continue
   ├─ Missing → try install
   │   ├─ Install succeeds → continue
   │   └─ Install fails → Docker fallback
   │       ├─ Docker available → continue (Docker mode)
   │       └─ Docker unavailable → fail with remediation
   
2. Detect project config
   ├─ Found .hadolint.yaml → use it
   └─ Not found → use default config from references/
   
3. Run validation
   ├─ System binary:
   │    hadolint Dockerfile
   └─ Docker mode:
        docker run --rm -i hadolint/hadolint < Dockerfile
   
4. Report results
   ├─ Valid → confirm and proceed
   └─ Invalid → show DL/SC errors, suggest fixes, re-validate
```

## Validation methods

### Validate a single Dockerfile

```bash
hadolint Dockerfile
```

### Validate multiple files

```bash
hadolint Dockerfile Dockerfile.prod Dockerfile.dev
```

### Validate with explicit config

```bash
hadolint --config .hadolint.yaml Dockerfile
```

### Validate from stdin

```bash
cat Dockerfile | hadolint -
```

### Docker fallback (if system binary unavailable)

```bash
docker run --rm -i hadolint/hadolint < Dockerfile
```

### Docker fallback with config

```bash
docker run --rm -i \
  -v "$(pwd)/.hadolint.yaml:/.config/hadolint.yaml" \
  hadolint/hadolint < Dockerfile
```

## Error handling

### Install failure

If hadolint cannot be installed via system package manager and Docker is
also unavailable, report the error with remediation steps. Do not proceed
with validation.

### Validation failure

When validation fails, report each error with:

- The file and line number
- The error code (DL prefix for Dockerfile best practices, SC prefix for
  shell script issues)
- What was wrong
- A concrete fix

Example:

```text
Validation failed:

1. Dockerfile:1 DL3006 warning: Always tag the version of an image explicitly
   Fix: FROM ubuntu → FROM ubuntu:22.04

2. Dockerfile:3 DL3008 warning: Pin versions in apt-get install
   Fix: apt-get install -y curl → apt-get install -y curl=7.88.1-10+deb12u5

3. Dockerfile:3 DL3009 info: Delete the apt-get lists after installing
   Fix: add && rm -rf /var/lib/apt/lists/* at the end of RUN

4. Dockerfile:4 DL3015 warning: Use --no-install-recommends flag in apt-get install
   Fix: apt-get install -y → apt-get install -y --no-install-recommends

5. Dockerfile:5 DL3020 warning: Use COPY instead of ADD for files
   Fix: ADD https://example.com/app.tar.gz → use curl or wget in RUN

6. Dockerfile:7 DL4000 error: MAINTAINER is deprecated, use LABEL instead
   Fix: MAINTAINER user@example.com → LABEL maintainer="user@example.com"

7. Dockerfile:10 DL4006 warning: Set the SHELL directive in RUN for pipefail
   Fix: add SHELL ["/bin/bash", "-o", "pipefail", "-c"] before RUN with pipes

8. Dockerfile:3 SC2086 info: Double quote to prevent globbing
   Fix: COPY $SOURCE → COPY "$SOURCE"
```

DL codes identify Dockerfile-specific issues. SC codes are from shellcheck
applied to RUN instruction content. After reporting errors, suggest fixes
and ask to re-validate after correction.

## Rule reference

See `references/hadolint-rules.md` for the full rule reference, common
error categories, detailed DL/SC code explanations, fix examples, and
config file format.
