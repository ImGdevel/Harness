# Controller and Error Handling Snippet

## Use

- Spring MVC `@RestController` 작성
- query request DTO 기본값/검증 처리
- service 위임
- 공통 error response와 `GlobalExceptionHandler` 작성
- 공통 DTO는 `common-api-dto-snippet.md`를 우선 참고

## Controller

```java
@Validated
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/public/posts")
public class PublicPostController {

    private final PublicPostQueryService publicPostQueryService;

    @GetMapping
    public PageResponse<PublicPostListItemResponse> getPosts(@Valid PublicPostSearchRequest request) {
        return publicPostQueryService.getPosts(request.toQuery());
    }

    @GetMapping("/{slug}")
    public PublicPostDetailResponse getPost(@PathVariable @NotBlank String slug) {
        return publicPostQueryService.getPost(slug);
    }
}
```

## Query Request DTO

```java
public record PublicPostSearchRequest(
        String q,
        List<String> company,
        List<String> job,
        List<String> tag,
        Integer page,
        Integer size
) {
    private static final int DEFAULT_PAGE = 0;
    private static final int DEFAULT_SIZE = 24;
    private static final int MAX_SIZE = 100;

    public PublicPostQuery toQuery() {
        int normalizedPage = page == null ? DEFAULT_PAGE : page;
        int normalizedSize = size == null ? DEFAULT_SIZE : size;
        if (normalizedPage < 0) {
            throw new BusinessException(CommonErrorCode.INVALID_REQUEST, "page must be greater than or equal to 0");
        }
        if (normalizedSize < 1 || normalizedSize > MAX_SIZE) {
            throw new BusinessException(CommonErrorCode.INVALID_REQUEST, "size must be between 1 and 100");
        }
        return new PublicPostQuery(
                blankToNull(q),
                nullToEmpty(company),
                nullToEmpty(job),
                nullToEmpty(tag),
                normalizedPage,
                normalizedSize
        );
    }
}
```

## Error Code

```java
public interface ErrorCode {
    HttpStatus httpStatus();
    String code();
    String message();
}
```

```java
@Getter
@RequiredArgsConstructor
public enum CommonErrorCode implements ErrorCode {
    INVALID_REQUEST(HttpStatus.BAD_REQUEST, "INVALID_REQUEST", "요청 값이 올바르지 않습니다."),
    INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", "예상하지 못한 오류가 발생했습니다.");

    private final HttpStatus httpStatus;
    private final String code;
    private final String message;
}
```

## Error Response

```java
@JsonInclude(JsonInclude.Include.NON_EMPTY)
public record ErrorResponse(
        String code,
        String message,
        List<FieldErrorResponse> errors
) {
    public static ErrorResponse of(ErrorCode errorCode) {
        return new ErrorResponse(errorCode.code(), errorCode.message(), List.of());
    }

    public static ErrorResponse of(ErrorCode errorCode, List<FieldErrorResponse> errors) {
        return new ErrorResponse(errorCode.code(), errorCode.message(), errors);
    }
}
```

```java
public record FieldErrorResponse(
        String field,
        String reason
) {
}
```

## Global Exception Handler

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    ResponseEntity<ErrorResponse> handleBusinessException(BusinessException exception) {
        ErrorCode errorCode = exception.getErrorCode();
        return ResponseEntity
                .status(errorCode.httpStatus())
                .body(ErrorResponse.of(errorCode));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ErrorResponse> handleMethodArgumentNotValid(MethodArgumentNotValidException exception) {
        List<FieldErrorResponse> errors = exception.getBindingResult().getFieldErrors().stream()
                .map(error -> new FieldErrorResponse(error.getField(), error.getDefaultMessage()))
                .toList();
        return ResponseEntity.badRequest().body(ErrorResponse.of(CommonErrorCode.INVALID_REQUEST, errors));
    }

    @ExceptionHandler(BindException.class)
    ResponseEntity<ErrorResponse> handleBindException(BindException exception) {
        List<FieldErrorResponse> errors = exception.getBindingResult().getFieldErrors().stream()
                .map(error -> new FieldErrorResponse(error.getField(), error.getDefaultMessage()))
                .toList();
        return ResponseEntity.badRequest().body(ErrorResponse.of(CommonErrorCode.INVALID_REQUEST, errors));
    }
}
```

## Rules

- Controller는 service만 호출한다.
- request DTO에서 기본값을 확정하고 service query/command로 변환한다.
- page size 같은 숫자는 상수나 properties로 둔다.
- BusinessException은 ErrorCode를 반드시 가진다.
- validation error는 field-level list로 반환한다.
- fallback exception은 sanitized message만 반환한다.

## References

- [controller-writing-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/controller-writing-convention.md>)
- [common-api-dto-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/common-api-dto-convention.md>)
- [common-api-dto-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/common-api-dto-snippet.md>)
- [error-handling-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/error-handling-convention.md>)
