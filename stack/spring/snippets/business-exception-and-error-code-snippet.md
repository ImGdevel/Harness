# Spring ErrorCode And Business Exception Snippet

## Use

- 프로젝트 공통 `ErrorCode`, `BusinessException`, `ErrorResponse`, `GlobalExceptionHandler`를 만들 때
- validation/binding/type mismatch 예외를 동일한 JSON error contract로 반환할 때
- 프론트가 `code` 기준으로 안정적으로 분기해야 할 때

## Package Layout

```text
common/error/
  ErrorCode.java
  ErrorLogLevel.java
  CommonErrorCode.java
  BusinessException.java
  ErrorResponse.java
  FieldErrorResponse.java
  FieldErrorMapper.java
  ErrorResponseFactory.java
  TraceIdResolver.java
  GlobalExceptionHandler.java
```

## ErrorCode

```java
package com.example.common.error;

import org.springframework.http.HttpStatus;

public interface ErrorCode {

    HttpStatus httpStatus();

    String code();

    String message();

    default ErrorLogLevel logLevel() {
        return httpStatus().is5xxServerError() ? ErrorLogLevel.ERROR : ErrorLogLevel.INFO;
    }
}
```

```java
package com.example.common.error;

public enum ErrorLogLevel {
    DEBUG,
    INFO,
    WARN,
    ERROR
}
```

```java
package com.example.common.error;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

@RequiredArgsConstructor
public enum CommonErrorCode implements ErrorCode {
    INVALID_REQUEST(HttpStatus.BAD_REQUEST, "INVALID_REQUEST", "요청 값이 올바르지 않습니다.", ErrorLogLevel.INFO),
    UNAUTHORIZED(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", "인증이 필요합니다.", ErrorLogLevel.INFO),
    FORBIDDEN(HttpStatus.FORBIDDEN, "FORBIDDEN", "접근 권한이 없습니다.", ErrorLogLevel.INFO),
    RESOURCE_NOT_FOUND(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "요청한 리소스를 찾을 수 없습니다.", ErrorLogLevel.INFO),
    METHOD_NOT_ALLOWED(HttpStatus.METHOD_NOT_ALLOWED, "METHOD_NOT_ALLOWED", "지원하지 않는 HTTP 메서드입니다.", ErrorLogLevel.INFO),
    CONFLICT(HttpStatus.CONFLICT, "CONFLICT", "요청 상태가 현재 리소스 상태와 충돌합니다.", ErrorLogLevel.INFO),
    UNSUPPORTED_MEDIA_TYPE(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "UNSUPPORTED_MEDIA_TYPE", "지원하지 않는 Content-Type입니다.", ErrorLogLevel.INFO),
    TOO_MANY_REQUESTS(HttpStatus.TOO_MANY_REQUESTS, "TOO_MANY_REQUESTS", "요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.", ErrorLogLevel.WARN),
    INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", "예상하지 못한 오류가 발생했습니다.", ErrorLogLevel.ERROR),
    EXTERNAL_SERVICE_UNAVAILABLE(HttpStatus.SERVICE_UNAVAILABLE, "EXTERNAL_SERVICE_UNAVAILABLE", "외부 서비스가 일시적으로 불안정합니다.", ErrorLogLevel.WARN);

    private final HttpStatus httpStatus;
    private final String code;
    private final String message;
    private final ErrorLogLevel logLevel;

    @Override
    public HttpStatus httpStatus() {
        return httpStatus;
    }

    @Override
    public String code() {
        return code;
    }

    @Override
    public String message() {
        return message;
    }

    @Override
    public ErrorLogLevel logLevel() {
        return logLevel;
    }
}
```

## Domain ErrorCode

```java
package com.example.post.error;

import com.example.common.error.ErrorCode;
import com.example.common.error.ErrorLogLevel;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

@RequiredArgsConstructor
public enum PostErrorCode implements ErrorCode {
    PUBLIC_POST_NOT_FOUND(HttpStatus.NOT_FOUND, "PUBLIC_POST_NOT_FOUND", "기술 블로그 글을 찾을 수 없습니다.", ErrorLogLevel.INFO),
    PUBLIC_POST_HIDDEN(HttpStatus.NOT_FOUND, "PUBLIC_POST_HIDDEN", "공개된 기술 블로그 글을 찾을 수 없습니다.", ErrorLogLevel.INFO),
    POST_ALREADY_PUBLISHED(HttpStatus.CONFLICT, "POST_ALREADY_PUBLISHED", "이미 게시된 글입니다.", ErrorLogLevel.INFO);

    private final HttpStatus httpStatus;
    private final String code;
    private final String message;
    private final ErrorLogLevel logLevel;

    @Override
    public HttpStatus httpStatus() {
        return httpStatus;
    }

    @Override
    public String code() {
        return code;
    }

    @Override
    public String message() {
        return message;
    }

    @Override
    public ErrorLogLevel logLevel() {
        return logLevel;
    }
}
```

