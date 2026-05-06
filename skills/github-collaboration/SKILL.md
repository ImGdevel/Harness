---
name: github-collaboration
description: Create or update GitHub issues and pull requests using the workspace templates and enforcement rules. Use when the user asks to draft an issue, write or revise a PR description, apply issue or PR templates, or prepare GitHub collaboration artifacts for the workspace or a real project repository.
---

# GitHub Collaboration

Read this file once before writing an issue or PR body.

## Goal

Keep issue and PR descriptions aligned with the workspace templates and GitHub enforcement rules.

## Read Order

Read these files before drafting:

1. `common/index.md`
2. `common/convention/github-collaboration-conventions.md`
3. `common/templates/github-pr-template.md`
4. `common/templates/github-issue-work-item-template.md`
5. `common/templates/github-issue-bug-template.md`
6. If working in a real project, `project/index.md` and `project/registry.yaml`
7. After resolving the project path, the actual project `docs/index.md`

## Issue Rules

- Choose the issue template first.
- Use `work-item` for feature, refactor, docs, build, and chore work.
- Use `bug-report` for defects, regressions, incidents, and unexpected behavior.
- Keep the title short and specific.
- Fill required fields with concrete context, not placeholders.

## PR Rules

- PR 제목은 `gitmoji + type(optional-scope): 한국어 명사형 요약`을 사용한다.
- 예시는 `✨ feat(admin): 관리자 인증 API 추가`, `📝 docs(wiki): 작업 로그 보강`, `🔧 chore(repo): 허스키 검증 규칙 수정`이다.
- gitmoji가 없는 PR 제목으로는 PR 생성 완료를 보고하지 않는다.
- Always keep `Summary`, `Scope`, `Validation`, and `Checklist`.
- `Validation` must say what was run, or explicitly say `not run` with reason.
- `Scope` should describe both affected and excluded areas when that distinction matters.
- Use `Notes` for risk, rollout, screenshots, related links, and follow-up work.

## Local Drafting Rule

If the work happens outside the GitHub UI:

- start from the matching file in `common/templates/`
- keep the same headings as the `.github` templates
- do not invent a different PR or issue structure

## Output Expectations

When helping with GitHub collaboration artifacts, provide:

- selected repository path
- selected template type
- completed issue or PR body
- missing information if any field could not be filled
