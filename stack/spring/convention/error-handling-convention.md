# Spring ErrorCode And Exception Handling Convention

## Purpose

Spring MVC API의 예외 처리는 프론트엔드가 안정적으로 분기할 수 있는 **공개 계약**이다.
따라서 예외 클래스, HTTP status, error code, 사용자 메시지, field error, 로그 정책, 문서화 방식을 프로젝트마다 임의로 만들지 않는다.

이 문서는 다음을 고정한다.

- 언제 custom exception을 쓰고 언제 쓰지 않는가
- ErrorCode를 어떻게 작성하고 유지하는가
- validation/binding/type mismatch 예외를 어떻게 공통 처리하는가
- 내부 예외 정보를 프론트에 어디까지 노출하는가
- Swagger/OpenAPI와 테스트에는 무엇을 남기는가

## Official Basis

- Spring MVC는 `@ControllerAdvice`와 `@ExceptionHandler`로 중앙 예외 처리를 제공한다.
- Spring MVC `@ExceptionHandler`는 `ResponseEntity`, `ProblemDetail`, `ErrorResponse` 같은 error response return type을 지원한다.
- Spring Boot는 기본 `/error`와 `server.error.include-message`, `server.error.include-binding-errors`, `server.error.include-stacktrace` 등 error attribute 노출 속성을 제공한다.
- 이 하네스의 기본 선택은 Spring 기본 `/error` payload나 RFC `ProblemDetail`을 그대로 공개하지 않고, 프로젝트 공통 `ErrorResponse` DTO를 명시적으로 반환하는 방식이다.
- 프로젝트가 외부 공개 API 또는 표준 RFC 9457 호환을 목표로 하면 `ProblemDetail`을 선택할 수 있지만, 그 경우에도 code/message/errors/traceId 계약을 별도 문서에 고정해야 한다.

## Package Rule

예외와 에러코드 공통 클래스는 web boundary에 가까운 `common.error` 계열에 둔다.

```text
common/
  error/
    ErrorCode.java
    CommonErrorCode.java
    BusinessException.java
    ErrorResponse.java
    FieldErrorResponse.java
    GlobalExceptionHandler.java
    FieldErrorMapper.java
    ErrorLogLevel.java
```

Rules:

- `ErrorCode`, `BusinessException`, `ErrorResponse`는 domain entity 패키지에 두지 않는다.
- 도메인별 code enum은 feature boundary에 둘 수 있다. 예: `post/error/PostErrorCode.java`.
- `GlobalExceptionHandler`는 web adapter 또는 common web package에 둔다.
- Spring Security filter chain 예외는 `@ControllerAdvice`에 도달하지 않을 수 있으므로 별도 handler를 둔다.

## Exception Selection Rule

### Use BusinessException

`BusinessException`은 클라이언트가 행동을 바꿀 수 있는 **예상 가능한 업무 실패**에 사용한다.

Examples:

- 조회 대상이 없음: `PUBLIC_POST_NOT_FOUND`
- 이미 처리된 요청: `SUBSCRIPTION_ALREADY_VERIFIED`
- 상태 전이 불가: `POST_ALREADY_PUBLISHED`
- 권한은 있지만 해당 리소스에 대한 작업 조건이 맞지 않음: `COMPANY_SOURCE_PAUSED`
- 외부 시스템 실패를 사용자에게 안정적으로 노출해야 함: `AI_SUMMARY_PROVIDER_UNAVAILABLE`

Rules:

- `BusinessException`은 반드시 `ErrorCode`를 가진다.
- 클라이언트 분기가 필요한 상황은 `INVALID_REQUEST` 하나로 뭉개지 않는다.
- 동적 메시지를 넣을 수 있지만, 사용자에게 안전한 문장만 허용한다.
- `BusinessException`을 logging 목적으로만 만들지 않는다.

### Do Not Use BusinessException

다음 상황에서는 custom business exception을 쓰지 않는다.

