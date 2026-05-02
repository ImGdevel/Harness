---
name: troubleshooting-writing
description: Document reusable troubleshooting records for this harness. Use when the user asks to save a bug investigation, write a troubleshooting note, preserve a debugging session, document root cause analysis, or record a fix inside a real project. This skill stores project troubleshooting documents with metadata, cause analysis, resolution steps, trade-offs, outcomes, and references.
---

# Troubleshooting Writing

Read this entire file once before writing the document.

## Goal

Capture a debugging session or incident as a reusable project record.

## Read Order

Before writing, read only the relevant context:

1. `common/index.md`
2. `common/convention/project-artifact-conventions.md`
3. `common/templates/troubleshooting-template.md`
4. `stack/index.md`
5. The target framework `index.md`
6. `project/index.md` and `project/registry.yaml`
7. If it exists, the actual project `docs/index.md`

## Save Location

For real project issues, save the document in:

registry `troubleshooting_path`

Default path:

`<project-root>/docs/troubleshooting/`

For project issues with reuse or prevention value, this is mandatory.
Do not leave the troubleshooting result only in chat.

Use the filename format:

`YYYY-MM-DD_HHMM_<slug>.md`

If the document is a revision or direct continuation of the same issue, keep the same base name and use `_v2`, `_v3`, and so on.

Resolve `<project-root>` from `project/registry.yaml` first.
If `<project-root>/docs/troubleshooting/` does not exist yet, create it inside the actual project repository before writing the document unless registry overrides the path.

## Required Content

Keep these sections unless they are truly not applicable:

- meta information
- problem statement
- root cause analysis
- resolution process
- alternatives or trade-offs
- result or outcome
- insights
- references or appendix

## Writing Rules

- Write what happened, not vague summaries.
- Include commit id, environment, and related documents when known.
- Distinguish the harness registry path from the actual repository path when both matter.
- Record failed attempts only when they help future debugging.
- Prefer concrete symptoms, logs, and verification steps.
- If the result contains reusable framework insight, extract that insight to common or framework docs after saving the project note.
- For repeated or high-cost failures, not saving the troubleshooting note is a rule violation.

## Template Usage

Use `common/templates/troubleshooting-template.md` as the starting point.
Trim unused placeholders after filling the actual content.