## BusinessException

```java
package com.example.common.error;

import lombok.Getter;

@Getter
public class BusinessException extends RuntimeException {

    private final ErrorCode errorCode;
    private final String safeMessage;

    public BusinessException(ErrorCode errorCode) {
        this(errorCode, errorCode.message(), null);
    }

    public BusinessException(ErrorCode errorCode, String safeMessage) {
        this(errorCode, safeMessage, null);
    }

    public BusinessException(ErrorCode errorCode, Throwable cause) {
        this(errorCode, errorCode.message(), cause);
    }

    public BusinessException(ErrorCode errorCode, String safeMessage, Throwable cause) {
        super(safeMessage, cause);
        this.errorCode = errorCode;
        this.safeMessage = safeMessage == null || safeMessage.isBlank() ? errorCode.message() : safeMessage;
    }
}
```

Rules:

- `safeMessage`는 프론트에 노출 가능한 문장만 넣는다.
- 내부 exception message, SQL, upstream raw body를 `safeMessage`로 넘기지 않는다.
- cause는 로그 원인 추적용으로만 사용한다.

## Error Response DTO

```java
package com.example.common.error;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_EMPTY)
public record ErrorResponse(
        String code,
        String message,
        List<FieldErrorResponse> errors,
        String traceId
) {
    public ErrorResponse {
        errors = List.copyOf(errors == null ? List.of() : errors);
    }

    public static ErrorResponse of(ErrorCode errorCode, String message, String traceId) {
        return new ErrorResponse(errorCode.code(), message, List.of(), traceId);
    }

    public static ErrorResponse of(ErrorCode errorCode, String message, List<FieldErrorResponse> errors, String traceId) {
        return new ErrorResponse(errorCode.code(), message, errors, traceId);
    }
}
```

```java
package com.example.common.error;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record FieldErrorResponse(
        String field,
        String reason,
        String rejectedValue
) {
    public static FieldErrorResponse of(String field, String reason) {
        return new FieldErrorResponse(field, reason, null);
    }

    public static FieldErrorResponse of(String field, String reason, String rejectedValue) {
        return new FieldErrorResponse(field, reason, rejectedValue);
    }
}
```

## FieldErrorMapper

```java
package com.example.common.error;

import jakarta.validation.ConstraintViolation;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import org.springframework.stereotype.Component;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.validation.ObjectError;

@Component
public class FieldErrorMapper {

    private static final int MAX_REJECTED_VALUE_LENGTH = 80;
    private static final Set<String> SENSITIVE_FIELD_KEYWORDS = Set.of(
            "password",
            "token",
            "secret",
            "credential",
            "authorization",
            "cookie",
            "email",
            "phone"
    );

    public List<FieldErrorResponse> fromBindingResult(BindingResult bindingResult) {
        List<FieldErrorResponse> errors = new ArrayList<>();
        errors.addAll(bindingResult.getFieldErrors().stream()
                .map(this::fromFieldError)
                .toList());
        errors.addAll(bindingResult.getGlobalErrors().stream()
                .map(this::fromObjectError)
                .toList());
        return errors;
    }

    public List<FieldErrorResponse> fromConstraintViolations(Set<ConstraintViolation<?>> violations) {
        return violations.stream()
                .map(violation -> FieldErrorResponse.of(
                        violation.getPropertyPath().toString(),
                        safeReason(violation.getMessage())
                ))
                .toList();
    }

    public FieldErrorResponse fromTypeMismatch(String field, Object rejectedValue, String requiredTypeName) {
        String reason = requiredTypeName == null
                ? "요청 값의 타입이 올바르지 않습니다."
                : requiredTypeName + " 형식으로 입력해 주세요.";
        return FieldErrorResponse.of(field, reason, safeRejectedValue(field, rejectedValue));
    }

    public FieldErrorResponse fromMissingValue(String field) {
        return FieldErrorResponse.of(field, "필수 요청 값입니다.");
    }

    private FieldErrorResponse fromFieldError(FieldError error) {
        return FieldErrorResponse.of(
                error.getField(),
                safeReason(error.getDefaultMessage()),
                safeRejectedValue(error.getField(), error.getRejectedValue())
        );
    }

    private FieldErrorResponse fromObjectError(ObjectError error) {
        return FieldErrorResponse.of(error.getObjectName(), safeReason(error.getDefaultMessage()));
    }

    private String safeReason(String reason) {
        if (reason == null || reason.isBlank()) {
            return "요청 값이 올바르지 않습니다.";
        }
        return reason;
    }

    private String safeRejectedValue(String field, Object rejectedValue) {
        if (rejectedValue == null || isSensitiveField(field)) {
            return null;
        }
        String value = String.valueOf(rejectedValue);
        if (value.length() <= MAX_REJECTED_VALUE_LENGTH) {
            return value;
        }
        return value.substring(0, MAX_REJECTED_VALUE_LENGTH) + "...";
    }

    private boolean isSensitiveField(String field) {
        if (field == null) {
            return false;
        }
        String normalized = field.toLowerCase(Locale.ROOT);
        for (String keyword : SENSITIVE_FIELD_KEYWORDS) {
            if (normalized.contains(keyword)) {
                return true;
            }
        }
        return false;
    }
}
```

