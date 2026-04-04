<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Shellcheck Rules Reference

Reference for shellcheck error categories and SC codes commonly encountered
during validation. For the full list, see the
[shellcheck wiki](https://github.com/koalaman/shellcheck/wiki).

## Error categories

| Category | Codes | Description |
| --- | --- | --- |
| Quoting | SC2086, SC2046, SC2048 | Unquoted variables and command substitutions |
| Syntax | SC1073, SC1009, SC1072 | Parse errors and syntax mistakes |
| Portability | SC2039, SC3043 | Bash-isms in POSIX sh scripts |
| Security | SC2091, SC2012 | Command injection, unsafe patterns |
| Best practices | SC2155, SC2164, SC2103 | Variable scope, error handling, navigation |
| Unused | SC2034, SC2154 | Unused variables, undefined variables |

## Common errors and fixes

### SC2086: Double quote to prevent globbing and word splitting

Unquoted variables expand to multiple words, breaking assumptions about
single arguments.

```bash
# Bad — $USER and $HOME expand as separate words, may glob
echo $USER logged in at $HOME

# Fixed — quoted variables stay as single arguments
echo "$USER logged in at $HOME"
```

### SC2046: Quote command substitution to prevent globbing

Unquoted command substitution splits on whitespace and glob patterns.

```bash
# Bad — $(find ...) output splits on whitespace
rm $(find . -name "*.txt")

# Fixed — quoted command substitution preserves output
rm "$(find . -name "*.txt")"
```

### SC2164: Use 'cd ... || exit' in case cd fails

Silently failing `cd` commands can cause subsequent operations to run in the
wrong directory, creating serious bugs.

```bash
# Bad — if cd fails, script continues in wrong directory
cd /app
npm install

# Fixed — exit script if cd fails
cd /app || exit 1
npm install
```

### SC2155: Declare and assign separately

Combining `local`/`declare` with assignment hides the exit code of the
assignment, making error checking impossible.

```bash
# Bad — assignment exit code is hidden
local result=$(whoami)

# Fixed — declare first, then assign
local result
result=$(whoami)
```

### SC2039: Bash-ism in POSIX sh script

Using bash features (`[[ ]]`, `${var:offset}`, etc.) in scripts with `#!/bin/sh`
shebang breaks portability.

```bash
#!/bin/sh  # Uses POSIX shell, not bash

# Bad — [[ ]] is bash-only
if [[ "$1" = "test" ]]; then
    echo "testing"
fi

# Fixed — use [ ] for POSIX compatibility
if [ "$1" = "test" ]; then
    echo "testing"
fi
```

### SC2012: Use find or ls-alternatives to parse filenames

Parsing `ls` output is unreliable and breaks on special filenames (spaces,
newlines, glob characters).

```bash
# Bad — ls output splits on whitespace and special chars
for f in $(ls *.txt); do
    echo "Processing $f"
done

# Fixed — use glob expansion directly
for f in *.txt; do
    echo "Processing $f"
done
```

## Severity levels

Shellcheck reports errors at different severity levels. Filter with
`--severity=LEVEL`:

- **error**: Must be fixed; script will likely fail at runtime
- **warning**: Should be fixed; indicates potential bugs or bad practices
- **info**: Informational; best practice suggestions (default threshold)
- **style**: Code style suggestions (rarely used)

Filter examples:

```bash
# Show only errors and warnings (filter out info and style)
shellcheck --severity=warning script.sh

# Show only errors
shellcheck --severity=error script.sh

# Show everything (default)
shellcheck script.sh
```

## Shell dialects

Shellcheck auto-detects shell dialect from the script's shebang
(`#!/bin/bash`, `#!/bin/sh`, etc.). Override with `-s SHELL`:

```bash
# Auto-detect from shebang
shellcheck script.sh

# Explicit shell
shellcheck -s bash script
shellcheck -s sh script
shellcheck -s dash script
shellcheck -s ksh script
```

Supported shells: `sh`, `bash`, `dash`, `ksh`, `zsh`.

## Config file format

The `.shellcheckrc` config file allows disabling specific rules, setting
default shell, and customizing behavior:

```bash
# Disable specific rules (SC codes)
disable=SC2086
disable=SC2046

# Set default shell dialect (sh, bash, dash, ksh)
shell=bash

# Enable optional checks
enable=avoid-nullary-conditions
```

Place `.shellcheckrc` in the project root. Shellcheck also checks:

- `~/.shellcheckrc` (user-level config)
- `$XDG_CONFIG_HOME/shellcheckrc` (XDG standard location)
