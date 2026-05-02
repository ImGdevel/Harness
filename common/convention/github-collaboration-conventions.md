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

## Review Comment Handling

- Treat unresolved PR review comments as unfinished work.
- First classify every comment against user requirements, project-specific conventions, and common harness conventions.
- Accept a comment when it identifies a real correctness, security, portability, maintainability, or convention issue.
- If accepted, update code or docs, run the relevant validation, push the fix, reply with what changed, and resolve the conversation.
- Reject a comment only when it conflicts with user requirements, contradicts a stronger project convention, is factually wrong, or expands scope without product value.
- If rejected, reply on the thread with a concrete reason and reference the stronger requirement or convention.
- Do not silently resolve a thread without either a fix commit or a written rejection reason.
- When a comment reveals a reusable rule, add or update the matching common convention document in the same feedback pass.
- Keep review response commits split by intent when code fixes and convention updates are unrelated.

## Checklist

- Is the correct Issue template selected?
- Are required Issue fields filled?
- Does the PR body keep all required sections?
- Is `Validation` explicit?
- Do automation scripts use the same field structure as `.github` templates?
- Were unresolved review comments accepted or rejected with explicit rationale?
- Were resolved conversations backed by a fix, validation, or written rejection reason?

## References

- [github-pr-template.md](</C:/Users/imdls/workspace/Project Workspace/common/templates/github-pr-template.md>)
- [github-issue-work-item-template.md](</C:/Users/imdls/workspace/Project Workspace/common/templates/github-issue-work-item-template.md>)
- [github-issue-bug-template.md](</C:/Users/imdls/workspace/Project Workspace/common/templates/github-issue-bug-template.md>)
