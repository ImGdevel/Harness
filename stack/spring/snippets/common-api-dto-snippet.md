# Common API DTO Snippet

## Use

- 공통 목록 응답 DTO
- 공통 페이지 응답 DTO
- 공통 cursor/slice 응답 DTO
- 공통 error 응답 DTO
- field validation error DTO

## ListResponse

```java
public record ListResponse<T>(
        List<T> items
) {
    public ListResponse {
        items = List.copyOf(items == null ? List.of() : items);
    }

    public static <T> ListResponse<T> of(List<T> items) {
        return new ListResponse<>(items);
    }
}
```

## PageResponse

```java
public record PageResponse<T>(
        List<T> items,
        int page,
        int size,
        long totalElements,
        int totalPages,
        boolean first,
        boolean last
) {
    public PageResponse {
        items = List.copyOf(items == null ? List.of() : items);
    }

    public static <T> PageResponse<T> of(List<T> items, Page<?> page) {
        return new PageResponse<>(
                items,
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.getTotalPages(),
                page.isFirst(),
                page.isLast()
        );
    }
}
```

## SliceResponse

```java
@JsonInclude(JsonInclude.Include.NON_NULL)
public record SliceResponse<T>(
        List<T> items,
        int size,
        boolean hasNext,
        String nextCursor
) {
    public SliceResponse {
        items = List.copyOf(items == null ? List.of() : items);
    }

    public static <T> SliceResponse<T> of(List<T> items, int size, boolean hasNext, String nextCursor) {
        return new SliceResponse<>(items, size, hasNext, nextCursor);
    }
}
```

## ErrorResponse

```java
@JsonInclude(JsonInclude.Include.NON_EMPTY)
public record ErrorResponse(
        String code,
        String message,
        List<FieldErrorResponse> errors
) {
    public ErrorResponse {
        errors = List.copyOf(errors == null ? List.of() : errors);
    }

    public static ErrorResponse of(ErrorCode errorCode) {
        return new ErrorResponse(errorCode.code(), errorCode.message(), List.of());
    }

    public static ErrorResponse of(ErrorCode errorCode, List<FieldErrorResponse> errors) {
        return new ErrorResponse(errorCode.code(), errorCode.message(), errors);
    }
}
```

## FieldErrorResponse

```java
@JsonInclude(JsonInclude.Include.NON_NULL)
public record FieldErrorResponse(
        String field,
        String reason,
        String rejectedValue
) {
    public static FieldErrorResponse of(String field, String reason) {
        return new FieldErrorResponse(field, reason, null);
    }

    public static FieldErrorResponse ofSafeRejectedValue(String field, String reason, Object rejectedValue) {
        return new FieldErrorResponse(field, reason, rejectedValue == null ? null : String.valueOf(rejectedValue));
    }
}
```

## Page Request Params

```java
public record PageRequestParams(
        Integer page,
        Integer size
) {
    private static final int DEFAULT_PAGE = 0;
    private static final int DEFAULT_SIZE = 24;
    private static final int MAX_SIZE = 100;

    public Pageable toPageable(Sort sort) {
        int normalizedPage = page == null ? DEFAULT_PAGE : page;
        int normalizedSize = size == null ? DEFAULT_SIZE : size;
        if (normalizedPage < 0) {
            throw new BusinessException(CommonErrorCode.INVALID_REQUEST, "page must be greater than or equal to 0");
        }
        if (normalizedSize < 1 || normalizedSize > MAX_SIZE) {
            throw new BusinessException(CommonErrorCode.INVALID_REQUEST, "size must be between 1 and 100");
        }
        return PageRequest.of(normalizedPage, normalizedSize, sort);
    }
}
```

## Rules

- 공통 DTO는 `common.dto` 또는 `common.error`에 둔다.
- DTO는 기본적으로 `record`로 작성한다.
- list field는 null 대신 empty list를 보장한다.
- Spring Data `Page`를 API 응답으로 직접 반환하지 않는다.
- validation error는 `ErrorResponse.errors`의 `FieldErrorResponse` list로 반환한다.
- `rejectedValue`는 민감하지 않은 값에만 사용한다.
- page 기본값과 최대값은 상수 또는 configuration properties로 관리한다.

## References

- [common-api-dto-convention.md](../convention/common-api-dto-convention.md)
- [controller-and-error-snippet.md](controller-and-error-snippet.md)
