# Spring Swagger Docs Interface Snippet

## Use

- Controller implementation과 Swagger annotation 분리
- `@Tag`, `@Operation`, `@ApiResponse`, `@ParameterObject`
- 프론트 친화적인 API 설명 작성
- endpoint별 error group 연결

## Docs Interface

```java
@SwaggerTagOrder(10)
@Tag(
        name = "Public Posts",
        description = "메인 피드, 글 상세, 필터 UI에서 사용하는 공개 기술 블로그 글 조회 API"
)
public interface PublicPostApiDocs {

    @Operation(
            summary = "최신 기술 블로그 글 목록 조회",
            description = """
                    메인 화면의 최신 기술 블로그 피드에서 호출한다.

                    - 조회 대상: 공개 상태의 아카이브 글
                    - 검색: q는 공백 기준 token AND 검색
                    - 필터: company/job/tag는 그룹 내부 OR, 그룹 간 AND
                    - 정렬: latest 기본, relevance는 검색어가 있을 때만 의미가 있다
                    - 기본값: page=0, size=24, 최대 size=100
                    - 빈 결과: 정상 응답이며 프론트는 empty state를 표시한다
                    - 인증: 불필요
                    """
    )
    @ApiResponse(
            responseCode = "200",
            description = "공개 글 목록 조회 성공",
            content = @Content(
                    mediaType = "application/json",
                    schema = @Schema(implementation = PublicPostPageResponse.class),
                    examples = @ExampleObject(
                            name = "latest-feed",
                            summary = "최신 글 피드 예시",
                            value = """
                                    {
                                      "items": [
                                        {
                                          "slug": "naver-spring-boot-ops-20260502",
                                          "title": "Spring Boot 3.5 운영 체크리스트",
                                          "companyName": "NAVER",
                                          "publishedAt": "2026-05-02T10:15:30Z"
                                        }
                                      ],
                                      "page": 0,
                                      "size": 24,
                                      "totalElements": 128,
                                      "totalPages": 6,
                                      "first": true,
                                      "last": false
                                    }
                                    """
                    )
            )
    )
    @CustomErrorResponseDescription(
            value = PublicPostSwaggerErrorResponseDescription.class,
            group = "PUBLIC_POST_LIST"
    )
    PageResponse<PublicPostListItemResponse> getPosts(@ParameterObject @Valid PublicPostSearchRequest request);

    @Operation(
            summary = "기술 블로그 글 상세 조회",
            description = """
                    글 목록에서 특정 글을 선택했을 때 상세 화면에서 호출한다.

                    - 조회 대상: slug가 일치하고 공개 상태인 아카이브 글
                    - 원문 본문은 제공하지 않고 AI 요약과 원문 링크를 제공한다
                    - 요약 생성 실패 시 summary.state가 failed로 내려갈 수 있다
                    - 인증: 불필요
                    - 404 처리: 프론트는 Not Found 화면 또는 목록 복귀 CTA를 표시한다
                    """
    )
    @ApiResponse(
            responseCode = "200",
            description = "공개 글 상세 조회 성공",
            content = @Content(
                    mediaType = "application/json",
                    schema = @Schema(implementation = PublicPostDetailResponse.class)
            )
    )
    @CustomErrorResponseDescription(
            value = PublicPostSwaggerErrorResponseDescription.class,
            group = "PUBLIC_POST_DETAIL"
    )
    PublicPostDetailResponse getPost(
            @Parameter(
                    description = "공개 글 slug",
                    required = true,
                    example = "naver-spring-boot-ops-20260502"
            )
            String slug
    );
}
```

## Controller Implementation

```java
@Validated
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/public/posts")
public class PublicPostController implements PublicPostApiDocs {

    private final PublicPostQueryService publicPostQueryService;

    @Override
    @GetMapping
    public PageResponse<PublicPostListItemResponse> getPosts(
            @ParameterObject @Valid PublicPostSearchRequest request
    ) {
        return publicPostQueryService.getPosts(request.toQuery());
    }

    @Override
    @GetMapping("/{slug}")
    public PublicPostDetailResponse getPost(@PathVariable @NotBlank String slug) {
        return publicPostQueryService.getPost(slug);
    }
}
```

## Request DTO Schema

```java
@Schema(description = "공개 글 목록 검색 조건")
public record PublicPostSearchRequest(
        @Parameter(description = "검색어. 공백 기준 token AND 검색", example = "Spring Boot 운영")
        String q,

        @Parameter(description = "기업 slug 반복 필터. 예: company=naver&company=kakao")
        List<String> company,

        @Parameter(description = "직군 코드 반복 필터", example = "BACKEND")
        List<String> job,

        @Parameter(description = "주제 태그 slug 반복 필터", example = "spring-boot")
        List<String> tag,

        @Parameter(description = "0부터 시작하는 페이지 번호", example = "0")
        Integer page,

        @Parameter(description = "페이지 크기. 기본 24, 최대 100", example = "24")
        Integer size
) {
}
```

## Response DTO Schema

```java
@Schema(description = "공개 글 목록 item 응답")
public record PublicPostListItemResponse(
        @Schema(description = "글 slug", example = "naver-spring-boot-ops-20260502")
        String slug,

        @Schema(description = "원문 글 제목", example = "Spring Boot 3.5 운영 체크리스트")
        String title,

        @Schema(description = "대표 기업명", example = "NAVER")
        String companyName,

        @Schema(description = "게시 시각. ISO-8601 UTC", example = "2026-05-02T10:15:30Z")
        Instant publishedAt
) {
}
```

## Rules

- Swagger annotation은 docs interface에 둔다.
- controller method signature와 docs interface method signature를 일치시킨다.
- summary, description, success response, error response, parameter 설명을 모두 작성한다.
- example은 실제 서비스와 유사한 값으로 작성한다.
- query DTO는 `@ParameterObject`로 펼친다.
- DTO field는 `@Schema`로 설명한다.
- error response는 `@CustomErrorResponseDescription`로 endpoint별 group을 연결한다.

## References

- [swagger-documentation-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/swagger-documentation-convention.md>)
- [swagger-custom-error-response-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/swagger-custom-error-response-snippet.md>)
