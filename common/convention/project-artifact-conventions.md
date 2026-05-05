# Project Artifact Conventions

## Purpose

Keep project-owned docs in the project repository, not in the harness repository.

## Rules

- Resolve `<project-root>` from harness `project/registry.yaml`.
- Treat harness `project/` as registry metadata only.
- Store project docs in `<project-root>/docs/`.
- Store project plans in `<project-root>/docs/plan/` by default.
- Store project troubleshooting records in `<project-root>/docs/troubleshooting/` by default.
- Resolve the exact plan and troubleshooting paths from registry `plan_path` and `troubleshooting_path` when present.
- Create `docs/`, `docs/plan/`, `docs/troubleshooting/` if missing.
- When bootstrapping a registered project, prefer `scripts/bootstrap-project-docs.ps1`.
- Treat the registry-resolved plan and troubleshooting directories as required directories.
- Use `YYYY-MM-DD_HHMM_<slug>.md`.
- Use local time.
- Use lowercase hyphen slug.
- If the same topic is revised, keep the base name and append `_v2`, `_v3`.
- Create a new filename only for a new topic.
- Save useful plans as files. Do not leave them in chat only.
- Save reusable incident/debug records as files. Do not leave them in chat only.
- If project-only insight becomes framework-common, extract a separate doc into `stack/` or `common/`.

## Checklist

- Was `<project-root>` resolved from registry?
- Was the file written inside the project repository?
- Does the directory exist?
- Does the filename follow the convention?
- Is this a new topic or a version bump?

## References

- [project-doc-structure.md](common/convention/project-doc-structure.md)
- [documentation-governance.md](common/convention/documentation-governance.md)
- [project-plan-template.md](common/templates/project-plan-template.md)
- [troubleshooting-template.md](common/templates/troubleshooting-template.md)
