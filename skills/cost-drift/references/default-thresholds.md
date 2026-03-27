<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Default Drift Thresholds

These defaults apply when no `drift:` section exists in
`.cost-check.yml`.

## Thresholds

| Dimension       | Default | Unit | Description                          |
| --------------- | ------- | ---- | ------------------------------------ |
| drift_pct       | 10      | %    | Flag resources drifting above this % |
| drift_absolute  | 50      | $/mo | Flag resources drifting above this $ |
| total_drift_pct | 15      | %    | Flag if overall drift exceeds this % |

## Override format

Users override drift thresholds by adding a `drift:` section to
`.cost-check.yml` in the project root:

```yaml
# .cost-check.yml
drift:
  drift_pct: 10
  drift_absolute: 50
  total_drift_pct: 15
```

All fields are optional. Missing fields use the defaults above.
The `drift:` section is separate from the `thresholds:` section
used by cost-check.

## Flagging logic

A resource is flagged as drifting when ANY threshold is exceeded.
Drift is flagged in both directions (overspend and underspend):

1. **Drift percentage** — the absolute value of the resource's
   `percentDrift` field exceeds the `drift_pct` threshold
2. **Drift absolute** — the absolute value of the resource's
   cost delta (extrapolated monthly minus projected) exceeds
   the `drift_absolute` threshold
3. **Total drift** — the overall portfolio drift percentage
   (computed from summary totals) exceeds the `total_drift_pct`
   threshold

## Baseline for trend

The previous `COST_DRIFT.md` in the project root serves as the
baseline for trend comparison. If no previous report exists, trend
display is skipped.
