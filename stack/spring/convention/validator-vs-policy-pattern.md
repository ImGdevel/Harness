# Spring Validator vs Policy Pattern

## Purpose

Separate input validation from domain policy checks.

## Rules

- Keep `Validator` and `Policy` separate.
- Use `Validator` for null, blank, length, range, format, existence checks.
- Use `Policy` for ownership, state transition, limit, prohibition checks.
- Do not put business rules in `Validator`.
- Do not put HTTP shape checks in `Policy`.
- Run `Validator -> Policy -> Entity guard`.
- Name classes `*Validator`, `*Policy`.
- Use verbs such as `validate`, `validateCanXxx`, `shouldXxx`.
- Keep `Validator` in the application side.
- Keep `Policy` in the domain side.

## Checklist

- Is shape validation separated from business validation?
- Is `Validator` free from ownership and state logic?
- Is `Policy` free from request-shape logic?
- Is call order consistent?

## References

- [layer-and-naming-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/layer-and-naming-convention.md>)
- [3-devon-woo-community-BE docs/validation](https://github.com/100-hours-a-week/3-devon-woo-community-BE/tree/main/docs/validation)
