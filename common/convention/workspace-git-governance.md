# Workspace Git Governance

## Purpose

Keep harness Git strategy separate from project Git strategy.

## Rules

- Apply this doc to the harness repository only.
- Use `main` as the only long-lived branch.
- Do not assume `develop` exists in the harness repository.
- Create short-lived work branches from `main`.
- Use `feat/<short-name>`, `refactor/<short-name>`, `hotfix/<short-name>`.
- Keep one intent per work branch.
- Use `main` as the default PR base for the harness repository.
- Do not import project GitFlow rules into the harness repository.
- Re-check repository context before branch, commit, push, or PR.

## Checklist

- Is the target repository the harness repository?
- Is the work branch based on `main`?
- Is the branch short-lived and single-intent?
- Is the PR base branch `main`?

## References

- [git-branch-gitflow.md](</C:/Users/imdls/workspace/Project Workspace/common/convention/git-branch-gitflow.md>)
