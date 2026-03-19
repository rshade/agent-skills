# agent-skills

Picks and Shovels for digging AI. A collection of reusable skills for
AI coding agents, distributed via [skills.sh](https://skills.sh).

## Available skills

### commitlint

Validate commit messages against the
[Conventional Commits](https://www.conventionalcommits.org/) specification.
Auto-detects and installs commitlint CLI if missing. Checks project config
or falls back to sensible defaults.

**Use when:**

- Validating commit messages before committing
- Preparing pull requests
- Enforcing commit message conventions across a team

### markdownlint

Validate markdown files against formatting standards. Auto-detects and
installs markdownlint-cli if missing. Checks project config or falls back
to sensible defaults. Supports auto-fix mode.

**Use when:**

- Creating or modifying markdown files
- Validating documentation before committing
- Enforcing consistent markdown formatting

## Installation

```bash
npx skills add rshade/agent-skills
```

To install a specific skill:

```bash
npx skills add rshade/agent-skills -s commitlint
npx skills add rshade/agent-skills -s markdownlint
```

## Skill structure

Each skill is a directory under `skills/` containing:

- `SKILL.md` — core workflow with YAML frontmatter (`name` and
  `description` fields)
- `references/` — optional subdirectory with detailed specs, configs, and
  examples

Skills use progressive disclosure: `SKILL.md` has the concise workflow an
agent needs to act, while `references/` holds the details agents consult
only when needed.

## Contributing

New skills should follow these conventions:

- **Frontmatter**: YAML block with `name` (kebab-case) and `description`
- **Size**: keep `SKILL.md` under 200 lines; move detailed reference
  material to `references/`
- **Generic**: no personal workflow paths, tool-specific coupling, or
  simulated interactive prompts
- **Validation**: run `markdownlint` on all markdown files and
  `commitlint` on commit messages before submitting
- **Pattern**: follow the install check → config detection → run → report
  workflow used by existing skills

## License

[Apache 2.0](LICENSE)
