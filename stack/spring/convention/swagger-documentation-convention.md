# Spring Swagger Documentation Convention

## Purpose

Swagger/OpenAPI 문서는 선택 사항이 아니라 프론트엔드와 백엔드가 공유하는 API 계약서다.
Controller가 동작하더라도 Swagger가 부실하면 프론트는 API 의도, 파라미터 기본값, 응답 shape, 에러 처리 방식을 추측하게 된다.
Spring 프로젝트는 `springdoc-openapi`와 Swagger Core annotation을 사용해 화면 개발자가 Swagger UI만 보고 연동을 시작할 수 있는 수준으로 작성한다.

## Source Notes

이 문서는 다음 기준을 반영한다.

- `springdoc-openapi` 공식 문서 기준: `@ParameterObject`, `GroupedOpenApi`, `OpenAPI`, `OperationCustomizer`, `GlobalOpenApiCustomizer`
- Swagger Core annotation 기준: `@Tag`, `@Operation`, `@Parameter`, `@ApiResponse`, `@Content`, `@Schema`, `@ExampleObject`
- 참고 저장소 `3-devon-woo-community`: `CustomExceptionDescription`, `SwaggerResponseDescription`, `OperationCustomizer`로 endpoint별 error response를 자동 주입하는 패턴

## Non-Negotiable Rules

- Swagger annotation은 가능하면 Controller 구현체가 아니라 `*ApiDocs` 또는 `*Docs` interface에 작성한다.
- Controller는 docs interface를 `implements`하고, method signature를 정확히 맞춘다.
- 새 public/admin API를 만들면 Swagger 문서도 같은 PR에 포함한다.
- `@Operation.summary`만 쓰고 끝내지 않는다. `description`, success response, error response, parameter, schema example을 함께 작성한다.
- DTO field에는 필요한 `@Schema` 설명과 실제 서비스와 유사한 example을 작성한다.
- 반복되는 error response는 custom annotation과 `OperationCustomizer`로 자동 주입한다.
- 각 endpoint의 error group은 실제 발생 가능한 error code와 발생 상황을 설명해야 한다.
- Swagger 문서는 프론트가 읽는 문서다. 내부 구현 용어보다 화면, 사용 시점, client 처리 기준을 우선한다.

## Package Rule

기능 중심 구조에서는 docs interface를 해당 API boundary 안에 둔다.

```text
publicapi/
  api/
    PublicPostController.java
  docs/
    PublicPostApiDocs.java
  dto/
    PublicPostListItemResponse.java
    PublicPostSearchRequest.java

common/
  swagger/
    SwaggerConfig.java
    SwaggerTagOrder.java
    CustomErrorResponseDescription.java
    SwaggerErrorResponseDescription.java
```

Rules:

- `docs` 패키지는 API 문서 전용이다.
- docs interface는 service, repository, entity에 의존하지 않는다.
- docs interface는 controller method signature와 request/response DTO만 안다.
- controller 구현체에는 가능한 한 Swagger annotation을 두지 않는다.
- filter나 security entrypoint가 처리하는 API는 Swagger-only controller 또는 docs 전용 method로 노출 여부를 명시한다.

## Docs Interface Rule

Docs interface는 다음을 소유한다.

- `@Tag`
- `@Operation`
- `@ApiResponse` 또는 `@ApiResponses`
- `@CustomErrorResponseDescription`
- `@Parameter`, `@ParameterObject`, request body 설명
- endpoint별 security 설명

Controller 구현체는 다음만 소유한다.

- Spring MVC mapping
- request binding
- validation
- application service delegation
- response status

Rules:

- docs interface method name은 controller method name과 동일하게 둔다.
- docs interface return type은 실제 response type과 동일하게 둔다.
- docs interface parameter는 실제 controller parameter와 순서와 타입을 맞춘다.
- docs interface에 없는 endpoint가 controller에 생기면 문서 누락으로 본다.
- docs interface의 annotation이 controller와 충돌하면 controller annotation을 제거한다.

## Operation Writing Rule

`@Operation`은 summary와 description을 모두 작성한다.

Summary:

- 20자 내외의 짧은 한국어 명사형 또는 동사형으로 작성한다.
- 화면/기능 단위로 이해되는 이름을 쓴다.
- Bad: `조회`, `list`, `API`
- Good: `최신 기술 블로그 글 목록 조회`, `구독 기업 추가`, `AI 요약 재생성 요청`

