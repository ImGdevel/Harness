# GitHub Collaboration Conventions

## Purpose

Keep GitHub Issue and PR bodies predictable and machine-checkable.

## Rules

- Use `.github/ISSUE_TEMPLATE/` for every Issue.
- Keep `blank_issues_enabled: false`.
- Use `work-item.yml` for feature, refactor, docs, ops work.
- Use `bug-report.yml` for bug, regression, incident work.
- Fill all required Issue fields.
- PR 제목은 `gitmoji + type(optional-scope): 한국어 명사형 요약`을 사용한다.
- PR 제목 예시는 `✨ feat(admin): 관리자 인증 API 추가`, `📝 docs(wiki): 작업 로그 보강`, `🔧 chore(repo): 허스키 검증 규칙 수정`이다.
- gitmoji가 없는 PR 제목으로는 PR 생성 완료를 보고하지 않는다.
- 기존 PR 제목이 gitmoji 제목 규칙을 위반하면 리뷰 요청 또는 완료 보고 전에 제목부터 수정한다.
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
- If accepted, update code or docs, run the relevant validation, push the fix, and resolve the review thread.
- After pushing an accepted fix, re-query review threads and confirm the accepted thread is resolved.
- Reject a comment only when it conflicts with user requirements, contradicts a stronger project convention, is factually wrong, or expands scope without product value.
- If rejected, write a reply directly on that review thread with a concrete reason and reference the stronger requirement or convention.
- Do not use a top-level PR comment as a substitute for a review-thread reply.
- Do not resolve a rejected thread without a written review-thread reply.
- If connector permissions block resolve/reply, try an authenticated non-interactive path such as `gh` or GitHub API with the local Git Credential Manager token before reporting a blocker.
- Do not operate the user's GitHub Web UI to resolve review threads unless the user explicitly requests browser-based interaction.
- Do not report PR feedback handling as complete while any accepted review thread remains unresolved, unless every available resolve path failed and the blocker is documented.
- When a comment reveals a reusable rule, add or update the matching common convention document in the same feedback pass.
- Keep review response commits split by intent when code fixes and convention updates are unrelated.

## AI Review Automation

- If a repository uses an AI review app, treat its first-pass review as part of PR completion unless the project explicitly opts out.
- Do not merge or report a PR as fully complete until CI and the configured AI review window have both been checked.
- Wait the project-defined window before deciding that the AI review did not respond. Use 10 to 20 minutes when no stronger project rule exists.
- If a manual slash command is needed, write one command per top-level PR comment.
- Do not combine commands such as `/gemini review` and `/gemini summary` in one comment.
- Request review before summary. Summary is optional and should not block code-review handling unless the project requires it.
- If the PR is merged or closed before the AI app responds, do not treat a later failed or canceled AI response as review completion.
- Record AI review timeout, failure, or cancellation in the project log or troubleshooting document when it affects the workflow.

## Checklist

- Is the correct Issue template selected?
- Are required Issue fields filled?
- Does the PR title use `gitmoji + type(optional-scope): 한국어 명사형 요약`?
- Does the PR body keep all required sections?
- Is `Validation` explicit?
- Do automation scripts use the same field structure as `.github` templates?
- Were unresolved review comments accepted or rejected with explicit rationale?
- Were accepted conversations backed by a fix and validation before resolve?
- Were rejected conversations answered with a review-thread reply before resolve?
- Was the PR review thread list re-queried after fixes?
- Are unresolved accepted review threads zero, or is a resolve/reply permission blocker documented?
- Was configured AI review checked before merge or completion reporting?
- If a manual AI command was used, was it sent as one command per comment?

## References

- [github-pr-template.md](common/templates/github-pr-template.md)
- [github-issue-work-item-template.md](common/templates/github-issue-work-item-template.md)
- [github-issue-bug-template.md](common/templates/github-issue-bug-template.md)
