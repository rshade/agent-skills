<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Hadolint Rules Reference

Reference for hadolint error codes commonly encountered during Dockerfile
validation. Hadolint checks are identified by rule codes: DL-prefixed
codes for Dockerfile best practices, and SC-prefixed codes for shell
scripts in RUN instructions. For the full list, see the
[hadolint checks documentation](https://github.com/hadolint/hadolint/wiki/DL3006).

## Rule code prefixes

- **DL-prefixed** (DL3006, DL3008, etc.): Dockerfile best practices
  (tagging, package pinning, cleanup, COPY vs ADD, shell directives,
  user management, deprecated instructions, apt best practices).
- **SC-prefixed** (SC2086, SC2046, etc.): shellcheck codes applied to RUN
  instruction shell commands. For full SC code reference, see the
  shellcheck skill documentation.

## Dockerfile rule categories

| Category | Codes | Description |
| --- | --- | --- |
| Image tagging | DL3006, DL3007 | Always tag base images; use specific versions |
| Package pinning | DL3008, DL3013, DL3016, DL3018 | Pin apt, pip, npm, apk package versions |
| Cleanup | DL3009, DL3010 | Delete package manager cache; use `--rm` |
| COPY vs ADD | DL3020, DL3025 | Use COPY for files; use ADD only for URLs/archives |
| Shell practices | DL4006, DL4005 | Set SHELL for pipefail; don't use sh -c |
| User management | DL3002 | Do not switch to root; run as non-root |
| Deprecated | DL4000 | MAINTAINER is deprecated; use LABEL |
| Apt best practices | DL3015, DL3014 | Use --no-install-recommends; use apt-get clean |
| Registry validation | DL3026 | Verify images are from trusted registries |

## Common DL errors and fixes

### DL3006: Always tag the version of an image explicitly

Untagged or mutable references allow unpredictable image changes.

```dockerfile
# Wrong — no tag (resolves to latest, which is mutable)
FROM ubuntu
FROM node

# Fixed — explicit version tag
FROM ubuntu:22.04
FROM node:20-alpine
```

### DL3008: Pin versions in apt-get install

Unpinned packages can introduce unexpected changes and incompatibilities.

```dockerfile
# Wrong — no version pins
RUN apt-get update && apt-get install -y curl wget

# Fixed — pinned versions
RUN apt-get update && apt-get install -y \
    curl=7.88.1-10+deb12u5 \
    wget=1.21.3-1+deb12u1
```

### DL3009: Delete the apt-get lists after installing

Package cache wastes image space. Remove after install.

```dockerfile
# Wrong — cache left behind
RUN apt-get update && apt-get install -y curl

# Fixed — cleanup included
RUN apt-get update && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*
```

### DL3015: Use --no-install-recommends flag in apt-get install

Skips optional packages not required for base functionality.

```dockerfile
# Wrong — no flag
RUN apt-get install -y curl

# Fixed — with flag
RUN apt-get install -y --no-install-recommends curl
```

### DL3020: Use COPY instead of ADD

COPY is simpler and more explicit than ADD for file operations.

```dockerfile
# Wrong — ADD for local file
ADD app.jar /app/

# Fixed — COPY for local file
COPY app.jar /app/
```

### DL4000: MAINTAINER is deprecated, use LABEL instead

MAINTAINER is deprecated in newer Docker versions.

```dockerfile
# Wrong
MAINTAINER admin@example.com

# Fixed
LABEL maintainer="admin@example.com"
```

### DL4006: Set the SHELL directive in RUN for pipefail

Without pipefail, shell pipe failures are masked.

```dockerfile
# Wrong — pipes can fail silently
RUN curl https://example.com | tar xz

# Fixed — pipefail via SHELL
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl https://example.com | tar xz
```

## SC codes in Dockerfiles

hadolint runs shellcheck on RUN instruction content. Common SC codes:

| Code | Description | Example |
| --- | --- | --- |
| SC2086 | Double quote to prevent globbing | `COPY $SOURCE` → `COPY "$SOURCE"` |
| SC2046 | Quote to avoid word splitting | `RUN echo $VAR` → `RUN echo "$VAR"` |
| SC2076 | Single quotes in glob patterns | `[[ $x == "str"* ]]` (use =~) |
| SC2181 | Check exit code directly | `command; if [ $? -eq 0 ]` (use `if command`) |

For a comprehensive list of SC codes, see the
[shellcheck documentation](https://www.shellcheck.net/wiki/).

## Config file format

Place `.hadolint.yaml` in the project root or home directory to override
defaults:

```yaml
# Rules to ignore (suppress specific DL/SC codes)
ignored:
  - DL3008
  - DL3015
  - SC2086

# Trusted registries (images from these are not checked with DL3026)
trustedRegistries:
  - docker.io
  - gcr.io
  - ghcr.io
  - quay.io
  - mycompany.azurecr.io

# Override severity levels per rule
override:
  error:
    - DL3001
    - DL3002
  warning:
    - DL3042
    - DL3043
```

### Common config use cases

**Ignore all package pinning warnings** (DL3008, DL3013, DL3016, DL3018):

```yaml
ignored:
  - DL3008
  - DL3013
  - DL3016
  - DL3018
```

**Add private registry to trusted list**:

```yaml
trustedRegistries:
  - docker.io
  - registry.company.com
```

**Treat all info/style as warnings**:

```yaml
override:
  warning:
    - DL1000
    - DL1001
```

## Output formats

```bash
# Default (human-readable, best for agent reporting)
hadolint Dockerfile

# JSON (machine-readable)
hadolint --format=json Dockerfile

# SARIF (standard analysis format, GitHub Code Scanning)
hadolint --format=sarif Dockerfile

# CodeClimate (GitLab integration)
hadolint --format=codeclimate Dockerfile
```

## Severity levels

hadolint reports four severity levels:

- **error**: Serious issues that should be fixed
- **warning**: Best practice violations that should be addressed
- **info**: Informational messages about improvements
- **style**: Code style suggestions

All levels are reported by default. Filter with `--severity=warning` to
suppress info/style, or `--severity=error` to show only errors.
