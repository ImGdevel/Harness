# Spring Error Handling Convention

## Purpose

Keep Spring API error contracts stable and machine-readable.

## Rules

- Let clients branch on `code`.
- Treat `message` as display text, not contract key.
- Keep HTTP status and domain `code` separate.
- Use one error payload shape across the project.
- Return field-level `Validation` errors as a list.
- Separate expected business errors from unexpected system errors.
- Define `ErrorCode` as the source of status, code, default message.
- Wrap expected domain failures in a project `BusinessException` or equivalent.
- Handle `BusinessException`, `Validation` exceptions, and fallback `Exception` separately.
- Do not leak internal stack trace or implementation detail in `5xx` responses.
- Add `traceId` only when the project uses request tracing.
- Document API-specific error codes in API docs or OpenAPI.

## Checklist

- Can the client branch on `code` only?
- Are `Validation` errors returned as a list?
- Are business and system errors separated?
- Are `5xx` responses sanitized?
- Are documented error codes aligned with runtime behavior?

## References

- [api-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/api-design-convention.md>)
- [security-exception-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/security-exception-convention.md>)