| Situation | Preferred |
| --- | --- |
| `@RequestBody` validation 실패 | `MethodArgumentNotValidException`을 공통 handler에서 처리 |
| query/model binding 실패 | `BindException` 또는 Spring binding 예외를 공통 handler에서 처리 |
| path/query type mismatch | `MethodArgumentTypeMismatchException` 또는 `TypeMismatchException` 처리 |
| JSON 문법 오류 | `HttpMessageNotReadableException` 처리 |
| 인증 실패 | `AuthenticationException` 또는 Spring Security entry point |
| 인가 실패 | `AccessDeniedException` 또는 access denied handler |
| repository unique constraint 등 DB 무결성 실패 | service/application layer에서 의미 있는 `BusinessException`으로 변환하거나 fallback conflict handler 처리 |
| 외부 SDK timeout, IOException | infrastructure에서 원인을 보존하고 application layer에서 의미 있는 code로 변환 |
| null, blank, range 같은 내부 guard | `IllegalArgumentException` 또는 local guard. API 응답으로 직접 노출하지 않음 |
| 프로그래밍 오류, NPE, IllegalState | fallback `INTERNAL_ERROR`. 응답에 원문 message 노출 금지 |

### Domain Entity Guard

순수 domain entity와 value object는 Spring MVC 계약을 몰라야 한다.

Rules:

- entity factory/local guard에서 단순 invariant 위반은 `IllegalArgumentException`을 사용할 수 있다.
- application service가 사용자 요청을 처리하다 domain guard 예외를 받으면 필요한 경우 `BusinessException(ErrorCode)`로 변환한다.
- entity가 직접 HTTP status나 `ErrorResponse`를 알면 안 된다.
- entity가 직접 `BusinessException`을 던지는 것은 프로젝트에서 명시적으로 허용한 경우에만 사용한다. 기본은 application layer 변환이다.

## ErrorCode Design

기본 interface:

```java
public interface ErrorCode {

    HttpStatus httpStatus();

    String code();

    String message();
}
```

Optional extension:

```java
public interface LoggableErrorCode extends ErrorCode {

    ErrorLogLevel logLevel();
}
```

### Naming

Rules:

- code는 public contract이므로 대문자 snake case로 작성한다.
- code는 삭제하지 않는다. 더 이상 쓰지 않으면 deprecated 문서화 후 유지한다.
- code 이름에 HTTP status를 반복하지 않는다.
- domain prefix를 우선한다.
- 클라이언트 분기 단위가 다르면 code를 분리한다.

Good:

- `INVALID_REQUEST`
- `PUBLIC_POST_NOT_FOUND`
- `COMPANY_SOURCE_ALREADY_APPROVED`
- `SUBSCRIPTION_VERIFY_TOKEN_EXPIRED`
- `AI_SUMMARY_GENERATION_FAILED`

Bad:

- `BAD_REQUEST`
- `ERROR_001`
- `POST_ERROR`
- `NOT_FOUND_404`
- `USER_MESSAGE_CHANGED`

### Common Error Codes

| Code | HTTP | Usage |
| --- | --- | --- |
| `INVALID_REQUEST` | 400 | validation, binding, type mismatch, malformed JSON |
| `UNAUTHORIZED` | 401 | 인증 없음 또는 인증 실패 |
| `FORBIDDEN` | 403 | 인증은 되었지만 권한 없음 |
| `RESOURCE_NOT_FOUND` | 404 | domain code가 필요 없는 공통 not found |
| `METHOD_NOT_ALLOWED` | 405 | HTTP method 불일치 |
| `CONFLICT` | 409 | 공통 상태 충돌 |
| `UNSUPPORTED_MEDIA_TYPE` | 415 | request content type 불일치 |
| `TOO_MANY_REQUESTS` | 429 | rate limit |
| `INTERNAL_ERROR` | 500 | 예상하지 못한 서버 오류 |
| `EXTERNAL_SERVICE_UNAVAILABLE` | 503 | 외부 시스템 장애 |

### Domain Error Codes

도메인 code는 공통 code보다 구체적이어야 한다.

Examples:

| Code | HTTP | Usage |
| --- | --- | --- |
| `PUBLIC_POST_NOT_FOUND` | 404 | 공개 글이 없거나 공개 상태가 아님 |
| `COMPANY_NOT_FOUND` | 404 | 기업 slug가 없음 |
| `TOPIC_TAG_NOT_FOUND` | 404 | 주제 태그가 없음 |
| `SUBSCRIPTION_EMAIL_ALREADY_VERIFIED` | 409 | 이미 검증된 구독 이메일 |
| `SUBSCRIPTION_VERIFY_TOKEN_EXPIRED` | 400 | 검증 token 만료 |
| `SOURCE_BLOG_ALREADY_APPROVED` | 409 | 이미 승인된 source blog |

Rules:

