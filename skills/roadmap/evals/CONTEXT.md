<!-- Copyright 2025-2026 Richard Shade. Licensed under Apache-2.0. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Project Context

## Core Identity

A CLI tool for managing development workflows.

## Technical Boundaries

- No GUI components
- No cloud hosting — CLI only

## Data Source of Truth

- GitHub Issues for task tracking
- Local config files for user preferences

## Verification Criteria

- All commands must work offline (except GitHub sync)
- CLI output must be parseable by standard Unix tools
