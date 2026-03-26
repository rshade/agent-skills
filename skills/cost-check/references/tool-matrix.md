<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# IaC Detection and Cost Tool Compatibility

## Detection patterns

Scan the current directory for these files to identify the IaC stack:

| IaC       | Detection file | Detection command                                    |
| --------- | -------------- | ---------------------------------------------------- |
| Pulumi    | `Pulumi.yaml`  | `ls Pulumi.yaml 2>/dev/null`                         |
| Terraform | `*.tf`         | `ls *.tf 2>/dev/null \|\| ls main.tf 2>/dev/null`    |

Multiple IaC stacks in the same directory are supported. Run cost
analysis for each detected stack separately.

## Cost tool compatibility

| IaC       | Compatible Tool | Check command                      |
| --------- | --------------- | ---------------------------------- |
| Pulumi    | finfocus        | `command -v finfocus 2>/dev/null`  |
| Terraform | infracost       | `command -v infracost 2>/dev/null` |

No cross-compatibility. Each tool supports exactly one IaC ecosystem.

## Soft-fail recommendations

When a compatible cost tool is not installed, recommend the right tool
for the detected IaC stack. Do not prescribe install commands — link
to the tool's own documentation or install skill.

| IaC       | Recommended Tool | Reference                                      |
| --------- | ---------------- | ---------------------------------------------- |
| Pulumi    | finfocus         | <https://github.com/rshade/finfocus>           |
| Terraform | infracost        | <https://www.infracost.io/docs/>               |

## Adding a new IaC + tool pair

To add support for a new IaC ecosystem:

1. Add a row to the detection patterns table with the IaC name,
   detection file, and detection command
2. Add a row to the compatibility table with the compatible cost tool
   and check command
3. Add a row to the soft-fail recommendations table
4. Add a parser section in `tool-parsers.md` for the new tool