- `NOT_FOUND`라도 프론트가 다른 화면/문구를 보여야 하면 domain code로 분리한다.
- 같은 HTTP status라도 사용자 행동이 다르면 code를 분리한다.
- 운영자만 알아야 하는 내부 상태는 message에 넣지 않는다.

## Error Response Contract

기본 shape:

```json
{
  "code": "INVALID_REQUEST",
  "message": "요청 값이 올바르지 않습니다.",
  "errors": [
    {
      "field": "size",
      "reason": "1 이상 100 이하로 입력해 주세요."
    }
  ],
  "traceId": "9f5c2a0f"
}
```

Required fields:

| Field | Type | Rule |
| --- | --- | --- |
| `code` | `String` | machine-readable public contract |
| `message` | `String` | safe display message |

Optional fields:

| Field | Type | Rule |
| --- | --- | --- |
| `errors` | `List<FieldErrorResponse>` | validation/binding 오류가 있을 때만 |
| `traceId` | `String` | tracing/MDC가 있을 때만 |

Do not expose:

- exception class name
- stack trace
- SQL, table, column, query
- package/class/method name
- token, password, secret, full email, phone number
- internal numeric id unless API contract에서 공개하기로 한 값
- upstream raw error body
- fallback `Exception#getMessage()`

Allowed exposure:

- public error `code`
- 안전한 사용자 메시지
- validation field path
- validation 실패 이유
- 허용 enum 값 목록. 단, 보안상 민감하지 않은 public enum일 때만
- traceId 또는 requestId

## Binding And Validation Exception Rule

Spring MVC binding 계열 예외는 `BusinessException`으로 다시 던지지 않고 공통 handler에서 바로 `INVALID_REQUEST`로 변환한다.

| Exception | Source | Response |
| --- | --- | --- |
| `MethodArgumentNotValidException` | `@RequestBody @Valid` 실패 | `INVALID_REQUEST` + field errors |
| `BindException` | query/model attribute binding 실패 | `INVALID_REQUEST` + field errors |
| `HandlerMethodValidationException` | Spring method validation 실패 | `INVALID_REQUEST` + parameter errors |
| `ConstraintViolationException` | method/path/query constraint 실패 | `INVALID_REQUEST` + property path errors |
| `MethodArgumentTypeMismatchException` | path/query enum/number 변환 실패 | `INVALID_REQUEST` + field error |
| `HttpMessageNotReadableException` | malformed JSON, body parse 실패 | `INVALID_REQUEST`, field가 불명확하면 errors 생략 |
| `MissingServletRequestParameterException` | required query parameter 누락 | `INVALID_REQUEST` + parameter field error |
| `MissingRequestHeaderException` | required header 누락 | `INVALID_REQUEST` + header field error |

Field error rules:

- field path는 Spring binding path를 따른다. 예: `companySlugs[0]`.
- query parameter는 parameter name을 field로 둔다.
- body parse 실패처럼 field를 특정하기 어려우면 `errors`를 생략하거나 `field: "body"`를 사용한다. 프로젝트에서 하나로 고정한다.
- `rejectedValue`는 기본적으로 생략한다.
- `rejectedValue`를 쓰는 경우 문자열 길이를 제한하고 민감 field는 마스킹한다.
- validation annotation message는 프론트에 노출될 수 있으므로 내부 용어를 쓰지 않는다.
- enum mismatch에서 허용 값을 제공할 때는 public enum name/code만 노출한다.

Binder rules:

- public API request DTO는 필요한 field만 선언한다.
- admin form/model binding처럼 over-posting 위험이 있으면 `@InitBinder`의 `setAllowedFields`를 검토한다.
- 전역 binder로 모든 controller에 동일한 allowed field를 강제하지 않는다.
- binding 실패를 service까지 넘기지 않는다.

## Handler Structure

Recommended order:

1. `BusinessException`
2. validation/binding exceptions
3. security-related exceptions if they can reach MVC
4. Spring MVC infrastructure exceptions
5. fallback `Exception`

Rules:

- `@RestControllerAdvice`는 하나의 공통 error response shape만 반환한다.
- Spring `ResponseEntityExceptionHandler`를 상속할 수 있지만, 최종 payload는 프로젝트 `ErrorResponse`로 통일한다.
- fallback handler는 반드시 `INTERNAL_ERROR`와 generic message만 반환한다.
- `server.error.include-stacktrace`, `server.error.include-message`, `server.error.include-binding-errors`는 운영 환경에서 의도치 않게 내부 정보가 노출되지 않도록 `never` 또는 프로젝트 기준값으로 고정한다.
- Spring Security filter chain 예외는 `AuthenticationEntryPoint`, `AccessDeniedHandler`, safety-net filter에서 같은 `ErrorResponse` shape로 작성한다.