## TraceIdResolver

```java
package com.example.common.error;

import org.slf4j.MDC;
import org.springframework.stereotype.Component;

@Component
public class TraceIdResolver {

    public String resolve() {
        String traceId = MDC.get("traceId");
        if (traceId != null && !traceId.isBlank()) {
            return traceId;
        }
        String requestId = MDC.get("requestId");
        return requestId == null || requestId.isBlank() ? null : requestId;
    }
}
```

## ErrorResponseFactory

```java
package com.example.common.error;

import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class ErrorResponseFactory {

    private final TraceIdResolver traceIdResolver;

    public ErrorResponse from(ErrorCode errorCode) {
        return ErrorResponse.of(errorCode, errorCode.message(), traceIdResolver.resolve());
    }

    public ErrorResponse from(ErrorCode errorCode, String safeMessage) {
        return ErrorResponse.of(errorCode, safeMessage, traceIdResolver.resolve());
    }

    public ErrorResponse from(ErrorCode errorCode, List<FieldErrorResponse> errors) {
        return ErrorResponse.of(errorCode, errorCode.message(), errors, traceIdResolver.resolve());
    }
}
```

## GlobalExceptionHandler

```java
package com.example.common.error;

import jakarta.validation.ConstraintViolationException;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.validation.BindException;

@Slf4j
@RestControllerAdvice
@RequiredArgsConstructor
public class GlobalExceptionHandler {

    private final FieldErrorMapper fieldErrorMapper;
    private final ErrorResponseFactory errorResponseFactory;

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ErrorResponse> handleBusinessException(BusinessException exception) {
        ErrorCode errorCode = exception.getErrorCode();
        logByLevel(errorCode, exception);
        return ResponseEntity
                .status(errorCode.httpStatus())
                .body(errorResponseFactory.from(errorCode, exception.getSafeMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleMethodArgumentNotValid(MethodArgumentNotValidException exception) {
        List<FieldErrorResponse> errors = fieldErrorMapper.fromBindingResult(exception.getBindingResult());
        return invalidRequest(errors);
    }

    @ExceptionHandler(BindException.class)
    public ResponseEntity<ErrorResponse> handleBindException(BindException exception) {
        List<FieldErrorResponse> errors = fieldErrorMapper.fromBindingResult(exception.getBindingResult());
        return invalidRequest(errors);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> handleConstraintViolation(ConstraintViolationException exception) {
        List<FieldErrorResponse> errors = fieldErrorMapper.fromConstraintViolations(exception.getConstraintViolations());
        return invalidRequest(errors);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ErrorResponse> handleTypeMismatch(MethodArgumentTypeMismatchException exception) {
        String requiredType = exception.getRequiredType() == null ? null : exception.getRequiredType().getSimpleName();
        FieldErrorResponse error = fieldErrorMapper.fromTypeMismatch(
                exception.getName(),
                exception.getValue(),
                requiredType
        );
        return invalidRequest(List.of(error));
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ErrorResponse> handleMissingServletRequestParameter(MissingServletRequestParameterException exception) {
        return invalidRequest(List.of(fieldErrorMapper.fromMissingValue(exception.getParameterName())));
    }

    @ExceptionHandler(MissingRequestHeaderException.class)
    public ResponseEntity<ErrorResponse> handleMissingRequestHeader(MissingRequestHeaderException exception) {
        return invalidRequest(List.of(fieldErrorMapper.fromMissingValue(exception.getHeaderName())));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleHttpMessageNotReadable(HttpMessageNotReadableException exception) {
        log.debug("Malformed request body", exception);
        return invalidRequest(List.of(FieldErrorResponse.of("body", "요청 본문을 읽을 수 없습니다.")));
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ErrorResponse> handleMethodNotSupported(HttpRequestMethodNotSupportedException exception) {
        return ResponseEntity
                .status(CommonErrorCode.METHOD_NOT_ALLOWED.httpStatus())
                .body(errorResponseFactory.from(CommonErrorCode.METHOD_NOT_ALLOWED));
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<ErrorResponse> handleMediaTypeNotSupported(HttpMediaTypeNotSupportedException exception) {
        return ResponseEntity
                .status(CommonErrorCode.UNSUPPORTED_MEDIA_TYPE.httpStatus())
                .body(errorResponseFactory.from(CommonErrorCode.UNSUPPORTED_MEDIA_TYPE));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnexpectedException(Exception exception) {
        log.error("Unexpected server error", exception);
        return ResponseEntity
                .status(CommonErrorCode.INTERNAL_ERROR.httpStatus())
                .body(errorResponseFactory.from(CommonErrorCode.INTERNAL_ERROR));
    }

    private ResponseEntity<ErrorResponse> invalidRequest(List<FieldErrorResponse> errors) {
        return ResponseEntity
                .badRequest()
                .body(errorResponseFactory.from(CommonErrorCode.INVALID_REQUEST, errors));
    }

    private void logByLevel(ErrorCode errorCode, BusinessException exception) {
        switch (errorCode.logLevel()) {
            case DEBUG -> log.debug("{}: {}", errorCode.code(), exception.getSafeMessage());
            case INFO -> log.info("{}: {}", errorCode.code(), exception.getSafeMessage());
            case WARN -> log.warn("{}: {}", errorCode.code(), exception.getSafeMessage());
            case ERROR -> log.error("{}: {}", errorCode.code(), exception.getSafeMessage(), exception);
        }
    }
}
```

