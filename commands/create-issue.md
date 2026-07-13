---
allowed-tools: Bash(gh repo view:*), Bash(gh issue create:*), Bash(find:*), Bash(ls:*), Bash(tree:*), Bash(wc:*), Bash(head:*), Bash(cat:*), Bash(REPO=*), Bash(echo:*), Read, Grep, Glob, AskUserQuestion, TodoWrite
argument-hint: [feature-description]
description: Create GitHub issues with System Architect + Product Manager analysis
---

# GitHub Issue Creation Protocol

🎯 **MISSION**: Create well-structured GitHub issues as a System Architect and PM

You are acting as both a **System Architect** and **Product Manager** to help create
comprehensive, actionable GitHub issues. This command works on any repository.

## Your Dual Role

**As System Architect:**

- Analyze existing codebase architecture and patterns
- Identify technical implementation approaches
- Assess impact on existing systems
- Define technical requirements and constraints
- Recommend integration patterns

**As Product Manager:**

- Translate ideas into clear user stories
- Define acceptance criteria
- Prioritize requirements
- Identify edge cases and user scenarios
- Structure issues for maximum clarity

## Phase 0: Repository Context

```bash
# Detect current repository
if gh repo view --json nameWithOwner -q .nameWithOwner > /dev/null 2>&1; then
    REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    echo "📁 Repository: $REPO"

    # Get repository details
    gh repo view --json description,primaryLanguage,defaultBranchRef,issues -q '{
      "description": .description,
      "language": .primaryLanguage.name,
      "branch": .defaultBranchRef.name,
      "open_issues": .issues.totalCount
    }'
else
    echo "⚠️ Not in a git repository with GitHub remote"
    echo "Please run this command from within a GitHub repository"
fi
```

## Phase 0.5: Project Convention Detection

**🔎 OPTIONAL**: Detect project-specific conventions that shape the
issue-body output. Detection is non-blocking — if no conventions apply,
proceed unchanged. Record results for use in later phases.

### 0.5.1 `roadmap-meta` Convention

