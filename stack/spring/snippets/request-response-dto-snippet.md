# Request Response DTO Snippet

## Use

- 기능별 request DTO에서 command/query로 변환
- 기능별 response DTO에서 entity/result/projection을 API 응답으로 변환
- DTO 내부 mapper와 별도 assembler 분리 기준 예시

## Search Request To Query

```java
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

import java.util.List;

@Schema(description = "공개 기술 블로그 글 검색 요청")
public record PublicPostSearchRequest(
        @Parameter(description = "검색어. 공백 기준 token AND 검색", example = "Spring Boot 운영")
        String q,

        @Parameter(description = "기업 slug 반복 필터. 예: company=naver&company=kakao")
        List<String> company,

        @Parameter(description = "직군 slug 반복 필터. 예: job=backend&job=frontend")
        List<String> job,

        @Parameter(description = "주제 태그 slug 반복 필터. 예: tag=spring&tag=kafka")
        List<String> tag,

        @Parameter(description = "0부터 시작하는 페이지 번호", example = "0")
        @Min(value = 0, message = "page는 0 이상이어야 합니다.")
        Integer page,

        @Parameter(description = "페이지 크기. 기본 24, 최대 100", example = "24")
        @Min(value = 1, message = "size는 1 이상이어야 합니다.")
        @Max(value = 100, message = "size는 100 이하여야 합니다.")
        Integer size
) {
    private static final int DEFAULT_PAGE = 0;
    private static final int DEFAULT_SIZE = 24;

    public PublicPostSearchQuery toQuery() {
        return new PublicPostSearchQuery(
                normalizeKeyword(q),
                nullToEmpty(company),
                nullToEmpty(job),
                nullToEmpty(tag),
                page == null ? DEFAULT_PAGE : page,
                size == null ? DEFAULT_SIZE : size
        );
    }

    private static String normalizeKeyword(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private static List<String> nullToEmpty(List<String> values) {
        if (values == null) {
            return List.of();
        }
        return values.stream()
                .filter(value -> value != null && !value.isBlank())
                .map(String::trim)
                .toList();
    }
}

public record PublicPostSearchQuery(
        String keyword,
        List<String> companySlugs,
        List<String> jobSlugs,
        List<String> tagSlugs,
        int page,
        int size
) {
}
```

## Body Request To Command

```java
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;

@Schema(description = "구독 기업 추가 요청")
public record CompanySubscriptionAddRequest(
        @Schema(
                description = "추가할 기업 slug 목록",
                example = "[\"naver\", \"kakao\"]",
                requiredMode = Schema.RequiredMode.REQUIRED
        )
        @NotEmpty(message = "구독할 기업을 1개 이상 선택해야 합니다.")
        @Size(max = 30, message = "한 번에 추가할 수 있는 기업은 최대 30개입니다.")
        List<String> companySlugs
) {
    public CompanySubscriptionAddCommand toCommand(Long subscriberId) {
        return new CompanySubscriptionAddCommand(
                subscriberId,
                normalizeCompanySlugs(companySlugs)
        );
    }

    private static List<String> normalizeCompanySlugs(List<String> values) {
        if (values == null) {
            return List.of();
        }
        return values.stream()
                .filter(value -> value != null && !value.isBlank())
                .map(String::trim)
                .distinct()
                .toList();
    }
}

public record CompanySubscriptionAddCommand(
        Long subscriberId,
        List<String> companySlugs
) {
}
```

## Projection To List Item Response

```java
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;

@Schema(description = "공개 기술 블로그 글 목록 item 응답")
public record PublicPostListItemResponse(
        @Schema(description = "글 slug", example = "naver-spring-boot-ops-20260502")
        String slug,

        @Schema(description = "원문 글 제목", example = "Spring Boot 3.5 운영 체크리스트")
        String title,

        @Schema(description = "대표 기업명", example = "NAVER")
        String companyName,

        @Schema(description = "AI 요약 미리보기", example = "Spring Boot 3.5 운영 환경에서 확인해야 할 설정과 모니터링 기준을 정리한 글입니다.")
        String summaryPreview,

        @Schema(description = "원문 게시 시각. ISO-8601 UTC", example = "2026-05-02T10:15:30Z")
        Instant publishedAt
) {
    public static PublicPostListItemResponse from(PublicPostListQueryDto post) {
        return new PublicPostListItemResponse(
                post.slug(),
                post.title(),
                post.companyName(),
                post.summaryPreview(),
                post.publishedAt()
        );
    }
}

public record PublicPostListQueryDto(
        String slug,
        String title,
        String companyName,
        String summaryPreview,
        Instant publishedAt
) {
}
```

## Entity And Extra Values To Detail Response

```java
import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;

@Schema(description = "공개 기술 블로그 글 상세 응답")
public record PublicPostDetailResponse(
        @Schema(description = "글 slug", example = "naver-spring-boot-ops-20260502")
        String slug,

        @Schema(description = "원문 글 제목", example = "Spring Boot 3.5 운영 체크리스트")
        String title,

        @Schema(description = "대표 기업 정보")
        CompanySummaryResponse company,

        @Schema(description = "AI 요약 문단 목록")
        List<String> summaryParagraphs,

        @Schema(description = "원문 URL", example = "https://engineering.naver.com/posts/spring-boot-ops")
        String originUrl
) {
    public PublicPostDetailResponse {
        summaryParagraphs = List.copyOf(summaryParagraphs == null ? List.of() : summaryParagraphs);
    }

    public static PublicPostDetailResponse of(
            ArchivedPost post,
            Company company,
            AiSummaryView summary
    ) {
        return new PublicPostDetailResponse(
                post.getSlug(),
                post.getTitle(),
                CompanySummaryResponse.from(company),
                summary.paragraphs(),
                post.getOriginUrl()
        );
    }
}

public record AiSummaryView(List<String> paragraphs) {
}
```

## Separate Assembler When Policy Is Needed

```java
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class PublicPostDetailResponseAssembler {

    private final OriginUrlSigner originUrlSigner;

    public PublicPostDetailResponse assemble(PublicPostDetailResult result, ViewerContext viewer) {
        String signedOriginUrl = originUrlSigner.sign(result.originUrl(), viewer);

        return new PublicPostDetailResponse(
                result.slug(),
                result.title(),
                CompanySummaryResponse.from(result.company()),
                result.summaryParagraphs(),
                signedOriginUrl
        );
    }
}
```

## Rules

- 순수 field copy는 DTO 내부 `from`/`of`/`toCommand`/`toQuery`로 둔다.
- repository, service, security, clock, external client가 필요하면 DTO 내부 mapper로 넣지 않는다.
- request DTO는 service로 그대로 넘기지 않고 command/query로 변환한다.
- response DTO는 entity/projection/result에서 필요한 값만 복사한다.
- response factory에서 lazy association을 순회하지 않는다.
- public/admin/internal DTO는 같은 필드라도 분리한다.

## References

- [request-response-dto-convention.md](../convention/request-response-dto-convention.md)
- [common-api-dto-snippet.md](common-api-dto-snippet.md)
