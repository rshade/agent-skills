<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Actionlint Rules Reference

Reference for actionlint error categories commonly encountered during
validation. actionlint checks are grouped by category rather than
numbered rule IDs. For the full list, see the
[actionlint checks documentation](https://github.com/rhysd/actionlint/blob/main/docs/checks.md).

## Error categories

| Category | Description | Example |
| --- | --- | --- |
| Syntax | Invalid YAML or workflow structure | Missing `runs-on`, bad indentation |
| Action | Invalid action references | `actions/checkout@master` (use tag) |
| Expression | `${{ }}` errors | Undefined property, type mismatch |
| Shell script | Shell errors in `run:` blocks | Requires shellcheck installed |
| Credentials | Untrusted input in `run:` | `${{ github.event.pull_request.title }}` in shell |
| Runner | Invalid `runs-on` labels | Typo in runner label |
| Events | Invalid `on:` configuration | Unsupported event type or filter combo |
| Matrix | Matrix configuration errors | Undefined matrix property |
| Permissions | Invalid permission values | Typo in permissions key |
| Environment | Environment variable issues | `${{ env.UNDEFINED }}` |

## Common errors and fixes

### Action version pinning

```yaml
# Wrong — mutable ref
- uses: actions/checkout@master

# Fixed — pinned to version tag
- uses: actions/checkout@v4

# Best — pinned to commit hash
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4
```

### Expression context errors

```yaml
# Wrong — "repo" is not a property of github context
run: echo ${{ github.repo }}

# Fixed — correct property name
run: echo ${{ github.repository }}
```

```yaml
# Wrong — "always" needs parentheses (it's a function)
if: always

# Fixed
if: always()
```

### Shell injection (security)

```yaml
# Dangerous — untrusted input directly in shell
run: echo "Title: ${{ github.event.pull_request.title }}"

# Fixed — use environment variable
env:
  PR_TITLE: ${{ github.event.pull_request.title }}
run: echo "Title: $PR_TITLE"
```

Untrusted contexts that should never appear directly in `run:` blocks:

- `github.event.issue.title`
- `github.event.issue.body`
- `github.event.pull_request.title`
- `github.event.pull_request.body`
- `github.event.comment.body`
- `github.event.discussion.title`
- `github.event.discussion.body`
- `github.head_ref`

### Event filter conflicts

```yaml
# Wrong — "paths" filter not supported with "tags" filter
on:
  push:
    tags: ["v*"]
    paths: ["src/**"]

# Fixed — separate into two workflows or remove one filter
on:
  push:
    tags: ["v*"]
```

### Invalid runner labels

```yaml
# Wrong — typo in runner label
runs-on: ubunut-latest

# Fixed
runs-on: ubuntu-latest
```

Known GitHub-hosted runner labels: `ubuntu-latest`, `ubuntu-22.04`,
`ubuntu-24.04`, `macos-latest`, `macos-14`, `macos-15`,
`windows-latest`, `windows-2022`, `windows-2025`.

### Matrix property references

```yaml
# Wrong — matrix property not defined
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest]
runs-on: ${{ matrix.operating-system }}

# Fixed — use defined property name
runs-on: ${{ matrix.os }}
```

### Missing required fields

```yaml
# Wrong — job missing runs-on
jobs:
  build:
    steps:
      - run: echo hello

# Fixed
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo hello
```

### Permissions format

```yaml
# Wrong — invalid permission scope
permissions:
  content: read

# Fixed — correct scope name
permissions:
  contents: read
```

Valid permission scopes: `actions`, `attestations`, `checks`,
`contents`, `deployments`, `discussions`, `id-token`, `issues`,
`packages`, `pages`, `pull-requests`, `repository-projects`,
`security-events`, `statuses`.

## Config file format

The `.actionlintrc.yaml` config supports these fields:

```yaml
self-hosted-runner:
  labels:
    - my-runner       # custom self-hosted runner labels

ignore:
  - 'pattern to ignore'  # regex patterns to suppress errors

paths:
  shellcheck: /usr/bin/shellcheck  # custom shellcheck path
  pyflakes: /usr/bin/pyflakes      # custom pyflakes path
```

## Output formats

```bash
# Default (human-readable, best for agent reporting)
actionlint

# JSON (machine-readable)
actionlint -format '{{json .}}'

# SARIF (for GitHub Code Scanning)
actionlint -format sarif
```
