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
6. If it exists, `project/<name>/docs/index.md`

## Save Location

For real project issues, save the document in:

`project/<name>/troubleshooting/`

Use the filename format:

`YYYY-MM-DD_HHMM_<slug>.md`

If the document is a revision or direct continuation of the same issue, keep the same base name and use `_v2`, `_v3`, and so on.

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
- Distinguish the project container path from the actual repository path when both matter.
- Record failed attempts only when they help future debugging.
- Prefer concrete symptoms, logs, and verification steps.
- If the result contains reusable framework insight, extract that insight to common or framework docs after saving the project note.

## Template Usage

Use `common/templates/troubleshooting-template.md` as the starting point.
Trim unused placeholders after filling the actual content.
