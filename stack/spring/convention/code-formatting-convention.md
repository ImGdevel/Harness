# Spring Code Formatting Convention

## Purpose

Reduce review noise and formatter drift.

## Rules

- Use one formatter per project.
- Do not mix IDE default formatting with team formatter rules.
- Keep local auto-format and CI format checks aligned.
- Keep one import order rule for IDE and CI.
- Run formatter checks before commit when the project defines them.
- Split pure formatting changes from behavior changes when possible.
- Do not hide logic changes inside large formatting diffs.

## Checklist

- Is the formatter source of truth fixed?
- Does IDE formatting match CI formatting?
- Is import order stable?
- Are formatting-only changes separated when possible?

## References

- Project formatter config
- `spotlessCheck`, `spotlessApply`, or equivalent project command