## Logging Rule

| Error Type | Log Level | Stack Trace | Response Message |
| --- | --- | --- | --- |
| validation/binding 400 | debug 또는 info | no | safe common message |
| expected business 4xx | info | no by default | `ErrorCode.message()` or safe override |
| conflict/retryable business | warn optional | no by default | safe message |
| security 401/403 | info 또는 warn | no by default | safe message |
| external service failure | warn/error | yes if needed | sanitized |
| unexpected 5xx | error | yes | `INTERNAL_ERROR.message()` |

Rules:

- 4xx를 모두 error log로 남기지 않는다. 사용자 입력 오류가 error log를 오염시킨다.
- 5xx는 traceId/requestId와 함께 stack trace를 남긴다.
- 로그에는 raw request body, Authorization header, cookie, token을 남기지 않는다.
- 응답 message와 log message를 분리한다.

## Documentation Rule

ErrorCode는 코드에만 있으면 안 된다. API 문서와 운영 문서에서 추적 가능해야 한다.

Required:

- 공통 ErrorCode catalog
- 도메인별 ErrorCode catalog
- endpoint별 발생 가능한 error response
- validation field error shape
- 인증/인가 실패 response
- fallback 5xx response

Swagger/OpenAPI rules:

- endpoint마다 대표 business error를 `@ApiResponse`에 명시한다.
- 모든 endpoint에 공통 `INVALID_REQUEST`, `INTERNAL_ERROR`를 기계적으로 붙이되, 설명은 발생 조건을 구체적으로 쓴다.
- error example은 실제 code/message와 일치해야 한다.
- validation error example에는 최소 1개 field error를 포함한다.
- 프론트가 error code만 보고 사용자 행동을 결정할 수 있도록 description에 처리 기준을 적는다.

Change rules:

- ErrorCode 추가는 문서와 Swagger example을 함께 수정한다.
- ErrorCode 삭제는 금지한다. deprecated 처리 후 유지한다.
- message 변경은 breaking change는 아니지만 사용자 화면 문구에 영향을 주므로 PR에 명시한다.
- HTTP status 변경은 breaking change로 취급한다.

## Test Rule

Required tests:

- `ErrorCode` code 중복 검사
- code naming pattern 검사: `^[A-Z][A-Z0-9_]*$`
- `httpStatus`, `code`, `message` null/blank 금지
- `BusinessException`이 ErrorCode를 유지하는지 검사
- `MethodArgumentNotValidException` response shape 검사
- `BindException` 또는 query DTO validation response shape 검사
- type mismatch response shape 검사
- malformed JSON response shape 검사
- fallback `Exception`이 raw message를 노출하지 않는지 검사
- 5xx logging 또는 traceId가 운영 기준과 맞는지 검사
- Swagger error example이 실제 ErrorCode와 어긋나지 않는지 가능한 범위에서 검사

## Checklist

- 프론트가 `code`만 보고 분기할 수 있는가?
- business error와 validation error가 분리되어 있는가?
- custom exception을 남발하지 않고 Spring validation/binding 예외는 공통 handler에서 처리하는가?
- fallback 5xx가 내부 message, stack trace, SQL을 노출하지 않는가?
- field error에 민감 rejected value가 포함되지 않는가?
- ErrorCode 추가/변경이 Swagger와 문서에 반영되는가?
- 4xx가 error log를 과도하게 만들지 않는가?
- Security filter chain error도 같은 response shape를 쓰는가?

## References

- [api-design-convention.md](api-design-convention.md)
- [common-api-dto-convention.md](common-api-dto-convention.md)
- [controller-writing-convention.md](controller-writing-convention.md)
- [security-exception-convention.md](security-exception-convention.md)
- [swagger-documentation-convention.md](swagger-documentation-convention.md)
- [business-exception-and-error-code-snippet.md](../snippets/business-exception-and-error-code-snippet.md)
- [Spring Framework MVC Exception Handling](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-controller/ann-exceptionhandler.html)
- [Spring Boot Servlet Error Handling](https://docs.spring.io/spring-boot/reference/web/servlet.html)
