---
name: cost-drift
description: >
  Drift analysis for Pulumi infrastructure costs. Runs finfocus to
  compare actual vs projected spend, flags drifting resources against
  configurable thresholds, generates likely-cause explanations with
  investigation prompts, and tracks drift trends over time. Produces
  a terminal summary and COST_DRIFT.md report. Use when investigating
  cost overruns, validating projections against reality, or monitoring
  spend drift in CI.
compatibility: >
  Requires a Pulumi project (Pulumi.yaml) and finfocus installed.
  Soft-fails with recommendation when finfocus is not available.
  Terraform drift support is planned as future work.
---
<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Cost Drift

Compare actual vs projected infrastructure costs, flag drifting
resources, and explain why drift is happening.

**Core principle:** Wrap finfocus JSON output — do not compute drift
independently or query cloud billing APIs directly.

## Step 1: Detect Pulumi project

Scan the current directory for a Pulumi project:

```bash
ls Pulumi.yaml 2>/dev/null && echo "pulumi: detected"
```

If no `Pulumi.yaml` is found, stop and report:
"No Pulumi project detected — cost-drift requires a Pulumi project
with finfocus."

## Step 2: Detect finfocus

Check if finfocus is installed:

```bash
command -v finfocus 2>/dev/null && echo "finfocus: available"
```

If finfocus is not found, soft-fail: report that the Pulumi project
was detected but finfocus is needed for drift analysis. Link to
<https://github.com/rshade/finfocus> for installation. Do not
prescribe install commands.

## Step 3: Load thresholds

Check for `.cost-check.yml` in the project root. If present, read
the `drift:` section for threshold overrides. If absent or no
`drift:` section exists, use defaults from
`references/default-thresholds.md`:

- drift_pct: 10% (flag resources drifting above)
- drift_absolute: $50/mo (flag resources drifting above)
- total_drift_pct: 15% (flag if overall drift exceeds)

## Step 4: Read baseline

If a previous `COST_DRIFT.md` exists in the project root, read the
overall drift percentage and total actual spend. This serves as the
baseline for trend comparison. If no previous report exists, skip
trend display.

## Step 5: Run finfocus

Run finfocus with JSON output:

```bash
finfocus overview --output json --yes
```

Parse the JSON output. Key fields per resource in the `resources`
array:

- `costDrift.extrapolatedMonthly` — extrapolated monthly actual
- `costDrift.projected` — projected monthly cost
- `costDrift.delta` — extrapolated minus projected
- `costDrift.percentDrift` — drift as percentage
- `costDrift.isWarning` — finfocus built-in warning flag
- `actualCost.mtdCost` — month-to-date actual spend
- `projectedCost.monthlyCost` — projected monthly cost

From `summary`:

- `totalActualMTD` — total month-to-date actual
- `projectedMonthly` — total projected monthly

See `references/drift-explanations.md` for per-resource-type
context.

## Step 6: Flag drifting resources

Apply thresholds to each resource:

1. **Drift percentage** — flag if absolute value of
   `costDrift.percentDrift` exceeds the `drift_pct` threshold
2. **Drift absolute** — flag if absolute value of
   `costDrift.delta` exceeds the `drift_absolute` threshold
3. **Total drift** — flag if overall portfolio drift percentage
   exceeds the `total_drift_pct` threshold

Flag in both directions — overspend and underspend are both signals.

## Step 7: Generate explanations

For each flagged resource, look up its resource type in
`references/drift-explanations.md`. Determine drift direction
(overspend if delta > 0, underspend if delta < 0) and select the
matching explanation. Each explanation has:

- A **likely cause** hint
- An **investigation prompt** with an actionable next step

If the resource type is not in the reference file, use the fallback
explanations.

## Step 8: Terminal summary

Print the results immediately:

- Overall actual vs projected with drift percentage
- Trend from previous check (if baseline exists)
- Each flagged resource with actual, projected, delta, drift%,
  likely cause, and investigation prompt
- Total flagged resource count

## Step 9: Generate COST_DRIFT.md

Write the report to the project root using the template in
`references/report-template.md`. Include all sections: summary,
drifting resources with explanations, non-drifting resources,
thresholds used, trend, and tool info.

Run markdownlint on the generated file.

## Step 10: Present results

Show the user:

1. Overall drift percentage and direction
2. Trend vs previous check (better, worse, or stable)
3. Number of drifting resources
4. Top drifting resources with explanations
5. Ask if they want to investigate specific resources or adjust
   thresholds
