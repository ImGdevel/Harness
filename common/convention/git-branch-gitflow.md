# Git Branch Management With GitFlow

## Purpose

Use one GitFlow rule set for project repositories.

## Rules

- Apply this doc to project repositories only.
- Do not apply this doc to the harness repository.
- Use `main` as the production branch.
- Use `develop` as the integration branch.
- Create `feature/<short-name>` from `develop`.
- Create `release/<version>` from `develop`.
- Create `hotfix/<short-name>` from `main`.
- Merge `feature/*` to `develop`.
- Merge `release/*` to `main` and `develop`.
- Merge `hotfix/*` to `main` and `develop`.
- Use short English slugs.
- Do not put issue numbers in branch names by default.
- Do not reuse one `feature/*` branch for unrelated work.
- Keep `release/*` and `hotfix/*` scope minimal.
- Re-check repository context before branch creation.

## Checklist

- Is this a project repository, not the harness repository?
- Is the branch type correct for the work?
- Is the start branch correct?
- Is the merge target correct?
- Is the branch name short and descriptive?

## References

- [workspace-git-governance.md](</C:/Users/imdls/workspace/Project Workspace/common/convention/workspace-git-governance.md>)
- Project-specific Git doc, if it exists
