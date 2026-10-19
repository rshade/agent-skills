---
name: cost-drift
description: >
  Moved to rshade/finfocus (agent-skills/cost-drift). This directory is a
  pointer only. The moved skill compares actual and projected spend for a Pulumi
  stack with the FinFocus CLI, flags drifting resources, explains likely causes,
  and writes COST_DRIFT.md. Use it when investigating cost overruns or watching
  spend drift.
---
<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Cost Drift (moved)

This skill moved to the FinFocus core repository:
<https://github.com/rshade/finfocus/tree/main/agent-skills/cost-drift>

The copy here is a stub and is no longer maintained. The moved skill compares
actual and projected spend from the FinFocus CLI's JSON output, flags drifting
resources against the `drift:` section of `.cost-check.yml`, and writes
`COST_DRIFT.md`. It checks the installed CLI version and names what to do when
the CLI, a plugin, credentials, or a plan is missing.

## What to tell the user

Show the user the install command for the moved skill. Do not run a cost tool
from this stub.

```bash
npx skills add rshade/finfocus -s cost-drift
```

The same install with the `skills` installer version pinned:

```bash
npx -y skills@1.7.0 add https://github.com/rshade/finfocus/tree/main/agent-skills --skill cost-drift
```

## What changed

- The skill is FinFocus-first. It no longer selects another cost tool.
- Terraform projects are priced from a state file only.
- Thresholds still live in `.cost-check.yml`. The existing keys keep their
  names and defaults.
