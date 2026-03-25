# agent-skills Context & Boundaries

## Core Architectural Identity

agent-skills is a curated collection of reusable skills for AI coding
agents, distributed via [skills.sh](https://skills.sh). Each skill
packages a complete tool workflow — prerequisite checks, config
detection, execution, and reporting — so agents handle tasks
consistently without repeated prompting. Skills are markdown-based
instructions with YAML frontmatter, not executable code. Built on the
[Agent Skills](https://agentskills.io) open standard, compatible with
Claude Code and 40+ other AI coding agents.

## Technical Boundaries ("Hard No's")

- **Not a registry** — skills.sh is the discovery platform. This repo
  is a curated collection, not a package index.
- **Not executable code** — skills are imperative markdown instructions
  that agents interpret. No compiled binaries, no runtime dependencies
  bundled with skills.
- **Not agent-specific** — skills must work across multiple AI coding
  agents. No Claude Code tool names (`Agent tool`, `WebSearch`,
  `AskUserQuestion`), no agent-specific APIs.
- **Not accepting unsolicited PRs** — Curated Garden model. Tier 1
  (maintainer-authored) now. Proposal issues welcome (Tier 2). Invited
  PRs only after CI gates proven and co-maintainer onboarded (Tier 3,
  target Q4 2026).
- **Not a framework** — skills are standalone. No shared runtime, no
  inter-skill dependencies, no skill orchestration layer.
- **No personal workflow paths** — skills must be generic. No
  hardcoded paths, no tool-specific coupling, no simulated interactive
  prompts.

## Data Source of Truth

- **Skill content**: this repository (`skills/*/SKILL.md` +
  `references/`)
- **Distribution**: skills.sh (indexes repos via install telemetry)
- **Issues and planning**: GitHub Issues on rshade/agent-skills
- **Conventions**: CLAUDE.md in this repository

## Interaction Model

**Inbound** (how users get skills):

- `npx skills add rshade/agent-skills` — install all skills
- `npx skills add rshade/agent-skills -s <name>` — install one skill
- Skills are symlinked into the agent's skill directory

**Outbound** (what skills interact with):

- External tools via CLI commands (`gh`, `markdownlint`, `commitlint`,
  `golangci-lint`, `tailscale`)
- GitHub API via `gh` CLI (issues, labels, milestones)
- The local filesystem (reading project files, writing reports)

## Verification

To check if a proposed feature violates these boundaries, ask:

1. Does it require agent-specific tool names or APIs? → Violation
2. Does it bundle executable code beyond CLI commands? → Violation
3. Does it create dependencies between skills? → Violation
4. Does it assume a specific agent runtime? → Violation
5. Does it require personal paths or non-portable configuration? →
   Violation
6. Is it an unsolicited external contribution? → Check Tier status
