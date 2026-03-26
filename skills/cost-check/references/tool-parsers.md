<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Cost Tool Invocation and Output Parsing

Per-tool instructions for running cost analysis and extracting
normalized cost data.

## finfocus (Pulumi)

### finfocus Invocation

Do not hardcode finfocus subcommands or flags. Instead, read help
output to determine the correct invocation:

```bash
finfocus --help 2>&1
finfocus cost --help 2>&1
```

Look for a subcommand that produces projected or estimated cost
output (e.g., `cost projected`, `cost estimate`, `overview`). Run
the appropriate command and capture output.

### finfocus Parsing

Extract from finfocus output:

- **Total monthly cost** — look for a total or summary line
- **Per-stack breakdown** — finfocus operates per Pulumi stack; if
  multiple stacks exist, run once per stack
- **Per-resource-type grouping** — group resources by their cloud
  resource type (e.g., `aws:ec2:Instance`, `aws:s3:Bucket`)
- **Individual resource costs** — each resource with its name and
  monthly cost

If finfocus produces JSON output (check for `--output json` or
`-o json` flag), prefer JSON parsing over text parsing for
reliability.

## infracost (Terraform)

### infracost Invocation

```bash
infracost breakdown --path . --format json 2>&1
```

The `--format json` flag produces structured output that is easier
to parse than the default table format.

### infracost Parsing

infracost JSON output structure:

```json
{
  "totalMonthlyCost": "842.50",
  "projects": [
    {
      "name": "project-name",
      "breakdown": {
        "totalMonthlyCost": "842.50",
        "resources": [
          {
            "name": "aws_instance.web",
            "resourceType": "aws_instance",
            "monthlyCost": "450.00",
            "subresources": [...]
          }
        ]
      }
    }
  ]
}
```

Extract:

- **Total monthly cost** — top-level `totalMonthlyCost`
- **Per-project breakdown** — iterate `projects` array (Terraform
  workspaces map to projects)
- **Per-resource-type grouping** — group by `resourceType` field
- **Individual resource costs** — each entry in `resources` array
  with `name` and `monthlyCost`

## Adding a new tool parser

To add support for a new cost tool:

1. Add a section with the tool name and IaC ecosystem
2. Document the invocation command (prefer JSON output if available)
3. Document the output structure and extraction logic
4. Map the tool's output fields to the normalized structure:
   total, per-stack/project, per-resource-type, individual resources
