# Git Branch Management With GitFlow

## Purpose

Use one GitFlow rule set for project repositories.

## Rules

- Apply this doc to project repositories only.
- Do not apply this doc to the harness repository.
- Use `main` as the production branch.
- Use `develop` as the integration branch.
- Create `feat/<short-name>` from `develop`.
- Create `release/<version>` from `develop`.
- Create `hotfix/<short-name>` from `main`.
- Merge `feat/*` to `develop`.
- Merge `release/*` to `main` and `develop`.
- Merge `hotfix/*` to `main` and `develop`.
- Use short English slugs.
- Do not put issue numbers in branch names by default.
- Do not reuse one `feat/*` branch for unrelated work.
- Do not stack one `feat/*` branch on another `feat/*` branch unless the dependency is explicit and documented.
- Keep `release/*` and `hotfix/*` scope minimal.
- Re-check repository context before branch creation.
- Run `scripts/validate-project-git-context.ps1` when the repository is registered in the harness.

## Checklist

- Is this a project repository, not the harness repository?
- Is the branch type correct for the work?
- Is the start branch correct?
- Do `origin/main` and `origin/develop` exist?
- Does remote HEAD point to `main`?
- Is the merge target correct?
- Is the branch name short and descriptive?
- Is the branch free from unintegrated feature-branch ancestry?

## References

- [workspace-git-governance.md](</C:/Users/imdls/workspace/Project Workspace/common/convention/workspace-git-governance.md>)
- [project-git-governance.md](</C:/Users/imdls/workspace/Project Workspace/common/convention/project-git-governance.md>)
- Project-specific Git doc, if it exists
