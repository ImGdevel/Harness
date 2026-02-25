---
name: git-workflow
description: Apply the workspace Git workflow for branch creation, branch management, and commit preparation. Use when the user asks to create a branch, choose a branch name, follow GitFlow, prepare commits, split commits, or enforce commit message rules in this workspace or a project repository.
---

# Git Workflow

Read this entire file once before doing Git work.

## Goal

Apply a consistent Git workflow across the workspace and project repositories.

## Read Order

Before doing Git work, read:

1. `common/index.md`
2. `common/convention/git-commit-conventions.md`
3. `common/convention/git-branch-gitflow.md`
4. If issue or PR work is involved, `common/convention/github-collaboration-conventions.md`
5. If working in a real project, `project/index.md` and `project/registry.yaml`
6. After resolving the project path, the actual project `docs/index.md`

If the task is still ambiguous, align scope first with `workspace-gatekeeper`.

## Branch Rules

- Use GitFlow as the default strategy.
- Check whether the work belongs on `feature/*`, `release/*`, or `hotfix/*`.
- Choose the correct base branch before creating a branch.
- Do not continue unrelated work on an existing branch just because it already exists.
- Do not include issue numbers in branch names by default.
- Do not implement feature work directly on `main`, `develop`, or `master`.

## Commit Rules

- Commit one intent at a time.
- Use the commit message format from `common/convention/git-commit-conventions.md`.
- Review staged files before committing.
- If the scope is mixed, split the commit first.
- Do not include issue numbers in commit messages by default.

## Validation Order

Before creating a branch or commit, check in this order:

1. selected repository path
2. current branch name
3. branch type and expected base branch
4. staged scope or working tree scope
5. available validation commands

If one check fails, stop and fix that state before moving to the next step.

## Branch Validation

Validate the current branch against the GitFlow document:

- `feature/*`, `release/*` should start from `develop`
- `hotfix/*` should start from `main`
- `support/*` is exceptional and should exist only with a clear maintenance reason
- long-lived branches with unrelated work should be replaced, not reused

## Workspace vs Project Repo

- The workspace repository and each real project repository are separate Git contexts.
- Confirm which repository you are operating on before branching or committing.
- The harness `project/` directory is registry metadata only and is never the project Git target.
- Project-specific Git rules override workspace defaults when documented.
- If the task includes issue or PR authoring, hand off to `github-collaboration`.

## Execution Rules

- Prefer non-interactive Git commands.
- Use `git status -sb` before staging or committing.
- Use `git diff --cached --stat` or an equivalent staged diff check before `git commit`.
- Avoid destructive commands unless explicitly requested.
- If branch strategy and current branch conflict, stop and correct the branch first.
- If the staged set contains two different intents, split it before commit.

## Output Expectations

When helping with Git work, provide:

- selected repository path
- current or proposed branch name
- selected branch strategy
- expected base branch when relevant
- commit scope summary
- validation status if checks were run
