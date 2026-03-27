<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# COST_DRIFT.md Report Template

Use this structure when generating `COST_DRIFT.md`.

## Template

````markdown
# Cost Drift Report

Generated: YYYY-MM-DD
IaC: Pulumi
Tool: finfocus vX.Y.Z
Stack: [stack name]
Period: YYYY-MM-DD to YYYY-MM-DD

## Summary

| Metric                | Value        |
| --------------------- | ------------ |
| Total actual (MTD)    | $X,XXX.XX   |
| Total projected       | $X,XXX.XX   |
| Overall drift         | +/- X.X%    |
| Drifting resources    | N flagged    |
| Total resources       | N            |
| Trend                 | [better/worse/stable vs last check] |

## Drifting Resources

### [Resource Name] ([Resource Type])

| Metric    | Value      |
| --------- | ---------- |
| Actual    | $XXX.XX/mo |
| Projected | $XXX.XX/mo |
| Delta     | +/- $XX.XX |
| Drift     | +/- X.X%   |

**Likely cause:** [explanation from drift-explanations.md]

**Investigate:** [actionable next step]

[Repeat for each flagged resource, ordered by absolute drift %]

## Non-Drifting Resources

| Resource    | Type             | Actual    | Projected | Drift |
| ----------- | ---------------- | --------- | --------- | ----- |
| [name]      | [type]           | $XXX.XX   | $XXX.XX   | X.X%  |

## Thresholds Used

| Dimension       | Value |
| --------------- | ----- |
| Drift %         | XX%   |
| Drift absolute  | $XX   |
| Total drift %   | XX%   |

Source: [.cost-check.yml drift: section / default thresholds]

## Trend

| Metric         | Previous Check | Current | Direction |
| -------------- | -------------- | ------- | --------- |
| Overall drift  | X.X%           | X.X%    | [better/worse/stable] |
| Total actual   | $X,XXX.XX      | $X,XXX.XX | [+/- $XX.XX] |

[Omit this section if no previous COST_DRIFT.md exists]

## Tool Information

- **Tool**: finfocus [version]
- **IaC stack**: Pulumi
- **Stack**: [stack name]
- **Period**: [start date] to [end date]
- **Caveats**: [any limitations — e.g., MTD data extrapolated to
  monthly, actual costs may have 24-48hr delay]
````

## Report quality checklist

Before writing the report, verify:

- Every flagged resource has actual, projected, delta, and drift %
- Drift explanations match the resource type and drift direction
- Cost values are formatted consistently (two decimal places)
- The trend section uses the previous COST_DRIFT.md as baseline
- The thresholds section reflects actual thresholds used
- Non-drifting resources are included for completeness
- Tool version is captured from `finfocus --version`
