---
name: feature-planning
description: Create concise implementation plans for this harness. Use when the user asks to plan a feature, break work into phases, organize tasks, write a roadmap, or save a plan document before implementation. This skill produces short phase-based plans with scope, validation, risks, and next actions, aligned to the workspace structure.
---

# Feature Planning

Read this entire file once before drafting the plan.

## Goal

Turn a vague request into a short, execution-ready plan that fits this workspace.

## Read Order

Before planning, read only the context that matters:

1. `common/index.md`
2. `common/convention/project-artifact-conventions.md`
3. `common/templates/project-plan-template.md`
4. `stack/index.md`
5. The target framework `index.md`
6. If planning for a real project, `project/<name>/docs/index.md`

Do not load broad unrelated documentation just to create a plan.

## Scope Selection

Choose the plan scope first:

- `common`: workspace-wide rules, shared conventions, shared automation
- `framework`: `stack/spring/`, `stack/spring-webflux/`, `stack/fastapi/`, `stack/react/` level work
- `project`: a project container inside `project/<name>/` with a real repository in `project/<name>/<repo-name>/`

Save the plan in the nearest relevant documentation area, not at the workspace root.
If the scope is `project`, save the plan under `project/<name>/plan/`.

## Planning Rules

- Prefer 2-5 phases.
- Each phase should end in a verifiable state.
- Keep each phase small enough to complete in a focused work session.
- Use concrete tasks with likely file paths or modules when known.
- Include only meaningful risks, dependencies, and rollback notes.
- If a section does not add decision value, omit it.

## Persistence Rules

- When the user asks for a plan, do not leave it only in chat if it should be retained.
- For real project work, persist the plan as a Markdown file in the project `plan/` directory.
- Use the filename format `YYYY-MM-DD_HHMM_<slug>.md`.
- If the plan is a revision or continuation of the same topic, reuse the same base filename and add `_v2`, `_v3`, and so on.
- Keep old plan versions as history; do not overwrite silently.

## Quality Gate Rules

Use quality gates that match the real repository.

- Reuse actual project commands when they exist.
- Do not force generic coverage numbers or TDD rules if the repository does not work that way.
- If tests, lint, type checks, or build commands are unknown, say so explicitly instead of inventing them.
- Keep validation short and specific.

## Output Shape

Default to this structure:

1. Goal and success criteria
2. Scope and relevant context
3. Phase breakdown
4. Validation approach
5. Risks or blockers
6. Next action

For larger work, add:

- decision log
- dependency notes
- rollback notes

## Phase Design

For each phase, include:

- phase goal
- concrete deliverable
- ordered task list
- validation checks
- blockers or assumptions if they matter

Do not repeat the same generic checklist under every phase unless it changes decisions.

## Plan Style

- Write short, operational sentences.
- Prefer checklists over long prose.
- Keep the plan editable by a human during execution.
- Avoid filler sections such as stakeholder notifications unless the user explicitly needs them.

## Template Usage

Use `common/templates/project-plan-template.md` as the starting point when the user wants a saved plan document.
Trim unused sections instead of filling every placeholder.
