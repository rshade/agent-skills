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
  - [Go development](#go-development)
  - [Workflow](#workflow)
  - [Decision making](#decision-making)
  - [Networking](#networking)
  - [Security & dependencies](#security--dependencies)
  - [Infrastructure cost](#infrastructure-cost)
  - [Project management](#project-management)
- [Installation](#installation)
- [Skill structure](#skill-structure)
- [Contributing](#contributing)
- [License](#license)

## Available skills

### Code quality

#### actionlint

Validate GitHub Actions workflow files for syntax errors, invalid
references, expression mistakes, and security issues. Catches errors
before they waste CI minutes.

**Use when:**

- Creating or modifying GitHub Actions workflows
- Validating CI/CD pipelines before pushing
- Catching workflow syntax errors and security issues

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

#### hadolint

Validate Dockerfiles against best practices for image tagging, package
pinning, cleanup, and shell script issues in RUN commands. Supports
system binary or Docker image fallback.

**Use when:**

- Creating or modifying Dockerfiles
- Reviewing container images for best practice compliance
- Catching Dockerfile anti-patterns before building

#### markdownlint

Validate markdown files against formatting standards. Catches
inconsistent formatting and supports auto-fix mode.

**Use when:**

- Creating or modifying markdown files
- Validating documentation before committing
- Enforcing consistent markdown formatting

#### lint-fix

Detect project linting and validation tools, build an execution
pipeline, and fix all issues to zero errors. Auto-detects Makefile
targets, package.json scripts, Go, Python, .NET, and Rust tooling.
Uses an atomic fix protocol — one issue at a time with re-verification.

**Use when:**

- Fixing linting errors before committing or pushing
- Running a full validation pipeline to zero errors
- Setting up linting on a project for the first time

#### scout

Scout Rule — identify the top 3 highest-impact improvement
opportunities in files you are already touching. Reads entire file
content, not just changed lines. Focuses on pre-existing code quality,
not PR bugs.

**Use when:**

- Preparing a pull request and want to leave the code better
- During code review to suggest quick wins
- After completing a feature to clean up touched files

#### shellcheck

Validate shell scripts for syntax errors, common bugs, quoting issues,
and portability problems. Catches errors before they surface at runtime.

**Use when:**

- Creating or modifying shell scripts
- Validating bash/sh files before committing
- Checking scripts for portability between shells

#### tech-debt

Systematic technical debt analysis and prioritized remediation plan.
Investigates architecture, testing, documentation, and infrastructure
directly. Delegates to scout (code quality), lint-fix (linting),
security-audit (security), dep-upgrade (dependencies), and
design-principles (design principles) for specialized analysis.
Generates a scored TECH_DEBT.md with actionable remediation priorities.

**Use when:**

- Assessing overall project health before a cleanup sprint
- Onboarding to an unfamiliar codebase
- Planning quarterly tech debt remediation
- Justifying cleanup work to stakeholders with concrete scores

#### design-principles

Audit a codebase against well-known software design principles: SOLID,
DRY, YAGNI, KISS, Law of Demeter, Separation of Concerns, Composition
over Inheritance, and the code-relevant 12-Factor subset. Scores
findings by impact and effort, runs an adversarial Red/Blue/White
debate on contested violations, and generates a prioritized
DESIGN_AUDIT.md. Composable — can be invoked standalone or delegated
from `tech-debt`.

**Use when:**

- Reviewing code quality beyond what linters catch
- Assessing design health before a refactor or cleanup sprint
- Onboarding to an unfamiliar codebase to understand design debt
- Running a full tech-debt assessment (called automatically by
  `tech-debt` when available)

### Go development

#### agent-ready-go

Audit and configure Go applications for effective AI agent collaboration.
Ensures structured JSON logging (Zap/ZeroLog/Logrus), machine-readable command
output, thorough golangci-lint config, proper test setup with race detection and
coverage enforcement, structured error handling with meaningful exit codes,
context propagation, and non-interactive CLI design with `--yes` flags.
Includes a ready-to-use `.golangci.yml` and `Makefile`.

**Use when:**

- Setting up a new Go project and want it agent-ready from the start
- Retrofitting an existing Go app so agents can build, test, and debug it
  effectively
- Auditing a Go project against agent-readiness best practices

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

#### tailscale-docker-debug

Diagnose Tailscale connectivity and DNS failures inside Docker
containers. Detects userspace vs kernel mode, DNS resolver conflicts,
TUN interface issues, and multi-tailnet mismatches between host and
container.

**Use when:**

- Tailscale peers connect by IP but MagicDNS names fail inside containers
- Containers unexpectedly fall back to userspace networking
- Running Tailscale on a host and in containers on different tailnets

#### tailscale-subnet-router-debug

Diagnose Tailscale subnet router connectivity failures. Traces the
full route lifecycle: advertisement, approval, client acceptance,
policy routing (table 52), and IP forwarding.

**Use when:**

- Clients can reach Tailscale peers but not devices on advertised subnets
- Subnet routes appear approved but traffic doesn't flow
- `ip route` shows no subnet route (routes are in table 52)
- Docker containers fail to advertise routes via `TS_ROUTES`
- Traffic flows to the target but responses never come back

### Security & dependencies

#### dep-upgrade

Safe systematic dependency upgrade with vulnerability scanning.
Detects project ecosystem (Go, Node.js, Python, Rust, .NET), audits
outdated and vulnerable packages, presents a prioritized upgrade
plan, and executes upgrades one at a time with test verification.

**Use when:**

- Updating dependencies after vulnerability alerts
- Periodic dependency maintenance
- Upgrading a major version with breaking change assessment
- Fixing npm audit / govulncheck / pip-audit findings

#### security-audit

Comprehensive security audit covering OWASP Top 10, secrets detection,
supply chain security, threat modeling (STRIDE/DREAD), and
language-specific vulnerability patterns. Investigates actual code
paths rather than grep-matching keywords. Generates a scored
SECURITY_AUDIT.md with prioritized remediation.

**Use when:**

- Assessing application security before a release or review
- Onboarding to a codebase with security concerns
- Periodic security health checks
- Preparing for a penetration test or compliance audit

### Infrastructure cost

#### cost-check

Generic cost estimation for IaC projects. Detects the IaC stack and
compatible cost tool, runs cost analysis, and flags expensive resources
against configurable thresholds.

**Use when:**

- Checking infrastructure costs in a Pulumi or Terraform project
- Reviewing cost impact of infrastructure changes
- Enforcing budget thresholds in CI pipelines

#### cost-drift

Drift analysis for Pulumi infrastructure costs. Compares actual vs
projected spend, flags drifting resources, and generates likely-cause
explanations with investigation prompts.

**Use when:**

- Investigating why actual cloud spend differs from projections
- Monitoring cost drift trends over time
- Validating that infrastructure changes reduced costs as expected

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
npx skills add rshade/agent-skills -s actionlint
npx skills add rshade/agent-skills -s agent-ready-go
npx skills add rshade/agent-skills -s commitlint
npx skills add rshade/agent-skills -s cost-check
npx skills add rshade/agent-skills -s cost-drift
npx skills add rshade/agent-skills -s decide
npx skills add rshade/agent-skills -s dep-upgrade
npx skills add rshade/agent-skills -s design-principles
npx skills add rshade/agent-skills -s go-nolint-audit
npx skills add rshade/agent-skills -s hadolint
npx skills add rshade/agent-skills -s lint-fix
npx skills add rshade/agent-skills -s markdownlint
npx skills add rshade/agent-skills -s pull-request-msg-with-gh
npx skills add rshade/agent-skills -s roadmap
npx skills add rshade/agent-skills -s scout
npx skills add rshade/agent-skills -s security-audit
npx skills add rshade/agent-skills -s shellcheck
npx skills add rshade/agent-skills -s tailscale-docker-debug
npx skills add rshade/agent-skills -s tailscale-install
npx skills add rshade/agent-skills -s tailscale-subnet-router-debug
npx skills add rshade/agent-skills -s tech-debt
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
