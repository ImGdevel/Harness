# Spring Swagger Custom Error Response Snippet

## Use

- repeated error response docs
- `OperationCustomizer`
- `ErrorCode`-driven examples

## Snippet

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface CustomErrorResponseDescription {

    Class<? extends SwaggerErrorResponseDescription> value();

    String group();
}

public interface SwaggerErrorResponseDescription {

    Set<ErrorCode> getErrorCodeList();

    default Set<ErrorCode> withCommonErrors(Set<ErrorCode> errorCodes) {
        Set<ErrorCode> merged = new LinkedHashSet<>(errorCodes);
        merged.add(CommonErrorCode.INTERNAL_SERVER_ERROR);
        return merged;
    }
}

@Getter
@RequiredArgsConstructor
public enum AuthSwaggerErrorResponseDescription implements SwaggerErrorResponseDescription {

    AUTH_TOKEN_REFRESH(Set.of(AuthErrorCode.INVALID_REFRESH_TOKEN));

    private final Set<ErrorCode> errorCodeList;

    @Override
    public Set<ErrorCode> getErrorCodeList() {
        return withCommonErrors(errorCodeList);
    }
}
```

## Rules

- Bind error groups to domain enums, not raw strings in config.
- Add shared common errors in one place.
- Reuse the same annotation across controllers.

## References

- [swagger-documentation-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/swagger-documentation-convention.md>)
