# Controller and Error Handling Snippet

## Use

- Spring MVC `@RestController` 작성
- query request DTO 기본값/검증 처리
- service 위임
- 공통 error response와 `GlobalExceptionHandler` 연결
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

## Error Handling Reference

Controller 예제에는 error handling 구현을 중복 작성하지 않는다.
공통 `ErrorCode`, `BusinessException`, `ErrorResponse`, `FieldErrorMapper`, `GlobalExceptionHandler`는 [business-exception-and-error-code-snippet.md](business-exception-and-error-code-snippet.md)를 사용한다.

## Rules

- Controller는 service만 호출한다.
- request DTO에서 기본값을 확정하고 service query/command로 변환한다.
- page size 같은 숫자는 상수나 properties로 둔다.
- BusinessException은 ErrorCode를 반드시 가진다.
- validation error는 field-level list로 반환한다.
- fallback exception은 sanitized message만 반환한다.

## References

- [controller-writing-convention.md](../convention/controller-writing-convention.md)
- [common-api-dto-convention.md](../convention/common-api-dto-convention.md)
- [common-api-dto-snippet.md](common-api-dto-snippet.md)
- [error-handling-convention.md](../convention/error-handling-convention.md)
- [business-exception-and-error-code-snippet.md](business-exception-and-error-code-snippet.md)
