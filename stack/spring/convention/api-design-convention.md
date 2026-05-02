# Spring API Design Convention

## Purpose

Fix request, response, error, and pagination rules for Spring HTTP APIs.

## Rules

- Fix one Base URL policy per project.
- Use `application/json; charset=utf-8` by default.
- Use standard auth headers such as `Authorization: Bearer <token>`.
- Use ISO-8601 for date-time.
- Keep `GET` read-only.
- Use `POST` for create or command-style actions.
- Use `PUT` for full replace only.
- Use `PATCH` for partial update only.
- Use `DELETE` for remove entrypoints.
- Use `204 No Content` when the response body is unnecessary.
- Use `{"data": ...}` for success payloads unless the project defines another fixed envelope.
- Use `code`, `message`, optional `errors`, optional `traceId` for error payloads.
- Separate HTTP status from domain `error.code`.
- Use either `Page` or `Cursor` in one API. Do not mix them.
- Do not expose Spring Data `Page` directly. Convert it to the project's common `PageResponse<T>`.
- Use common DTOs such as `ListResponse<T>`, `PageResponse<T>`, `SliceResponse<T>`, `ErrorResponse`, and `FieldErrorResponse` when the response shape repeats.
- Keep query parameters explicit. Do not pack JSON into query parameters.
- Document the default sort rule.
- Add a stable tie-breaker for `Cursor` pagination.
- Use `POST /.../search` only for complex search DSL.
- Separate public API paths from internal/admin API paths.

## Checklist

- Does the URI match the HTTP method semantics?
- Does the API keep one success envelope rule?
- Does the API keep one error envelope rule?
- Are `Validation` errors separated from business errors?
- Is pagination strategy consistent?
- Is `PUT` used only for full replace?

## References

- [error-handling-convention.md](error-handling-convention.md)
- [common-api-dto-convention.md](common-api-dto-convention.md)
- [security-exception-convention.md](security-exception-convention.md)
