# agent-skills

Picks and Shovels for digging AI. A collection of reusable skills for
AI coding agents, distributed via [skills.sh](https://skills.sh).

Each skill packages a complete tool workflow — prerequisite checks,
config detection, execution, and reporting — so agents handle them
consistently without repeated prompting.

Built on the [Agent Skills](https://agentskills.io) open standard.
Compatible with [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
and [40+ other AI coding agents](https://skills.sh).

## Contents

- [Available skills](#available-skills)
  - [Code quality](#code-quality)
  - [Workflow](#workflow)
  - [Decision making](#decision-making)
  - [Networking](#networking)
  - [Project management](#project-management)
- [Installation](#installation)
- [Skill structure](#skill-structure)
- [Contributing](#contributing)
- [License](#license)

## Available skills

### Code quality

#### commitlint

Validate commit messages against
[Conventional Commits](https://www.conventionalcommits.org/). Catches
malformed messages before they enter your git history.

**Use when:**

- Validating commit messages before committing
- Preparing pull requests
- Enforcing commit message conventions across a team

#### go-nolint-audit

Audit Go `//nolint:` directives for staleness and weak justifications.
Verifies each suppression still triggers, then challenges the top
candidates through adversarial
[Red/Blue/White debate](skills/go-nolint-audit/SKILL.md).

**Use when:**

- Inheriting a Go codebase with accumulated nolint directives
- Periodic cleanup of suppressed lint warnings
- Nolint count is growing and justifications are not being challenged

#### markdownlint

Validate markdown files against formatting standards. Catches
inconsistent formatting and supports auto-fix mode.

**Use when:**

- Creating or modifying markdown files
- Validating documentation before committing
- Enforcing consistent markdown formatting

#### scout

Scout Rule — identify the top 3 highest-impact improvement
opportunities in files you are already touching. Reads entire file
content, not just changed lines. Focuses on pre-existing code quality,
not PR bugs.

**Use when:**

- Preparing a pull request and want to leave the code better
- During code review to suggest quick wins
- After completing a feature to clean up touched files

### Workflow

#### pull-request-msg-with-gh

Generate a structured `PR_MESSAGE.md` from your current work. Detects
related issues via GitHub CLI, writes a PR description with summary,
test plan, and changelog, then validates the output.

**Use when:**

- Preparing a pull request on GitHub
- Generating structured PR descriptions from completed work
- Ensuring PR messages pass commitlint and markdownlint validation

### Decision making

#### decide

Three-agent adversarial debate protocol (Red/Blue/White team) for
strategic decisions. Two advocates steelman opposing positions while
a moderator identifies risks, asks hard questions, and synthesizes a
binding consensus document.

**Use when:**

- Choosing between two or more alternatives (technology, architecture,
  pricing, strategy)
- Evaluating tradeoffs where both sides have legitimate arguments
- Making high-stakes decisions that benefit from structured adversarial
  analysis

### Networking

#### tailscale-install

Install and configure Tailscale across platforms. Detects OS, distro,
and environment (including WSL2 and containers), performs the appropriate
installation, and guides initial connection to a tailnet.

**Use when:**

- Setting up Tailscale on a new machine or server
- Onboarding a headless server to a tailnet with auth keys
- Verifying an existing Tailscale installation

### Project management

#### roadmap

Strategic roadmap management for GitHub repositories. Syncs ROADMAP.md
with GitHub Issues and labels, bootstraps roadmap files from scratch,
and runs brainstorming sessions with boundary checking. Five modes:
sync (default), generate, brainstorm, status, and help.

**Use when:**

- Syncing a ROADMAP.md file with GitHub Issues and milestones
- Bootstrapping project planning files for a new repository
- Brainstorming new features with boundary-aware ideation
- Getting a quick status summary of roadmap progress

## Installation

Requires [Node.js](https://nodejs.org/) (for `npx`).

Install all skills:

```bash
npx skills add rshade/agent-skills
```

Install a specific skill:

```bash
npx skills add rshade/agent-skills -s commitlint
npx skills add rshade/agent-skills -s decide
npx skills add rshade/agent-skills -s go-nolint-audit
npx skills add rshade/agent-skills -s markdownlint
npx skills add rshade/agent-skills -s pull-request-msg-with-gh
npx skills add rshade/agent-skills -s roadmap
npx skills add rshade/agent-skills -s scout
npx skills add rshade/agent-skills -s tailscale-install
```

## Skill structure

Each skill is a directory under `skills/` containing:

- `SKILL.md` — core workflow with YAML frontmatter (`name` and
  `description` fields). The `description` drives when agents activate
  the skill, so it should be specific about both purpose and trigger
  conditions.
- `references/` — optional subdirectory with detailed specs, configs,
  and examples

Skills use progressive disclosure: `SKILL.md` has the concise workflow
an agent needs to act, while `references/` holds the details agents
consult only when needed.

## Contributing

New skills should follow these conventions:

- **Frontmatter**: YAML block with `name` (kebab-case) and `description`
- **Size**: keep `SKILL.md` under 200 lines; move detailed reference
  material to `references/`
- **Generic**: no personal workflow paths, tool-specific coupling, or
  simulated interactive prompts
- **Validation**: run `markdownlint` on all markdown files and
  `commitlint` on commit messages before submitting
- **Pattern**: follow the prerequisite check → run → report workflow.
  Add config detection when the skill wraps a configurable tool
- **Testing**: install the skill locally and verify the workflow runs
  end-to-end against a real project

File issues or ideas in the
[issue tracker](https://github.com/rshade/agent-skills/issues).

## License

[Apache 2.0](LICENSE)