Description must include:

- 이 API가 어떤 화면이나 사용자 행동에서 호출되는지
- 조회 조건, 필터, 정렬, 기본값
- 빈 결과가 어떤 의미인지
- 인증 필요 여부
- side effect 여부
- 프론트가 특별히 처리해야 하는 상태

Template:

```text
{화면/사용자 행동}에서 {목적}으로 호출한다.

- 조회 대상: ...
- 필터/정렬: ...
- 기본값: ...
- 빈 결과: ...
- 인증: ...
- 프론트 처리: ...
```

Rules:

- description은 구현 설명이 아니라 API 사용 설명이어야 한다.
- "데이터를 조회합니다"처럼 당연한 문장 하나로 끝내지 않는다.
- 필터 조합 규칙, 정렬 whitelist, page 기본값은 description에 적는다.
- command API는 중복 호출 정책과 side effect를 적는다.
- 관리자 API는 권한, audit log, 상태 전이를 적는다.

## Parameter Rule

Path/query/header parameter는 `@Parameter`로 설명한다.

Rules:

- path variable은 required, 의미, 예시를 반드시 작성한다.
- query parameter는 required 여부, default, max, 허용 값, 반복 파라미터 여부를 작성한다.
- enum/string sort는 allowable values를 적는다.
- list query는 반복 방식까지 적는다. 예: `?company=naver&company=kakao`
- header는 인증/추적/멱등성 key처럼 client가 알아야 할 때만 노출한다.
- 복잡 query object는 springdoc `@ParameterObject`를 사용해 query parameter를 펼친다.
- request DTO field에도 `@Parameter` 또는 `@Schema`를 보완해 Swagger UI가 빈 설명으로 나오지 않게 한다.

Example:

```java
PageResponse<PublicPostListItemResponse> getPosts(
        @ParameterObject @Valid PublicPostSearchRequest request);
```

```java
public record PublicPostSearchRequest(
        @Parameter(description = "검색어. 공백 기준 token AND 검색", example = "Spring Boot 운영")
        String q,

        @Parameter(description = "기업 slug 반복 필터. 예: company=naver&company=kakao")
        List<String> company,

        @Parameter(description = "0부터 시작하는 페이지 번호", example = "0")
        Integer page,

        @Parameter(description = "페이지 크기. 기본 24, 최대 100", example = "24")
        Integer size
) {
}
```

## Request Body Rule

`@RequestBody`를 사용하는 API는 request body 설명과 schema를 명시한다.

Rules:

- `@RequestBody(required = true, content = ...)`를 docs interface에 작성한다.
- DTO class와 field에 `@Schema`를 작성한다.
- validation annotation과 Swagger description이 서로 맞아야 한다.
- 필수 field는 `requiredMode = Schema.RequiredMode.REQUIRED`를 사용한다.
- nullable field는 nullable 이유를 설명한다.
- 생성/수정 API는 최소 하나의 현실적인 request example을 제공한다.
- password, token, secret example은 실제처럼 보이되 재사용 가능한 값으로 둔다. 실제 secret은 절대 넣지 않는다.

## Response Rule

Success response는 `@ApiResponse`와 `@Content(schema = @Schema(...))`로 명시한다.

Rules:

- response code는 실제 status와 맞춘다.
- `201 Created`, `204 No Content`를 Swagger에도 동일하게 반영한다.
- 단건 DTO, `ListResponse<T>`, `PageResponse<T>`, `SliceResponse<T>` 중 실제 응답 shape를 명확히 한다.
- Spring Data `Page`를 schema로 노출하지 않는다.
- common response wrapper를 쓰면 wrapper schema와 payload schema가 프론트에서 이해 가능해야 한다.
- generic response는 Swagger가 payload type을 잃기 쉬우므로 필요하면 endpoint별 wrapper response class를 둔다.
- 응답 example은 화면에서 실제로 볼 법한 값으로 작성한다.

Example value rule:

- Bad: `string`, `foo`, `test`, `1`
- Good: `naver`, `Spring Boot 3.5 운영 체크리스트`, `2026-05-02T10:15:30Z`, `https://engineering.naver.com/posts/spring-boot-ops`

## DTO Schema Rule

DTO는 Swagger 문서의 핵심이다.

Rules:

