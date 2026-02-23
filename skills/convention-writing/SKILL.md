---
name: convention-writing
description: Write or update enforceable convention documents for this workspace. Use when the user asks to define naming, folder layout, testing rules, documentation rules, Git rules, or operational standards in common, framework, or project scope.
---

# Convention Writing

Read this file once before writing the document.

## Goal

Document rules that future work can actually follow and verify.

## Read Order

Read only the documents that affect the target rule:

1. `common/index.md`
2. The nearest target `index.md`
3. Existing related convention documents in the same scope
4. The framework `index.md` when the rule is stack-specific
5. `project/<name>/docs/index.md` when the rule is project-specific

## Save Location

Choose the nearest scope that owns the rule:

- shared workspace rule: `common/convention/`
- framework rule: `stack/<framework>/convention/`
- project rule: `project/<name>/docs/`

If one project accumulates multiple rule documents, group them under `project/<name>/docs/convention/` and keep `project/<name>/docs/index.md` as the entry point.

For project-specific rules, prefer `project/<name>/docs/convention/` instead of mixing them into other doc folders.

## Default Structure

Prefer this shape:

1. purpose and scope
2. applies to
3. required rules
4. recommended rules
5. forbidden patterns
6. examples and path conventions
7. exceptions or override order
8. related docs

## Writing Rules

- State the default first, then the exception.
- Use one rule per bullet when possible.
- Separate `must`, `should`, and `do not` ideas clearly.
- Include concrete examples, paths, or filenames.
- Define override order when common, framework, and project rules can conflict.
- Avoid vague phrases such as `적절히`, `상황에 따라`, `필요 시` unless you also give criteria.

## Maintenance Rules

- If a convention change affects a template or a skill, update the related file in the same task when practical.
- When a framework or project rule overrides a common rule, say so explicitly instead of implying it.
- Remove stale examples when they no longer match the current structure.

## Index Rules

Whenever you add or move a convention document:

- update the nearest `index.md`
- if you create `project/<name>/docs/convention/`, update both that folder's `index.md` and `project/<name>/docs/index.md`
- keep the index entry short and operational
