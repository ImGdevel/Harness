# Spring Layer And Naming Convention

## Purpose

Make role and layer visible from package name and class name.

## Rules

- Name request DTO as `{Domain}{UseCase}Request`.
- Name response DTO as `{Domain}{UseCase}Response`.
- Use `*Condition` for query input.
- Use `*QueryDto` for query projection output.
- Keep request/response DTO on the application or web side.
- Keep domain DTO, repository, policy in domain-oriented packages.
- Use `toXxx`, `fromXxx`, `of`, `empty` consistently.
- Separate `Validator` from `Policy`.
- Use `Validator` for shape, required field, range, existence checks.
- Use `Policy` for ownership, state transition, limit, prohibition checks.
- Run `Validator` before `Policy`.
- Do not let `Policy` depend on web DTO types.
- Convert web DTO to internal type in `Controller`.
- Do not let `Service` depend on web request types.
- Use role-based names for security and infra components.
- Use `Custom*` only when extending or implementing framework types.
- Standardize pagination request and response models per project.

## Checklist

- Does the class name reveal role and layer?
- Are `Condition` and `QueryDto` used correctly?
- Is `Validator` free from business rule logic?
- Is `Policy` free from web-layer dependency?
- Does `Controller` own web-to-internal conversion?

## References

- [request-response-dto-convention.md](request-response-dto-convention.md)
- [validator-vs-policy-pattern.md](validator-vs-policy-pattern.md)