- request/response DTO class에는 `@Schema(description = "...")`를 둔다.
- 중요한 field에는 `description`, `example`, `requiredMode`, `nullable`, `allowableValues`, `accessMode` 중 필요한 값을 둔다.
- ID, slug, code, enum은 의미와 예시를 반드시 쓴다.
- 날짜는 ISO-8601 예시를 쓴다.
- URL은 실제 서비스와 유사한 도메인 예시를 쓴다.
- 목록 field는 element가 무엇인지 설명한다.
- 내부 상태, hash, admin memo, raw provider payload는 public schema에 포함하지 않는다.
- 민감 field는 `accessMode = WRITE_ONLY` 또는 Swagger 노출 제외를 검토한다.

Example:

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

## Error Documentation Rule

에러 문서는 매우 중요하다. 프론트는 Swagger error 문서를 보고 사용자 메시지, retry, form validation, empty state를 결정한다.

Rules:

- 각 endpoint마다 발생 가능한 domain error code를 error group으로 정의한다.
- 공통 error `INVALID_REQUEST`, `INTERNAL_ERROR`는 한 곳에서 자동 추가한다.
- 인증 API는 `UNAUTHORIZED`, `FORBIDDEN` 등 security error를 누락하지 않는다.
- error response schema는 프로젝트 공통 `ErrorResponse`를 사용한다.
- validation error는 `FieldErrorResponse` 예시를 포함한다.
- description에는 "언제 발생하는지"와 "프론트 처리"를 쓴다.
- 같은 HTTP status에 여러 error code가 있을 수 있으므로 example name은 error code로 둔다.

Error description template:

```text
PUBLIC_POST_NOT_FOUND: slug에 해당하는 공개 글이 없거나 hidden/blocked 상태일 때 발생한다. 프론트는 404 페이지 또는 목록 복귀 CTA를 표시한다.
INVALID_REQUEST: page, size, sort, filter 값이 허용 범위를 벗어났을 때 발생한다. 프론트는 입력값을 유지하고 validation 메시지를 표시한다.
```

Avoid:

- `400 Bad Request`
- `잘못된 요청`
- `에러 발생`
- 모든 endpoint에 같은 error 목록 복붙

## Custom Error Annotation Rule

반복 error response는 hand-written `@ApiResponses`로 복붙하지 않는다.
참고 저장소의 `CustomExceptionDescription` 패턴을 수용하되, 프로젝트 공통 `ErrorCode`와 `ErrorResponse` shape에 맞춰 확장한다.

Required components:

- `@CustomErrorResponseDescription`
- `SwaggerErrorResponseDescription` interface
- endpoint/domain별 error group enum
- `OperationCustomizer`
- error code별 `ExampleObject`

Rules:

- error group enum 이름은 `{Domain}SwaggerErrorResponseDescription`로 둔다.
- group constant는 endpoint use case와 맞춘다. 예: `PUBLIC_POST_LIST`, `PUBLIC_POST_DETAIL`.
- error group은 raw string보다 enum constant를 사용한다.
- `OperationCustomizer`는 error code의 HTTP status로 response를 묶고, 같은 status 안에 여러 examples를 추가한다.
- error code의 기본 message만 쓰지 말고 가능하면 발생 상황 설명도 함께 제공한다.

## OpenAPI Config Rule

`SwaggerConfig`는 하나의 shared config에서 관리한다.

Must include:

- `OpenAPI` bean with title, description, version
- server URL은 environment별로 필요할 때만 명시
- security scheme은 한 번만 등록
- `GroupedOpenApi`로 public/admin/internal API를 분리
- tag order customizer
- error response `OperationCustomizer`
- optional common header customizer such as `X-Request-ID`

Rules:

- Swagger UI path와 api-docs path는 `application.yml`에서 관리한다.
- controller별로 bearer auth 설정을 반복하지 않는다.
- internal API는 Swagger 노출 여부를 명시적으로 결정한다.
- actuator나 infrastructure endpoint는 기본적으로 API 문서에서 제외한다.

## Group and Tag Rule

- API group은 public, admin, internal처럼 소비자 기준으로 나눈다.
- tag는 화면/도메인 기준으로 나눈다.
- tag 이름은 프론트가 이해하는 이름으로 쓴다.
- tag description은 해당 묶음의 화면과 권한 범위를 설명한다.
- tag 정렬이 필요하면 `@SwaggerTagOrder` 같은 공통 annotation과 customizer를 사용한다.

Example:

