# Spring Business Exception and ErrorCode Snippet

## Use

- 도메인 예외를 코드/HTTP 상태와 함께 통일적으로 전달할 때
- 엔티티 가드에서 비즈니스 규칙 위반을 API 계약 단위로 묶을 때

## Snippet

```java
public interface ErrorCode {
    HttpStatus getHttpStatus();
    String getCode();
    String getMessage();
}
```

```java
@Getter
@RequiredArgsConstructor
public enum CommonErrorCode implements ErrorCode {
    INVALID_REQUEST(HttpStatus.BAD_REQUEST, "INVALID_REQUEST", "invalid request"),
    POST_NOT_FOUND(HttpStatus.NOT_FOUND, "POST_NOT_FOUND", "post not found"),
    INVALID_DOMAIN_STATE(HttpStatus.INTERNAL_SERVER_ERROR, "INVALID_DOMAIN_STATE", "invalid domain state");

    private final HttpStatus httpStatus;
    private final String code;
    private final String message;
}
```

```java
@Getter
public class BusinessException extends RuntimeException {
    private final ErrorCode errorCode;

    public BusinessException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.errorCode = errorCode;
    }

    public BusinessException(ErrorCode errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }
}
```

```java
public void publish() {
    if (this.status == PostStatus.PUBLISHED) {
        throw new BusinessException(PostErrorCode.ALREADY_PUBLISHED);
    }
    this.status = PostStatus.PUBLISHED;
}
```

```java
public static Post create(String title, String content) {
    if (!StringUtils.hasText(title)) {
        throw new BusinessException(CommonErrorCode.INVALID_REQUEST);
    }
    return new Post(...);
}
```

## Rules

- 기본 검증 가드:
  - 입력값 null/blank/length: `IllegalArgumentException` 또는 `Assert`로 빠르게 실패
  - 비즈니스 규칙 충돌: `BusinessException(ErrorCode)`를 사용
- 에러 코드는 API에서 분기 가능하도록 고정 문자열(`getCode`)을 둔다.
- `GlobalExceptionHandler`는 `BusinessException`, 검증 예외, 예기치 않은 예외를 분리한다.

## References

- [entity-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/entity/entity-design-convention.md>)
