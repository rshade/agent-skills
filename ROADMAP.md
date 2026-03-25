# agent-skills Strategic Roadmap

## Vision

A curated, trusted collection of AI agent skills that covers the most
common developer workflows. See [CONTEXT.md](CONTEXT.md) for project
boundaries.

**Current state**: 9 skills across 5 categories (Code quality,
Workflow, Decision making, Networking, Project management). Distributed
via [skills.sh](https://skills.sh), compatible with 40+ AI coding
agents.

## Immediate Focus

Skills actively being developed or next in the migration pipeline.

- [ ] #1 Dependency Dashboard [S]

## Near-Term Vision

Skills and infrastructure planned for the next milestone.

*No GitHub issues created yet. Candidates from the migration pipeline:*

- lint-fix — Execute complete linting and validation pipeline
- code-review — Local code review with parallel agents and auto-fix
- verify-fix — Verify code review findings before fixing
- fix-pr — Address PR reviewer comments and failing CI
- diagnose-issue — Systematic issue diagnosis with gated fix
- CI validation pipeline — automated skill validation on PRs

## Future Vision (Long-Term)

Research, exploration, and skills that need scoping decisions.

- create-issue — GitHub issue creation with architect + PM analysis
- dev-issue — Implement GitHub issue with testing and documentation
- tdd-implement — Complete TDD workflow for GitHub issues
- security-audit — Comprehensive security audit (OWASP Top 10)
- dep-upgrade — Safe systematic dependency upgrade with rollback
- test-coverage — Systematic test coverage improvement
- Contribution infrastructure (Tier 3) — CONTRIBUTING.md, PR
  templates, issue templates, co-maintainer onboarding

## Completed Milestones

### 2026-Q1

- [x] commitlint — Validate commit messages against Conventional
  Commits [S]
- [x] markdownlint — Validate markdown formatting standards [S]
- [x] go-nolint-audit — Audit Go nolint directives with adversarial
  debate [M]
- [x] scout — Scout Rule top 3 improvement opportunities [M]
- [x] pull-request-msg-with-gh — Generate structured PR descriptions
  [M]
- [x] decide — Three-agent adversarial debate for strategic
  decisions [L]
- [x] tailscale-install — Cross-platform Tailscale installation [M]
- [x] roadmap — Strategic roadmap management with 5 modes [L]
- [x] Repository setup — README categories, compatibility frontmatter,
  markdownlint config, GitHub topics, test framework [M]

## Boundary Safeguards

From [CONTEXT.md](CONTEXT.md):

- Skills must be agent-agnostic (no Claude Code-specific tool names)
- Skills are markdown instructions, not executable code
- No inter-skill dependencies or shared runtime
- Curated Garden model — maintainer-authored only until Tier 3
- No personal workflow paths or non-portable configuration
