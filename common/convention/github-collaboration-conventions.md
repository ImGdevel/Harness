# GitHub Collaboration Conventions

## Purpose

Keep GitHub Issue and PR bodies predictable and machine-checkable.

## Rules

- Use `.github/ISSUE_TEMPLATE/` for every Issue.
- Keep `blank_issues_enabled: false`.
- Use `work-item.yml` for feature, refactor, docs, ops work.
- Use `bug-report.yml` for bug, regression, incident work.
- Fill all required Issue fields.
- Use `.github/PULL_REQUEST_TEMPLATE.md` for every PR.
- Keep `## Summary`, `## Scope`, `## Validation`, `## Checklist` in every PR body.
- Do not leave `Validation` empty.
- If checks were not run, write `not run` plus reason.
- Keep the checklist section. Put exceptions in `Notes` instead of deleting items.
- Keep automation fields aligned with `.github` templates.
- Treat GitHub validation workflows as the source of enforcement.

## Checklist

- Is the correct Issue template selected?
- Are required Issue fields filled?
- Does the PR body keep all required sections?
- Is `Validation` explicit?
- Do automation scripts use the same field structure as `.github` templates?

## References

- [github-pr-template.md](</C:/Users/imdls/workspace/Project Workspace/common/templates/github-pr-template.md>)
- [github-issue-work-item-template.md](</C:/Users/imdls/workspace/Project Workspace/common/templates/github-issue-work-item-template.md>)
- [github-issue-bug-template.md](</C:/Users/imdls/workspace/Project Workspace/common/templates/github-issue-bug-template.md>)
