<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
# go fix analyzer reference

All analyzers registered in Go 1.26's `go tool fix`, from
`go tool fix help` and `go tool fix help <name>`. All run by default;
select one with `go fix -NAME ./...` or exclude with `-NAME=false`.

Fixes only apply when the module's `go.mod` directive (or a file's
`//go:build go1.XX` constraint) meets the minimum version of the feature
being introduced.

## Analyzer table

| Analyzer | Rewrite | Target feature since |
| --- | --- | --- |
| `any` | `interface{}` → `any` | Go 1.18 |
| `buildtag` | check `//go:build` / `// +build` consistency | — |
| `fmtappendf` | `[]byte(fmt.Sprintf(...))` → `fmt.Appendf(nil, ...)` | Go 1.19 |
| `forvar` | remove redundant `x := x` in range loops | Go 1.22 |
| `hostport` | `fmt.Sprintf("%s:%d", host, port)` for net.Dial → `net.JoinHostPort` | — |
| `inline` | apply `//go:fix inline` directives (API migrations) | directive-driven |
| `mapsloop` | map copy loops → `maps.Copy` / `Insert` / `Clone` / `Collect` | Go 1.23 |
| `minmax` | clamp-style if/else → `min` / `max` builtins | Go 1.21 |
| `newexpr` | pointer-helper funcs and calls → `new(expr)` | Go 1.26 |
| `omitzero` | `omitempty` on struct-typed JSON fields → `omitzero` | Go 1.24 |
| `plusbuild` | remove obsolete `//+build` lines beside `//go:build` | Go 1.18 |
| `rangeint` | `for i := 0; i < n; i++` → `for i := range n` | Go 1.22 |
| `reflecttypefor` | `reflect.TypeOf(x)` → `reflect.TypeFor[T]()` | Go 1.22 |
| `slicescontains` | existence loops → `slices.Contains` / `ContainsFunc` | Go 1.21 |
| `slicessort` | `sort.Slice` on basic types → `slices.Sort` | Go 1.21 |
| `stditerators` | `Len`/`At` index loops → `range x.All()` iterators | Go 1.23 |
| `stringsbuilder` | repeated `s += ...` in loops → `strings.Builder` | Go 1.10 |
| `stringscut` | `strings.Index` + slicing → `strings.Cut` / `Contains` | Go 1.18 |
| `stringscutprefix` | `HasPrefix`+`TrimPrefix` → `CutPrefix` (also suffix) | Go 1.20 |
| `stringsseq` | `range strings.Split(...)` → `SplitSeq` / `FieldsSeq` | Go 1.24 |
| `testingcontext` | `context.WithCancel` + `defer cancel()` in tests → `t.Context()` | Go 1.24 |
| `waitgroup` | `wg.Add(1)` / `go` / `defer wg.Done()` → `wg.Go(func(){...})` | Go 1.25 |

## Behavior notes worth reviewing

- **omitzero** — an explicit behavior change: `omitempty` on a
  struct-typed field does nothing, while `omitzero` omits zero-valued
  structs. Skips packages containing `+kubebuilder` annotations because
  kubebuilder assigns its own meaning to these tags.
- **mapsloop** — the `maps.Clone` rewrite preserves nilness of the
  source map; a hand-written loop that always allocated a map behaves
  differently for nil input.
- **minmax** — never fires on floating-point operands because `min`/`max`
  NaN semantics can differ from the original if/else. Also requires the
  `x := f()` declaration-then-clamp shape; it does not rewrite clamps on
  function parameters.
- **rangeint** — only fires when the loop variable is not modified in the
  body and the limit expression is not modified in the loop, since
  `for range n` evaluates `n` once.
- **slicescontains** — if the target-element expression has side effects,
  they occur once after the rewrite instead of once per element.
- **stringsbuilder** — requires all pre-final references to be `+=`, at
  least one inside a loop, and the variable to be a local (not a global
  or parameter).
- **stditerators** — only rewrites loops over well-known standard library
  types that offer an `All()` iterator.

## Useful details observed in practice

- `go fix -diff ./...` prints a unified diff and **exits 1 when the diff
  is non-empty**, 0 when clean — usable directly as a CI check.
- `newexpr` does two things in one pass: rewrites the helper body to
  `new(x)` and marks it `//go:fix inline`, *and* rewrites existing call
  sites (`newInt(42)` → `new(42)`). The directive lets the `inline`
  analyzer clean up any remaining callers, including in other modules
  that depend on yours.
- Synergy is real: `minmax` needs two passes to turn a two-branch clamp
  into `min(max(f(), 0), 100)`. Loop until `-diff` exits 0.
- Generated files carrying the standard
  `// Code generated ... DO NOT EDIT.` header are never modified.
- Unused imports left behind by fixes are removed in a final cleanup
  pass, so applied fixes still compile.

## Flags reference

From `go help fix` and `go tool fix help`:

```text
go fix [build flags] [-fixtool prog] [fix flags] [packages]

-diff            print fixes as a unified diff instead of applying;
                 exit non-zero if the diff is not empty
-fixtool=prog    use an alternative analysis tool with extra fixers
                 (analogous to go vet -vettool)
-NAME            run only analyzer NAME (repeatable)
-NAME=false      run all analyzers except NAME
-json            emit JSON output (go tool fix)
-c int           show offending line with N lines of context

Build flags such as -C, -tags, -n, -x, -v are accepted and control
package resolution, e.g. GOOS/GOARCH env vars select the platform.
```

Per-analyzer flags exist too, e.g.
`-inline.allow_binding_decl=false` disables inlinings that would need a
`var params = args` binding declaration.

For full text on any analyzer: `go tool fix help <name>`.

## Publishing migrations with //go:fix inline

Library authors can ship their own migrations instead of hoping users
read the changelog. Express the old API in terms of the new one and mark
it:

```go
// Deprecated: use Pow(x, 2).
//go:fix inline
func Square(x int) int { return Pow(x, 2) }
```

Every caller running `go fix` gets `Square(x)` replaced by `Pow(x, 2)`.
This also works for moving to a new import path or major version:

```go
package pkg

import pkg2 "example.com/pkg/v2"

//go:fix inline
func F() { pkg2.F(nil) }
```

Constants work when they alias another named constant, and the directive
may sit on a single const, one entry in a group, or a whole group:

```go
//go:fix inline
const Ptr = Pointer
```

Type aliases can be marked the same way to migrate type references.

The inliner never changes behavior: it preserves argument evaluation
order (inserting `var params = args` bindings when needed) and refuses
rewrites it cannot prove safe, such as calls under `defer`. Directives
are defined by <https://go.dev/issue/32816>; background reading:
<https://go.dev/blog/gofix> and <https://go.dev/blog/inliner>.
