# Spring Security Exception Convention

## Purpose

Keep Security filter chain errors aligned with the project JSON error contract.

## Rules

- Throw auth failures as `AuthenticationException` or a subtype.
- Throw authorization failures as `AccessDeniedException` or a subtype.
- Handle unexpected filter-chain errors in a dedicated safety-net filter.
- Keep security error codes in the shared `ErrorCode` rule set or a dedicated security group.
- Wire `AuthenticationEntryPoint`, `AccessDeniedHandler`, and safety-net filter explicitly in `SecurityConfig`.
- Use the same error payload shape as the normal API error contract.
- Do not rely on `@ControllerAdvice` alone for Security filter-chain errors.
- Do not expose stack trace or framework internals in the response.

## Checklist

- Are auth failures mapped to `AuthenticationException`?
- Are authorization failures mapped to `AccessDeniedException`?
- Does the filter chain have a safety-net filter?
- Are security error codes centralized?
- Is the response shape aligned with normal API errors?

## References

- [error-handling-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/error-handling-convention.md>)
- [3-devon-woo-community-BE docs/security](https://github.com/100-hours-a-week/3-devon-woo-community-BE/tree/main/docs/security)
