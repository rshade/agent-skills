---
name: cost-check
description: >
  Moved to rshade/finfocus (agent-skills/cost-check). This directory is a
  pointer only. The moved skill estimates the monthly cost of a Pulumi or
  Terraform project with the FinFocus CLI, flags expensive resources, cost
  increases, and total cost against thresholds, and writes COST_CHECK.md. Use it
  when checking infrastructure costs or gating CI on cost.
---
<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Cost Check (moved)

This skill moved to the FinFocus core repository:
<https://github.com/rshade/finfocus/tree/main/agent-skills/cost-check>

The copy here is a stub and is no longer maintained. The moved skill estimates
infrastructure cost from the FinFocus CLI's JSON output, flags resources and
totals against `.cost-check.yml` thresholds, and writes `COST_CHECK.md`. It
checks the installed CLI version and names what to do when the CLI, a plugin,
credentials, or a plan is missing.

## What to tell the user

Show the user the install command for the moved skill. Do not run a cost tool
from this stub.

```bash
npx skills add rshade/finfocus -s cost-check
```

The same install with the `skills` installer version pinned:

```bash
npx -y skills@1.7.0 add https://github.com/rshade/finfocus/tree/main/agent-skills --skill cost-check
```

## What changed

- The skill is FinFocus-first. It no longer selects another cost tool.
- Terraform projects are priced from a state file only.
- Thresholds still live in `.cost-check.yml`. The existing keys keep their
  names and defaults.