```java
@SwaggerTagOrder(10)
@Tag(
        name = "Public Posts",
        description = "메인 피드, 글 상세, 필터 UI에서 사용하는 공개 기술 블로그 글 조회 API"
)
public interface PublicPostApiDocs {
}
```

## Frontend-Friendly Description Checklist

Swagger 설명을 작성할 때 다음 질문에 답해야 한다.

- 프론트의 어떤 화면에서 호출하는가?
- 사용자가 어떤 행동을 했을 때 호출하는가?
- 인증이 필요한가?
- 요청 파라미터 기본값과 최대값은 무엇인가?
- filter와 sort 조합 규칙은 무엇인가?
- empty list는 정상인가, 에러인가?
- 성공 시 화면에 어떤 데이터를 표시할 수 있는가?
- 실패 시 어떤 UI를 보여줘야 하는가?
- 재시도 가능한 오류인가?
- 같은 요청을 여러 번 보내도 안전한가?
- 응답 field 중 null이 될 수 있는 것은 무엇인가?
- 날짜/시간 timezone은 무엇인가?
- cursor나 page index는 0-based인가?

## Bad and Good Examples

Bad:

```java
@Operation(summary = "목록 조회", description = "목록을 조회합니다.")
@GetMapping
public PageResponse<PostResponse> getPosts(...) {
}
```

Good:

```java
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
```

## Validation and Swagger Alignment

- Bean Validation과 Swagger 설명은 일치해야 한다.
- `@Size(max = 20)`이면 Swagger description에 최대 20개를 적는다.
- `@Min(0)`이면 page가 0-based임을 적는다.
- enum validation이 있으면 allowable values를 적는다.
- request DTO의 수동 validation이 있으면 해당 조건을 description에 적는다.
- validation error example에는 field path와 reason을 포함한다.

## Test and Review Rule

Swagger는 수동으로 열어보는 것만으로 끝내지 않는다.

Minimum:

- `/v3/api-docs`가 생성되는지 smoke test 또는 local run으로 확인한다.
- 새 endpoint가 원하는 group/tag 아래에 있는지 확인한다.
- operation summary와 description이 비어 있지 않은지 확인한다.
- success response schema가 실제 DTO와 맞는지 확인한다.
- error response examples가 code별로 표시되는지 확인한다.
- request DTO field example이 `string`, `0`, `foo` 같은 placeholder로 남지 않았는지 확인한다.

Optional automation:

- OpenAPI JSON snapshot 검증
- `swagger-cli validate` 또는 equivalent OpenAPI validator
- CI에서 `/v3/api-docs` generation test

## PR Checklist

- docs interface를 추가했는가?
- controller가 docs interface를 구현하는가?
- summary/description이 프론트 화면 기준으로 충분한가?
- path/query/header/body parameter 설명과 example이 있는가?
- request/response DTO field에 `@Schema`가 있는가?
- success response status, schema, example이 실제 구현과 맞는가?
- endpoint별 error group이 있는가?
- error code별 발생 상황과 프론트 처리 기준이 설명됐는가?
- 인증/권한이 Swagger에 표현됐는가?
- page/cursor/default/sort/filter 정책이 Swagger에서 보이는가?
- Swagger UI에서 프론트가 mock 없이 요청을 구성할 수 있는가?

## References

- [api-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/api-design-convention.md>)
- [common-api-dto-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/common-api-dto-convention.md>)
- [controller-writing-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/controller-writing-convention.md>)
- [error-handling-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/error-handling-convention.md>)
- [security-exception-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/security-exception-convention.md>)
- [swagger-config-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/swagger-config-snippet.md>)
- [swagger-docs-interface-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/swagger-docs-interface-snippet.md>)
- [swagger-custom-error-response-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/swagger-custom-error-response-snippet.md>)
- [springdoc-openapi](https://springdoc.org/)
- [Swagger Core Annotations](https://github.com/swagger-api/swagger-core/wiki/Swagger-2.X---Annotations)
- Source: [Devon SWAGGER_CUSTOM_EXCEPTION.md](</C:/Users/imdls/workspace/KakaobootTechCamp/3-devon-woo-community/docs/SWAGGER_CUSTOM_EXCEPTION.md>)
- Source: [Devon SwaggerConfig.java](</C:/Users/imdls/workspace/KakaobootTechCamp/3-devon-woo-community/src/main/java/com/kakaotechbootcamp/community/common/swagger/SwaggerConfig.java>)
