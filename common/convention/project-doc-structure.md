# Project Doc Structure

## Purpose

Use one predictable `docs/` tree for every project repository.

## Tree

```text
<project-root>/docs/
  index.md
  api/
    index.md
  architecture/
    index.md
  convention/
    index.md
  domain-tech-spec/
    index.md
  erd/
    index.md
  infrastructure/
    index.md
  local-setup/
    index.md
  plan/
    index.md
  references/
    index.md
  security/
    index.md
  stack-selection/
    index.md
  troubleshooting/
    index.md
```

## Rules

- Keep this baseline tree in every project repository.
- When starting from a registered project, prefer `scripts/bootstrap-project-docs.ps1` to create the baseline tree.
- Keep one `index.md` in every document directory.
- Use `api/` for API contract docs.
- Use `architecture/` for module boundary, runtime flow, system shape.
- Use `convention/` for project-only rules.
- Use `domain-tech-spec/` for use case, policy, state, domain behavior.
- Use `erd/` for table and relation docs.
- Use `infrastructure/` for deploy and cloud docs.
- Use `local-setup/` for local environment setup.
- Use `references/` for external references and supporting links.
- Use `security/` for auth, authz, secret handling, security checks.
- Use `stack-selection/` for stack choice and trade-off records.
- Add optional folders only when needed.
- If a new folder is added, update `docs/index.md` in the same change.
- Do not duplicate the same doc across folders.
- Keep plans in `<project-root>/docs/plan/` by default.
- Keep troubleshooting records in `<project-root>/docs/troubleshooting/` by default.

## Checklist

- Does the project keep the baseline tree?
- Does every document directory have `index.md`?
- Is each doc in the nearest matching section?
- If a new section was added, was `docs/index.md` updated?

## References

- [documentation-governance.md](common/convention/documentation-governance.md)
- [project-artifact-conventions.md](common/convention/project-artifact-conventions.md)
