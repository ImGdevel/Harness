# Husky Git Hooks Convention

## Purpose

Use Husky as the default local Git hook runner for project repositories that have a Node.js toolchain at the repository root.

## Rules

- Use Husky v9.
- Keep Husky configuration at the repository root.
- Keep hook files in `.husky/`.
- Add `prepare` to root `package.json`.
- Use `HUSKY=0` in CI, production Docker builds, and emergency local commands that must bypass hooks.
- Do not put long-running full test suites in `pre-commit`.
- Put fast staged checks in `pre-commit`.
- Put commit message validation in `commit-msg`.
- Keep hook bodies small and delegate logic to scripts.
- Do not use Husky hooks as the only CI validation.
- Do not require project code to exist before Husky is installed.

## Standard Files

```text
package.json
.husky/
  pre-commit
  commit-msg
scripts/
  validate-repo.mjs
  validate-commit-message.mjs
```

## Package Script

Use this default.

```json
{
  "scripts": {
    "prepare": "husky || true",
    "validate:repo": "node scripts/validate-repo.mjs",
    "validate:commit-message": "node scripts/validate-commit-message.mjs"
  },
  "devDependencies": {
    "husky": "9.1.7"
  }
}
```

`husky || true` prevents install failure when dev dependencies are not available. CI should still set `HUSKY=0`.

## Hook Policy

`pre-commit` should run repository-local fast checks.

Examples:

- staged whitespace check
- forbidden path check
- generated artifact check
- lint-staged when the project has a frontend package

`commit-msg` should validate the commit message contract.

Examples:

- conventional subject prefix
- Korean subject text when the project requires it
- required body labels
- forbidden attribution text

## Commit Message Contract

The default project contract is:

```text
<type>(optional-scope): <한국어 요약>

What changed:
- ...

Why:
- ...

Evidence:
- ...
```

Allowed commit types can be restricted by each project. If a project has its own commit convention, the project convention wins.

## CI

Use this default in GitHub Actions.

```yaml
env:
  HUSKY: 0
```

CI must run the equivalent checks explicitly instead of relying on local hooks.

## References

- Husky v9 official setup: `npx husky init`
- Husky v9 prepare script: `prepare: husky`
- Husky v9 CI bypass: `HUSKY=0`
