# CLAUDE.md

This file provides guidance to Claude Code when working with code in this
repository.

## Project overview

**agent-skills** is a collection of reusable skills for AI coding agents,
distributed via [skills.sh](https://skills.sh). Licensed under Apache 2.0.

## Repository structure

```text
skills/<name>/SKILL.md              — core workflow (<200 lines)
skills/<name>/references/           — detailed specs, configs, examples
```

## Skill format

Every skill must have a `SKILL.md` with YAML frontmatter:

```yaml
---
name: skill-name
description: >
  What this skill does and when to use it.
---
```

- `name`: kebab-case identifier
- `description`: concise, specific — used for discovery and relevance
  matching

## Skill conventions

- **Progressive disclosure**: `SKILL.md` has the concise workflow an agent
  needs to act. Detailed reference material (format specs, rule lists,
  default configs) goes in `references/`.
- **Generic**: no personal workflow paths, tool-specific coupling, or
  simulated interactive prompts. Use imperative instructions.
- **Workflow pattern**: install check → config detection → run → report.
  Fail hard on missing tools — do not silently skip validation.
- **Size target**: keep `SKILL.md` under 200 lines.

## Adding a new skill

When adding a new skill to the repository:

1. Create `skills/<name>/SKILL.md` following the format and conventions
   above.
2. Add a `references/` subdirectory if the skill needs detailed specs or
   configs.
3. Update `README.md` — add the skill to the "Available skills" section
   with a description and "Use when" scenarios.
4. Validate all new and modified markdown files before committing.

## Validation

- Run `markdownlint` on all created or modified markdown files.
- Run `commitlint` on commit messages. Use the default config from
  `skills/commitlint/references/conventional-commits.md` if the project
  has no commitlint config.
- Ensure all files end with a newline.
