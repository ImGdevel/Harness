---
name: spec-writing
description: Write or update reusable specification documents for this workspace. Use when the user asks to capture architecture, technical design, module behavior, workflow, domain rules, or implementation reference docs in common, framework, or project areas.
---

# Spec Writing

Read this file once before writing the document.

## Goal

Turn implementation knowledge into a reusable, searchable spec document.

## Read Order

Read only the context needed for the target spec:

1. `common/index.md`
2. The nearest target `index.md`
3. Existing related spec documents in the same scope
4. The framework `index.md` when the spec is stack-specific
5. `project/<name>/docs/index.md` when the spec is project-specific

## Save Location

Choose the nearest scope that owns the spec:

- workspace-wide spec: `common/spec/`
- framework spec: `stack/<framework>/spec/`
- project spec: `project/<name>/docs/`

If one project accumulates multiple spec documents, group them under `project/<name>/docs/spec/` and keep `project/<name>/docs/index.md` as the top-level entry point.

## Recommended Structure

Keep only the sections that help future work:

1. background and purpose
2. scope and non-goals
3. current state or assumptions
4. structure, components, or boundaries
5. runtime flow or work sequence
6. interface, configuration, or data contract
7. decisions and trade-offs
8. validation, usage notes, or references

## Diagram Rule

Use Mermaid only when it shortens the explanation.

- for module or architecture docs, prefer `flowchart` or `classDiagram`
- for runtime or request flow docs, prefer `sequenceDiagram`
- use actual package, module, or path names only when they improve precision
- separate implemented state from future ideas instead of mixing them

## Writing Rules

- Write in a practical note style, not a brochure style.
- Prefer short headings, short paragraphs, and direct labels.
- Distinguish current behavior from planned behavior.
- Use exact paths, config keys, and module names when they matter.
- Drop filler sections if they do not help decisions.

## Index Rules

Whenever you add or move a spec document:

- update the nearest `index.md`
- if you create `project/<name>/docs/spec/`, update both `project/<name>/docs/spec/index.md` and `project/<name>/docs/index.md`
- keep index entries short enough to scan without opening the full document