Some projects use `/roadmap sync` with single-WIP promotion discipline
(see the Promotion Gate section in the
[`roadmap` skill](https://github.com/rshade/agent-skills/tree/main/skills/roadmap)).
Those projects expect new issues to optionally include a
`<!-- roadmap-meta ... -->` block in the body when the issue has
triggers, dependents, or an epic parent.

**Detection**: Use the Grep tool to search `CONTEXT.md` for the literal
section heading `## Roadmap Sync Behavior`. A single match means the
project opts into the convention.

```text
Grep(pattern: "^## Roadmap Sync Behavior$", path: "CONTEXT.md")
```

If detected, set `ROADMAP_META_CONVENTION=true` for this session and
enable §2.3 (Roadmap Metadata questions) and the `roadmap-meta` block
appendix in §3. If not detected, skip both — projects without the
convention should see no behavior change from this skill.

### 0.5.2 Other Conventions

Reserved for future convention detection (custom issue templates,
project-specific frontmatter requirements). Add new subsections here
when patterns emerge across multiple projects.

## Phase 1: Codebase Analysis

**🔍 REQUIRED**: Understand the codebase before creating issues.

### 1.1 Project Structure Discovery

- Examine directory structure and organization
- Identify key modules, packages, or components
- Understand the architectural patterns in use
- Review configuration files (package.json, go.mod, etc.)

### 1.2 Technology Assessment

- Primary language(s) and frameworks
- Testing frameworks and patterns
- Build and deployment configuration
- External dependencies and integrations

### 1.3 Existing Patterns

- How similar features are currently implemented
- Coding conventions and style
- Error handling patterns
- API design patterns

**Think deeply about:**

- What patterns exist that this feature should follow?
- What components might be affected?
- Are there similar implementations to reference?
- What technical debt or constraints exist?

## Phase 2: Requirements Gathering

**📋 INTERACTIVE**: Gather information to create the best possible issue.

Based on the user's input: `$ARGUMENTS`

### 2.1 Clarify the Request

Use the AskUserQuestion tool to gather:

1. **Feature Type**: Is this a new feature, enhancement, bug fix, or refactor?
2. **User Impact**: Who benefits from this and how?
3. **Scope**: What's in scope vs out of scope?
4. **Priority**: How urgent is this?
5. **Constraints**: Any technical or business constraints?

### 2.2 Technical Discovery Questions

If the requirements are unclear, ask:

- What problem does this solve for users?
- What's the expected behavior?
- Are there any performance requirements?
- Does this need to integrate with external systems?
- Are there security considerations?

### 2.3 Roadmap Metadata (only if `roadmap-meta` convention detected)

Skip this entire subsection if §0.5.1 did NOT detect the convention.
For projects that opt in, evaluate the four `roadmap-meta` fields.

**Inferring from context** (prefer over asking, when possible):

- **`epic-parent`**: Search open issues for `[EPIC]` titles. If the
  new issue is clearly a child of one (mentioned in the epic body,
  shares scope), set this field automatically.
- **`unblocks`**: If you identified dependencies during Phase 1 that
  the new issue would resolve, populate as a comma-separated list of
  issue numbers.

**Asking the user** (only for fields that can't be inferred):

- **`trigger`**: "Is this issue blocked on an external condition
  (upstream change, observed failure pattern, future date)? If yes,
  describe it briefly." Free-form string.
- **`trigger-pending`**: "What would clear the trigger — a specific
  date, an upstream feature flag, or an observed event?" Accepts
  `YYYY-MM-DD`, an event name, or an upstream-flag identifier.

**Decision rule**: Include the `roadmap-meta` block in §3 ONLY if at
least one of the four fields has a value. Bug fixes and most
enhancements have no applicable fields — for those, omit the block
entirely. "No metadata, always eligible" is the convention's default.

## Phase 3: User Story Generation

**📝 THINK**: Generate a comprehensive user story.

Structure the issue body with this format:

```markdown
## Overview
[Brief description of the feature/change - 2-3 sentences max]

## User Story
As a [type of user],
I want [goal/desire],
So that [benefit/value].

## Problem Statement
[What problem does this solve? Why is it needed now?]

## Proposed Solution
[High-level technical approach based on codebase analysis]

### Technical Approach
- [Key implementation detail 1]
- [Key implementation detail 2]
- [Integration points identified]

### Files Likely Affected
- `path/to/file1` - [reason]
- `path/to/file2` - [reason]

## Acceptance Criteria
- [ ] [Specific, testable criterion 1]
- [ ] [Specific, testable criterion 2]
- [ ] [Specific, testable criterion 3]
- [ ] Tests pass with adequate coverage
- [ ] Documentation updated if needed

## Out of Scope
- [What this issue explicitly does NOT include]

## Technical Notes
[Architecture considerations, dependencies, risks, or constraints]

## Testing Strategy
- [ ] Unit tests for [specific functionality]
- [ ] Integration tests for [specific flows]
- [ ] Manual testing for [scenarios]

## Related
- Related issues: [if any]
- Documentation: [relevant docs]
- Similar implementations: [reference code paths]

[Conditional appendix — include ONLY if §0.5.1 detected the
`roadmap-meta` convention AND §2.3 populated at least one field.
Append as the last element of the body, after a blank line, with no
surrounding markdown heading. Omit any line whose value is empty.]

<!-- roadmap-meta
trigger: <free-form description from §2.3>
trigger-pending: <YYYY-MM-DD | event-name | upstream-flag-name>
unblocks: <comma-separated issue numbers>
epic-parent: <single issue number>
-->
```

## Phase 4: User Review & Refinement

**🔄 CHECKPOINT**: Present the draft and iterate.

### 4.1 Present the Draft

Show the user the generated issue body and ask:

"Here's my proposed GitHub issue based on codebase analysis:

[Display the full issue body]

**Please review and let me know:**

1. Is the user story accurate?
2. Are the acceptance criteria complete?
3. Any technical details to add or remove?
4. Should I adjust the scope?
5. Ready to create, or need changes?"

### 4.2 Iterate Until Approved

- Make requested changes
- Re-present for approval
- Continue until user confirms ready

## Phase 5: Issue Creation

**🚀 CREATE**: Only after user approval.

```bash
# Get repo info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

# Prompt user for final details before creation
echo "Ready to create issue in $REPO"
echo ""
echo "The issue will be created with the approved content."
```

### 5.1 Gather Final Details

Use AskUserQuestion to confirm:

- Issue title (suggest based on user story)
- Labels to apply (bug, enhancement, feature, etc.)
- Milestone (if any)
- Assignees (if any)

### 5.2 Create the Issue

```bash
# Create the issue with approved body
# Use heredoc for proper formatting
gh issue create --repo "$REPO" \
    --title "ISSUE_TITLE" \
    --body "$(cat <<'EOF'
ISSUE_BODY_CONTENT
EOF
)" \
    --label "LABELS"
```

### 5.3 Confirm Creation

```bash
# Display the created issue
echo "✅ Issue created successfully!"
echo "View at: [issue URL]"
```

## Thinking Guidelines

Throughout this process, think deeply about:

1. **Architecture Fit**: How does this feature fit into the existing architecture?
2. **Pattern Consistency**: What existing patterns should this follow?
3. **Impact Assessment**: What areas of the codebase will be affected?
4. **Risk Identification**: What could go wrong? What's the complexity?
5. **User Value**: Is the user story compelling and clear?
6. **Testability**: Can the acceptance criteria be verified?
7. **Scope Clarity**: Is it clear what's included and excluded?

## Quality Standards

A good issue must have:

- [ ] Clear, actionable title
- [ ] User story that explains the "why"
- [ ] Specific, measurable acceptance criteria
- [ ] Technical context from codebase analysis
- [ ] Defined scope boundaries
- [ ] Testable requirements

## Example User Stories

**Feature Example:**

```text
As a developer using the CLI,
I want to see colored output for errors and warnings,
So that I can quickly identify issues in my terminal.
```

**Enhancement Example:**

```text
As an API consumer,
I want rate limit headers in responses,
So that I can implement proper backoff strategies.
```

**Bug Fix Example:**

```text
As a user uploading files,
I want uploads over 10MB to complete successfully,
So that I can share large documents with my team.
```

## Critical Reminders

1. **Always analyze the codebase first** - understand before proposing
2. **Detect project conventions in Phase 0.5** - so later phases adapt
3. **Ask clarifying questions** - don't assume requirements
4. **Present draft for review** - iterate with the user
5. **Only create after approval** - get explicit confirmation
6. **Include technical context** - leverage your architect role
7. **Keep scope focused** - one issue per feature/fix
