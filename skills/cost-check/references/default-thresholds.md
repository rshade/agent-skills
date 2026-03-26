<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Default Flagging Thresholds

These defaults apply when no `.cost-check.yml` exists in the project
root.

## Thresholds

| Dimension        | Default | Unit  | Description                          |
| ---------------- | ------- | ----- | ------------------------------------ |
| resource         | 100     | $/mo  | Flag individual resources above this |
| increase         | 50      | $/mo  | Flag cost increases above this       |
| increase_pct     | 20      | %     | Flag cost increases above this %     |
| total            | 1000    | $/mo  | Flag total cost above this           |

## Override format

Users override thresholds by creating `.cost-check.yml` in the project
root:

```yaml
thresholds:
  resource: 100
  increase: 50
  increase_pct: 20
  total: 1000
```

All fields are optional. Missing fields use the defaults above.

## Flagging logic

A resource or cost is flagged when ANY threshold is exceeded:

1. **Expensive resource** — a single resource's monthly cost exceeds
   the `resource` threshold
2. **Cost increase (absolute)** — the difference between current total
   and previous baseline exceeds the `increase` threshold
3. **Cost increase (percentage)** — the percentage increase from
   previous baseline exceeds the `increase_pct` threshold
4. **Total cost** — the total projected cost across all stacks exceeds
   the `total` threshold

The previous `COST_CHECK.md` in the project root serves as the
baseline for delta comparison. If no previous report exists, cost
increase flags are skipped.
