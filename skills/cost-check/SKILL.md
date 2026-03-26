---
name: cost-check
description: >
  Generic cost estimation for IaC projects. Detects the IaC stack
  (Pulumi, Terraform) and compatible cost tool (finfocus, infracost),
  runs cost analysis, flags expensive resources, cost increases, and
  total cost against configurable thresholds. Produces a terminal
  summary and COST_CHECK.md report. Use when checking infrastructure
  costs, reviewing cost impact of changes, or enforcing budget
  thresholds in CI.
compatibility: >
  Requires an IaC project (Pulumi.yaml or *.tf files). Enhanced with
  cost tools: finfocus (Pulumi), infracost (Terraform). Soft-fails
  with recommendations when no compatible tool is installed.
---
<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Cost Check

Detect the IaC stack in the current directory, run a compatible cost
tool, and produce a cost report with flagged items.

**Core principle:** Orchestrate real cost tools — do not parse IaC
files directly or estimate prices manually.

## Step 1: Detect IaC stack

Scan the current directory for IaC project files:

```bash
ls Pulumi.yaml 2>/dev/null && echo "pulumi: detected"
ls *.tf 2>/dev/null && echo "terraform: detected"
```

If no IaC files are found, stop and report:
"No IaC project detected in this directory."

For the full detection table, see `references/tool-matrix.md`.

## Step 2: Detect cost tool

For each detected IaC stack, check if a compatible cost tool is
installed:

```bash
command -v finfocus 2>/dev/null && echo "finfocus: available"
command -v infracost 2>/dev/null && echo "infracost: available"
```

If no compatible tool is found for a detected stack, soft-fail:
report which IaC stack was detected and recommend the appropriate
tool. Do not prescribe install commands — link to the tool's own
documentation. See `references/tool-matrix.md` for recommendations.

If the only available tool is incompatible with the detected stack
(e.g., infracost found but project is Pulumi), treat the same as
no tool found.

## Step 3: Load thresholds

Check for `.cost-check.yml` in the project root. If present, read
threshold overrides. If absent, use defaults from
`references/default-thresholds.md`:

- resource: $100/mo (flag individual resources above)
- increase: $50/mo (flag cost increases above)
- increase_pct: 20% (flag cost increase percentage above)
- total: $1000/mo (flag total cost above)

## Step 4: Read baseline

If a previous `COST_CHECK.md` exists in the project root, read the
total monthly cost from it. This serves as the baseline for delta
comparison. If no previous report exists, skip delta flagging.

## Step 5: Run cost tool

Run the compatible cost tool for each detected IaC stack. See
`references/tool-parsers.md` for per-tool invocation and parsing
instructions.

Capture the full output. Extract into the normalized structure:

- Total projected monthly cost
- Per-stack/workspace breakdown
- Per-resource-type grouping within each stack
- Individual resource costs

## Step 6: Flag items

Apply thresholds to the normalized cost data:

1. **Expensive resources** — flag any resource with monthly cost
   above the resource threshold
2. **Cost increase** — if a baseline exists, flag if the total cost
   increase exceeds the increase threshold OR the increase percentage
   exceeds the increase_pct threshold
3. **Total cost** — flag if total projected cost across all stacks
   exceeds the total threshold

## Step 7: Terminal summary

Print the results immediately:

- IaC stack and cost tool used
- Per-stack total with resource type breakdown
- Flagged items with threshold that triggered the flag
- Delta from baseline (if baseline exists)
- Total across all stacks

## Step 8: Generate COST_CHECK.md

Write the report to the project root using the template in
`references/report-template.md`. Include all sections: summary,
stack breakdown, flagged items, thresholds used, and tool info.

Run markdownlint on the generated file.

## Step 9: Present results

Show the user:

1. Total projected cost across all stacks
2. Number of flagged items by category
3. Top flagged items with costs
4. Delta from previous check (if baseline existed)
5. Ask if they want to adjust thresholds or investigate specific items
