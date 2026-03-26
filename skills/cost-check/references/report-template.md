<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# COST_CHECK.md Report Template

Use this structure when generating `COST_CHECK.md`.

## Template

````markdown
# Cost Check Report

Generated: YYYY-MM-DD
IaC: [Pulumi / Terraform]
Tool: [finfocus vX.Y.Z / infracost vX.Y.Z]

## Summary

| Metric              | Value     |
| ------------------- | --------- |
| Total monthly cost  | $X,XXX.XX |
| Stacks analyzed     | N         |
| Resources costed    | N         |
| Flagged items       | N         |
| Cost change         | +/- $X.XX (X%) |

## Stack Breakdown

### [Stack/Workspace Name]

**Total: $X,XXX.XX/mo**

#### By Resource Type

| Resource Type    | Count | Monthly Cost |
| ---------------- | ----- | ------------ |
| aws:ec2:Instance | N     | $X,XXX.XX   |
| aws:rds:Instance | N     | $X,XXX.XX   |
| aws:s3:Bucket    | N     | $X,XXX.XX   |

#### Individual Resources

| Resource Name | Type             | Monthly Cost |
| ------------- | ---------------- | ------------ |
| prod-api-xl   | aws:ec2:Instance | $XXX.XX     |
| main-db        | aws:rds:Instance | $XXX.XX     |

[Repeat for each stack/workspace]

## Flagged Items

### Expensive Resources

Resources exceeding the per-resource threshold:

| Resource    | Type             | Monthly Cost | Threshold |
| ----------- | ---------------- | ------------ | --------- |
| [name]      | [type]           | $XXX.XX     | $XXX.XX   |

### Cost Increases

Changes from previous baseline:

| Metric         | Previous  | Current   | Change         |
| -------------- | --------- | --------- | -------------- |
| Total cost     | $X,XXX.XX | $X,XXX.XX | +$XXX.XX (X%) |

### Total Cost Warning

[Include only if total exceeds threshold]

Total projected cost ($X,XXX.XX/mo) exceeds threshold ($X,XXX.XX/mo).

## Thresholds Used

| Dimension    | Value  |
| ------------ | ------ |
| Resource     | $XXX/mo |
| Increase     | $XXX/mo |
| Increase %   | XX%    |
| Total        | $X,XXX/mo |

Source: [.cost-check.yml / default thresholds]

## Tool Information

- **Tool**: [name] [version]
- **IaC stack**: [Pulumi / Terraform]
- **Stacks analyzed**: [list of stack/workspace names]
- **Caveats**: [any limitations — e.g., spot pricing not included,
  data transfer estimates are approximate]
````

## Report quality checklist

Before writing the report, verify:

- Every flagged item has the specific resource name and type
- Cost values are formatted consistently (two decimal places)
- The delta comparison uses the previous COST_CHECK.md as baseline
- The thresholds section reflects actual thresholds used (overrides
  or defaults)
- Tool version is captured from the tool's version command
