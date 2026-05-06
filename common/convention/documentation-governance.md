# Documentation Governance

## Purpose

Keep docs searchable with minimum token cost.

## Rules

- Store each doc in the nearest owner scope.
- Use `common/` for cross-project rules, specs, templates.
- Use `stack/<framework>/` for framework-specific docs.
- Use `<project-root>/docs/` as the project-owned docs root.
- Keep project plans in `<project-root>/docs/plan/` by default.
- Keep project troubleshooting records in `<project-root>/docs/troubleshooting/` by default.
- If a project registry entry overrides those paths, follow `plan_path` and `troubleshooting_path`.
- Use harness `project/` for registry metadata only.
- Every doc directory must have `index.md`.
- When reading a directory's docs, also list its actual files (`Glob` or directory listing) so an index-missing doc is not silently skipped. See `anti-drift-guards.md`.
- Update the nearest `index.md` in the same change.
- If a new subdirectory is added, update the parent `index.md` too.
- Keep `index.md` as a map only: path plus one-line summary.
- Do not duplicate the same rule across scopes. Link instead.
- Use original English terms where possible.
- Write `convention` and `spec` docs in command form.
- Keep `convention` and `spec` docs to `Purpose`, `Rules`, `Checklist`, `References` by default.
- Add a `Snippet` section only when it improves prompt hit rate or copy-paste reuse.
- Prefer short, canonical, copyable snippets over long inline examples.
- Store reusable code examples in `snippets/` instead of repeating them across many docs.
- Link from rule docs to snippet docs instead of embedding large code blocks repeatedly.
- Treat snippets as patterns, not as copy-paste targets. Domain identifiers and dependencies must be re-mapped to the actual task context. See `anti-drift-guards.md`.
- Add `Flow` or `Tree` only when structure itself is required.
- Remove tutorial text, history, and long rationale from rule docs.
- Move deep rationale to linked reference docs only.
- If scope rules conflict, priority is project -> framework -> common.
- If a lower scope overrides a higher scope, state the override explicitly.
- If a folder is empty, create `index.md`. Do not keep `.gitkeep` with `index.md`.

## Checklist

- Is the doc in the nearest owner scope?
- Does the target directory have `index.md`?
- Did the same change update the nearest `index.md`?
- If a new folder was added, was the parent `index.md` updated?
- Is the doc command-first and low-token?
- Is long rationale moved to `References`?
- If a snippet exists, is it short and reusable?

## References

- [anti-drift-guards.md](common/convention/anti-drift-guards.md)
- [project-artifact-conventions.md](common/convention/project-artifact-conventions.md)
- [project-doc-structure.md](common/convention/project-doc-structure.md)
- [project/index.md](project/index.md)
- [project-plan-template.md](common/templates/project-plan-template.md)
- [troubleshooting-template.md](common/templates/troubleshooting-template.md)
