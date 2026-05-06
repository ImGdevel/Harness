---
name: workspace-gatekeeper
description: Align task context before editing this harness or a nested project. Use when starting a new task, deciding whether work belongs in common/stack/project, choosing which docs to read first, or confirming whether Git work should happen in the workspace repo or a real project repo.
---

# Workspace Gatekeeper

Read this file once at the start of the task.

## Goal

Pick the correct document scope and Git scope before making changes.

## Read Order

Read only the minimum context needed:

1. `README.md`
2. `AGENTS.md`
3. `common/index.md`
4. `stack/index.md`
5. The target framework `index.md` when framework context matters
6. `project/index.md` when the work touches a real project
7. `project/registry.yaml` when a project name or alias is known
8. The actual project `docs/index.md` after resolving `repo_path`

Do not load unrelated framework or project docs just to start work.

When reading any directory's `index.md`, also list its actual contents (`Glob` or directory listing) so unindexed docs are not silently skipped. See `common/convention/anti-drift-guards.md`.

## Scope Decision

Choose one primary scope first:

- `common`: workspace-wide rules, templates, shared workflows
- `framework`: one stack under `stack/<framework>/`
- `project`: one registered external project repository

If the task spans multiple scopes, start from the narrowest scope that owns the change and pull shared context only when needed.

## Git Context Decision

Confirm which repository you are operating on:

- Workspace repo: root harness files such as `skills/`, `common/`, `stack/`, `scripts/`
- Real project repo: the `repo_path` resolved from `project/registry.yaml`

The harness `project/` directory is registry metadata only, not a clone location.

## Handoff Rules

After scope alignment, hand off to the matching skill when needed:

- plan work: `feature-planning`
- Git work: `git-workflow`
- troubleshooting records: `troubleshooting-writing`
- spec docs: `spec-writing`
- convention docs: `convention-writing`

## Drift Rules

If the actual structure or workflow differs from the docs:

- update the nearest `index.md` or rule document in the same task
- prefer fixing the narrower scoped document first
- avoid leaving a known mismatch for a later turn when the correction is small

## Output Expectations

When this skill is used, surface these decisions before deeper work:

- selected scope
- selected repository path
- documents that were actually read
- next skill or next concrete action
