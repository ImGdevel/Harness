# Spring Business Exception and ErrorCode Snippet

## Use

- stable API error contract
- `ErrorCode`
- `BusinessException`

## Snippet

```java
public interface ErrorCode {
    HttpStatus getStatus();
    String getCode();
    String getMessage();
}
```

```java
@Getter
@RequiredArgsConstructor
public enum MemberErrorCode implements ErrorCode {
    MEMBER_NOT_FOUND(HttpStatus.NOT_FOUND, "MEMBER_NOT_FOUND", "member not found"),
    DUPLICATE_EMAIL(HttpStatus.CONFLICT, "DUPLICATE_EMAIL", "email already exists");

    private final HttpStatus status;
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
}
```

## Rules

- Branch on `code`.
- Keep HTTP status and domain code separate.
- Reuse one `BusinessException` shape.

## References

- [error-handling-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/error-handling-convention.md>)
