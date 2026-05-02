# Git Commit Conventions

## Purpose

Use split-by-intent commits for project repositories.

## Rules

- Apply this doc to project repositories by default.
- Keep one intent per commit.
- Split feature, refactor, format, docs, and generated-file changes when possible.
- Do not stage unrelated files in one commit.
- Re-check repository context before commit.
- Do not commit broken code, debug leftovers, or secrets.
- Run required checks before commit when the repository defines them.
- Use `type(scope): summary`.
- Write the commit message subject in Korean.
- Keep the summary short and do not end it with a period.
- Do not put issue numbers in commit messages by default.
- Do not use vague summaries such as `wip`, `fix bug`, `update stuff`.
- Add a body only when rationale, trade-off, or follow-up is necessary.

## Checklist

- Is the repository context correct?
- Does the commit contain one intent only?
- Are unrelated files excluded?
- Is the message format correct?
- Were required checks run or explicitly skipped?

## References

- [git-branch-gitflow.md](</C:/Users/imdls/workspace/Project Workspace/common/convention/git-branch-gitflow.md>)
- Project-specific Git doc, if it exists
