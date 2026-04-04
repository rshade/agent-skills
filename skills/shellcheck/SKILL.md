---
name: shellcheck
description: >
  Validate shell scripts for syntax errors, common bugs, quoting issues,
  and portability problems. Auto-detects shellcheck binary or guides
  installation. Checks project config or falls back to sensible defaults.
  Use when creating or modifying shell scripts, validating bash/sh files,
  or catching shell scripting mistakes before committing.
---
<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Shellcheck

Validate shell scripts (`.sh`, `bash`, `sh`, `dash`, `ksh`) for syntax
errors, common bugs, quoting issues, and portability problems. Catches
errors that would otherwise only surface at runtime.

## What this skill does

1. Checks if `shellcheck` is available; guides installation if missing.
2. Detects project-specific `.shellcheckrc` or falls back to a sensible
   default config.
3. Validates shell scripts for syntax, quoting, security, portability,
   and best practice issues.
4. Reports errors with specific SC codes and concrete fixes.

## Installation check

```bash
shellcheck --version 2>/dev/null
```

If not installed, install using one of:

```bash
# Debian/Ubuntu
sudo apt-get install shellcheck

# Homebrew (macOS/Linux)
brew install shellcheck

# Snap
sudo snap install shellcheck

# Download binary (Linux amd64)
curl -sL "$(curl -sL https://api.github.com/repos/koalaman/shellcheck/releases/latest \
  | grep browser_download_url | grep linux.x86_64.tar.xz | cut -d'"' -f4)" \
  | tar xJ -C /usr/local/bin shellcheck
```

If installation fails, stop and report the issue with remediation steps.
Do **not** silently skip validation.

## Config detection priority

1. `.shellcheckrc` in project root
2. `~/.shellcheckrc` in home directory
3. `$XDG_CONFIG_HOME/shellcheckrc` (if XDG_CONFIG_HOME is set)
4. Default config (see `references/shellcheckrc`)

If no project config exists, use the default config from references before
running validation.

## Validation workflow

```text
1. Check shellcheck installation
   ├─ Installed → continue
   └─ Missing → install, then continue (fail if install fails)

2. Detect project config
   ├─ Found → use it
   └─ Not found → use default config from references/

3. Run validation
   ├─ All scripts:
   │    find . -name '*.sh' -exec shellcheck {} +
   ├─ Specific files:
   │    shellcheck script.sh deploy.sh
   └─ With explicit shell:
        shellcheck -s bash script.sh

4. Report results
   ├─ Valid → confirm and proceed
   └─ Invalid → show errors, suggest fixes, re-validate after correction
```

## Validation methods

### Validate all shell scripts (auto-discovers `*.sh`)

```bash
find . -name '*.sh' -exec shellcheck {} +
```

### Validate specific files

```bash
shellcheck script.sh deploy.sh
```

### Validate with explicit shell dialect

```bash
shellcheck -s bash script.sh
shellcheck -s sh script
shellcheck -s dash dash-script
```

### Validate from stdin (useful for generated scripts)

```bash
cat script.sh | shellcheck -
```

### Filter by severity level

```bash
# Warnings and above
shellcheck --severity=warning script.sh

# Errors only
shellcheck --severity=error script.sh

# Info and above (verbose)
shellcheck --severity=info script.sh
```

## Error handling

### Install failure

If shellcheck cannot be installed, report the error and provide remediation
steps. Do not proceed with validation.

### Validation failure

When validation fails, report each error with:

- The file and line number
- The SC code (e.g., SC2086)
- The severity (error, warning, info, style)
- What was wrong
- A concrete fix

Example:

```text
Validation failed:

1. script.sh:5:3 SC2086 (info): Double quote to prevent globbing
   Bad:   echo $USER logged in at $HOME
   Fix:   echo "$USER logged in at $HOME"

2. script.sh:12:1 SC2164 (warning): Use 'cd ... || exit' in case cd fails
   Bad:   cd /app
   Fix:   cd /app || exit 1

3. script.sh:15:20 SC2155 (warning): Declare and assign separately
   Bad:   local result=$(whoami)
   Fix:   local result; result=$(whoami)

4. script.sh:18:1 SC2012 (info): Use find instead of ls in loops
   Bad:   for f in $(ls *.txt); do
   Fix:   for f in *.txt; do
```

After reporting errors, suggest fixes and re-validate after correction.

## Rule reference

See `references/shellcheck-rules.md` for the full rule reference, common
error categories, SC code explanations, and detailed fix examples.