## Spring Boot Error Exposure

```yaml
server:
  error:
    include-message: never
    include-binding-errors: never
    include-stacktrace: never
    include-exception: false
```

Rules:

- 운영 환경에서는 Spring Boot 기본 `/error`가 내부 정보를 노출하지 않게 막는다.
- 실제 API error response는 `GlobalExceptionHandler`와 Security error handler가 생성한다.
- 개발 환경에서만 include 옵션을 열고 싶다면 profile별 설정에 명확히 남긴다.

## Service Usage

```java
public PublicPostDetailResult getPublicPost(String slug) {
    return publicPostRepository.findPublishedBySlug(slug)
            .map(PublicPostDetailResult::from)
            .orElseThrow(() -> new BusinessException(PostErrorCode.PUBLIC_POST_NOT_FOUND));
}
```

```java
public void publish() {
    if (this.status == PostStatus.PUBLISHED) {
        throw new IllegalStateException("이미 게시된 entity 상태입니다.");
    }
    this.status = PostStatus.PUBLISHED;
}
```

Rules:

- service/application layer는 API에 의미 있는 실패를 `BusinessException(ErrorCode)`로 변환한다.
- entity 내부 local guard는 `IllegalArgumentException` 또는 `IllegalStateException`을 사용할 수 있다.
- entity exception을 그대로 API response로 노출하지 않는다.

## ErrorCode Convention Test

```java
package com.example.common.error;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Arrays;
import java.util.List;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

class ErrorCodeConventionTest {

    private static final Pattern ERROR_CODE_PATTERN = Pattern.compile("^[A-Z][A-Z0-9_]*$");

    @Test
    void commonErrorCodes_followConvention() {
        List<CommonErrorCode> values = Arrays.asList(CommonErrorCode.values());

        assertThat(values)
                .extracting(CommonErrorCode::code)
                .doesNotHaveDuplicates()
                .allMatch(code -> ERROR_CODE_PATTERN.matcher(code).matches());

        assertThat(values)
                .allSatisfy(errorCode -> {
                    assertThat(errorCode.httpStatus()).isNotNull();
                    assertThat(errorCode.message()).isNotBlank();
                });
    }
}
```

## Rules

- `ErrorCode`는 HTTP status, public code, safe message를 가진다.
- `BusinessException`은 예상 가능한 업무 실패에만 사용한다.
- validation/binding/type mismatch는 Spring 예외를 그대로 공통 handler에서 변환한다.
- fallback `Exception`의 raw message는 응답하지 않는다.
- field error의 `rejectedValue`는 기본적으로 생략하고, 필요할 때만 안전하게 제한한다.
- Security filter chain 예외는 별도 entry point/access denied handler에서 같은 `ErrorResponse` shape로 반환한다.
- ErrorCode 추가 시 Swagger, API 문서, 테스트를 함께 갱신한다.

## References

- [error-handling-convention.md](../convention/error-handling-convention.md)
- [common-api-dto-convention.md](../convention/common-api-dto-convention.md)
- [security-entrypoint-and-access-denied-snippet.md](security-entrypoint-and-access-denied-snippet.md)
- [swagger-custom-error-response-snippet.md](swagger-custom-error-response-snippet.md)
