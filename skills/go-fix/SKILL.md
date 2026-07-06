---
name: go-fix
description: >
  Modernize Go code with the rebuilt go fix command in Go 1.26+. Applies
  safe, version-aware rewrites to newer language and stdlib idioms
  (interface{} to any, 3-clause loops to range-over-int, min/max,
  strings.Cut, new(expr), and 20+ more), iterating to a fixed point and
  verifying the build afterward. Use whenever Go code should be
  modernized, cleaned up, or made idiomatic — after a go.mod version
  bump, when old-style or AI-generated patterns accumulate, when
  migrating callers off deprecated or renamed APIs (go:fix inline
  directives), when the user mentions go fix or gofix, or to enforce
  modern idioms as a CI gate. Not for gofmt formatting, dependency
  upgrades, or go vet bug-finding.
---
<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Go Fix

Modernize Go code using `go fix`, rebuilt in Go 1.26 on the Go analysis
framework. It applies safe rewrites toward newer language and stdlib
idioms, respecting the module's declared Go version — it never rewrites
code into something the module has not opted into via its `go.mod`.

## What this skill does

1. Verifies the toolchain is Go 1.26 or later; stops if not.
2. Checks preconditions: a Go module and a clean git state.
3. Previews fixes with `go fix -diff`, applies them, and re-runs until no
   fixes remain (fixes can expose further fixes).
4. Verifies the result builds and tests pass, then reports what changed.

## Toolchain check (required — do not skip)

The modernizers only exist in Go 1.26+. On older toolchains `go fix` is
the legacy tool: it runs, finds nothing, and exits cleanly — which reads
as "code is already modern" when it means "wrong toolchain". Gate first:

```bash
if [ "$(printf '%s\n' go1.26 "$(go env GOVERSION)" | sort -V | head -n1)" != "go1.26" ]; then
  echo "go fix modernizers require Go 1.26+, found $(go env GOVERSION)" >&2
  exit 1
fi
```

If the toolchain is too old, stop and report it with upgrade guidance
(<https://go.dev/dl/>). Do **not** silently run the legacy fixer.

## Preconditions

- **A Go module**: `go.mod` must exist in or above the working directory.
- **Clean git state**: `git status --porcelain` should be empty for the
  files being fixed, so the rewrite lands as an isolated, reviewable
  change. If the tree is dirty, ask before proceeding or commit/stash
  first.
- **Note the module's `go` directive**: fixes are gated by it. A module
  declaring `go 1.21` will receive `any` and `strings.Cut` rewrites but
  not `range n` (1.22) or `new(expr)` (1.26). Never bump the `go`
  directive just to unlock more fixes unless the user explicitly asks.

## Workflow

```text
1. Toolchain check
   ├─ go env GOVERSION >= go1.26 → continue
   └─ older → stop, report upgrade guidance

2. Preconditions
   ├─ go.mod present, git state clean → continue
   └─ dirty tree → ask / stash first

3. Preview
   └─ go fix -diff ./...
      ├─ exit 0 → nothing to do, report "already modern"
      └─ exit 1 → diff printed; review it, then apply

4. Apply to fixed point (cap at ~4 passes)
   └─ go fix ./... ; repeat while go fix -diff ./... exits 1

5. Verify
   ├─ go build ./... && go test ./...
   └─ failures are rare semantic conflicts → fix by hand, report

6. Report
   └─ analyzers that fired, files touched, behavior-change flags
```

## Run methods

### Full modernization to fixed point

```bash
go fix -diff ./...        # preview; exit 1 means fixes are available
go fix ./...              # apply
go fix -diff ./...        # re-check: some fixes expose more fixes
```

Repeat apply/check until `-diff` exits 0. Two passes usually suffice
(e.g. `minmax` collapses a clamp to `max(...)` first, then to
`min(max(...), ...)` on the next pass).

### One analyzer at a time (smaller, reviewable PRs)

```bash
go fix -newexpr ./...     # run only newexpr
go fix -any=false ./...   # run everything except any
```

Prefer this when a full run touches many files — one analyzer per commit
keeps review manageable.

### CI gate (no writes)

`go fix -diff` exits non-zero when fixes are available, so it works as a
check step exactly like `gofmt -l`:

```bash
go fix -diff ./...        # exit 0 = modern, exit 1 = drift (diff printed)
```

### Build-tagged code

`go fix` analyzes the current platform's file set. For code behind build
tags, run per platform:

```bash
GOOS=linux  GOARCH=amd64 go fix ./...
GOOS=darwin GOARCH=arm64 go fix ./...
```

## Safety and review notes

- Generated files (`// Code generated ... DO NOT EDIT.`) are skipped
  automatically — fix the generator instead.
- Most fixers are behavior-preserving, but review these two closely:
  - **omitzero**: replacing `omitempty` with `omitzero` on struct-typed
    JSON fields *is* a behavior change (zero-valued structs become
    omitted). It skips packages with `+kubebuilder` annotations.
  - **mapsloop**: the `maps.Clone` rewrite preserves nilness of the
    source map, which can differ from a loop that always allocated.
- Rare semantic conflicts between independent fixes surface as
  compilation errors after applying — that is why step 5 builds and
  tests. Resolve by hand; do not re-run `go fix` hoping it heals.

## Report format

```text
go fix report (go1.26.4, module go directive: 1.26)

Pass 1: 12 fixes across 5 files
  any (3), rangeint (4), stringscut (2), newexpr (3)
Pass 2: 1 fix (minmax collapsed to min(max(...)))
Pass 3: clean (go fix -diff exits 0)

Verify: go build ./... OK, go test ./... OK
Review flags: none (omitzero/mapsloop did not fire)
```

If nothing fired, report the toolchain version, the module's `go`
directive, and that the code is already modern for that version — and
mention that raising the `go` directive would unlock more fixers if the
user wants that.

## Analyzer reference

See `references/analyzers.md` for all 22 analyzers with the minimum Go
version each rewrite targets, per-analyzer examples, flags, and how
library authors publish their own migrations with `//go:fix inline`.
