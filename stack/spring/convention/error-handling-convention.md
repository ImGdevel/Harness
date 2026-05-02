# Spring Error Handling Convention

## Purpose

Keep Spring API error contracts stable and machine-readable.

## Rules

- Let clients branch on `code`.
- Treat `message` as display text, not contract key.
- Keep HTTP status and domain `code` separate.
- Use one error payload shape across the project.
- Use the project common `ErrorResponse` and `FieldErrorResponse` DTOs for every API error.
- Return field-level `Validation` errors as a list.
- Separate expected business errors from unexpected system errors.
- Define `ErrorCode` as the source of status, code, default message.
- Wrap expected domain failures in a project `BusinessException` or equivalent.
- Handle `BusinessException`, `Validation` exceptions, and fallback `Exception` separately.
- Do not leak internal stack trace or implementation detail in `5xx` responses.
- Add `traceId` only when the project uses request tracing.
- Document API-specific error codes in API docs or OpenAPI.
- Error `code`는 대문자 snake case 문자열로 고정한다. 예: `PUBLIC_POST_NOT_FOUND`.
- 공통 code와 도메인 code를 분리한다.
- `ErrorCode` enum은 HTTP status, code, default message를 함께 가진다.
- default message는 짧고 안전해야 한다. 내부 테이블명, SQL, token, stack trace를 넣지 않는다.
- 예외 생성 시 동적 message가 필요하면 사용자가 이해할 수 있는 범위로 제한한다.
- validation field error는 field, rejectedValue(optional), reason 형태를 유지한다.
- rejectedValue는 password, token, secret, email full value처럼 민감할 수 있으면 생략하거나 마스킹한다.
- `MethodArgumentNotValidException`, `BindException`, `ConstraintViolationException`, `MissingServletRequestParameterException`, `MethodArgumentTypeMismatchException`을 공통 handler에서 처리한다.
- unknown exception은 logging 후 `INTERNAL_ERROR`로 sanitize한다.

## Error Code Design

기본 interface:

```java
public interface ErrorCode {
    HttpStatus httpStatus();
    String code();
    String message();
}
```

공통 code 예:

| Code | HTTP | Usage |
| --- | --- | --- |
| `INVALID_REQUEST` | 400 | binding, validation, type mismatch |
| `RESOURCE_NOT_FOUND` | 404 | 공통 리소스 부재 |
| `CONFLICT` | 409 | 상태 충돌 |
| `INTERNAL_ERROR` | 500 | 예상하지 못한 서버 오류 |

도메인 code 예:

| Code | HTTP | Usage |
| --- | --- | --- |
| `PUBLIC_POST_NOT_FOUND` | 404 | 공개 글이 없거나 공개 상태가 아님 |
| `COMPANY_NOT_FOUND` | 404 | 기업 slug가 없음 |
| `TAG_NOT_FOUND` | 404 | 태그 slug가 없음 |

Rules:

- client가 분기해야 하는 상황은 공통 code로 뭉개지 않는다.
- 메시지만 다른 같은 code를 남발하지 않는다.
- code 이름에 HTTP status를 반복하지 않는다. Bad: `BAD_REQUEST_INVALID_PAGE`.
- code는 삭제하지 않는다. deprecated가 필요하면 문서화 후 유지한다.

## Error Response Shape

권장 shape:

```json
{
  "code": "INVALID_REQUEST",
  "message": "요청 값이 올바르지 않습니다.",
  "errors": [
    {
      "field": "size",
      "reason": "must be between 1 and 100"
    }
  ],
  "traceId": "optional"
}
```

Rules:

- `errors`는 validation/binding error가 있을 때만 포함한다.
- `traceId`는 tracing이 설정된 프로젝트에서만 포함한다.
- `timestamp`를 넣을지 여부는 프로젝트에서 통일한다.
- 성공 envelope와 error envelope를 혼합하지 않는다.

## Exception Mapping

| Exception | HTTP | Code | Note |
| --- | --- | --- | --- |
| `BusinessException` | `errorCode.httpStatus()` | `errorCode.code()` | expected domain/application error |
| `MethodArgumentNotValidException` | 400 | `INVALID_REQUEST` | `@RequestBody @Valid` failure |
| `BindException` | 400 | `INVALID_REQUEST` | query/model binding failure |
| `ConstraintViolationException` | 400 | `INVALID_REQUEST` | method/path/query constraint failure |
| `MissingServletRequestParameterException` | 400 | `INVALID_REQUEST` | required query missing |
| `MethodArgumentTypeMismatchException` | 400 | `INVALID_REQUEST` | enum/number conversion failure |
| `NoHandlerFoundException` | 404 | `RESOURCE_NOT_FOUND` | optional if configured |
| `Exception` | 500 | `INTERNAL_ERROR` | log detail, return sanitized body |

## Message Policy

- message는 한국어/영어 중 프로젝트 기준 언어를 하나로 정한다.
- validation annotation message는 너무 긴 문장보다 짧은 원인 중심으로 쓴다.
- message interpolation으로 민감 데이터를 포함하지 않는다.
- 예외 message를 그대로 응답으로 내보낼 수 있는 exception type을 제한한다.
- fallback `Exception`의 `ex.getMessage()`는 응답하지 않는다.

## Binder and Type Mismatch

- type mismatch는 validation failure와 같은 `INVALID_REQUEST`로 처리한다.
- enum mismatch는 허용 값 목록을 `reason`에 포함할 수 있다.
- binding 대상에 없는 field가 들어왔을 때 ignore/deny 정책을 프로젝트에서 정한다.
- admin/form binding에서 over-posting 위험이 있으면 `@InitBinder`의 `setAllowedFields`를 사용한다.

## Checklist

- Can the client branch on `code` only?
- Are `Validation` errors returned as a list?
- Are business and system errors separated?
- Are `5xx` responses sanitized?
- Are documented error codes aligned with runtime behavior?
- Are binder/type mismatch errors mapped to the same contract?
- Are sensitive rejected values masked or omitted?
- Are domain-specific not-found errors distinct enough for the frontend?

## References

- [api-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/api-design-convention.md>)
- [common-api-dto-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/common-api-dto-convention.md>)
- [controller-writing-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/controller-writing-convention.md>)
- [security-exception-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/security-exception-convention.md>)
