# Spring Request Response DTO Convention

## Purpose

Request/Response DTO는 Controller와 외부 client 사이의 API contract다.
DTO는 entity나 repository 구현 세부사항을 숨기고, 프론트엔드가 Swagger와 JSON 응답만 보고 연동할 수 있는 안정적인 모양을 제공해야 한다.

이 문서는 기능별 request/response DTO의 이름, 패키지, mapper 배치, validation, null 처리, Swagger schema 작성 기준을 고정한다.

## Scope

- 기능별 request DTO
- 기능별 response DTO
- request DTO에서 application command/query로 변환하는 mapper
- response DTO에서 entity/result/projection을 API 응답으로 변환하는 mapper
- DTO naming, package, static factory method
- Swagger `@Schema`와 Bean Validation 정렬
- DTO 테스트와 리뷰 기준

공통 envelope, page, cursor, error DTO는 `common-api-dto-convention.md`를 따른다.

## Core Decision

기본 원칙은 다음과 같다.

- DTO는 기본적으로 Java `record`로 작성한다.
- 단순한 순수 변환 mapper는 DTO 내부 static factory 또는 instance method에 둔다.
- 의존성이 필요한 변환, 여러 aggregate 조합, 권한/노출 정책이 필요한 변환은 DTO 밖의 application assembler 또는 mapper로 분리한다.
- Request DTO는 web boundary object다. Service, domain, repository로 그대로 넘기지 않는다.
- Response DTO는 API contract다. Entity, QueryDSL projection, Spring Data `Page`를 그대로 노출하지 않는다.

## Package Rule

기능 중심 구조에서는 request/response DTO를 해당 API boundary의 `dto` 패키지에 둔다.
DTO 수가 많아지면 `request`, `response` 하위 패키지로 분리한다.

Small feature:

```text
publicapi/
  api/
    PublicPostController.java
  docs/
    PublicPostApiDocs.java
  dto/
    PublicPostSearchRequest.java
    PublicPostListItemResponse.java
    PublicPostDetailResponse.java
```

Larger feature:

```text
admin/
  post/
    api/
      AdminPostController.java
    docs/
      AdminPostApiDocs.java
    dto/
      request/
        AdminPostSearchRequest.java
        AdminPostVisibilityUpdateRequest.java
      response/
        AdminPostListItemResponse.java
        AdminPostDetailResponse.java
```

Rules:

- request DTO와 response DTO는 `domain`, `entity`, `repository` 패키지에 두지 않는다.
- 공통 DTO는 `common.dto`, `common.api.dto`, `common.error` 계열에 둔다.
- repository projection DTO는 domain/repository 쪽 `dto`에 둘 수 있지만 controller response로 직접 반환하지 않는다.
- public/admin/internal API의 DTO는 서로 재사용하지 않는다. 필드가 같아 보여도 권한과 노출 정책이 달라질 수 있다.
- 같은 API boundary 안에서만 DTO 재사용을 허용한다. cross-boundary 재사용은 공통 DTO로 승격할 때만 한다.

## Naming Rule

| Role | Name |
| --- | --- |
| 생성 요청 | `{Feature}CreateRequest` |
| 전체 수정 요청 | `{Feature}ReplaceRequest` |
| 부분 수정 요청 | `{Feature}UpdateRequest` |
| 상태 변경 요청 | `{Feature}{State}Request` 또는 `{Feature}{Action}Request` |
| 검색/필터 query 요청 | `{Feature}SearchRequest` |
| 목록 item 응답 | `{Feature}ListItemResponse` |
| 상세 응답 | `{Feature}DetailResponse` |
| 단순 단건 응답 | `{Feature}Response` |
| 생성 결과 응답 | `{Feature}CreateResponse` |
| application command | `{Feature}CreateCommand`, `{Feature}UpdateCommand` |
| application query | `{Feature}SearchQuery`, `{Feature}DetailQuery` |
| repository projection | `{Feature}QueryDto` |
| 복합 응답 조립기 | `{Feature}ResponseAssembler` |

Rules:

- API DTO 이름에 `Dto` suffix를 붙이지 않는다. `Request`, `Response`로 외부 contract임을 드러낸다.
- repository projection에는 `QueryDto` suffix를 붙여 API response와 구분한다.
- 목록 item은 `SummaryResponse`보다 `ListItemResponse`를 우선한다. `SummaryResponse`는 카드/요약 컴포넌트처럼 별도 의미가 있을 때만 사용한다.
- 상세 응답은 `{Feature}DetailResponse`를 우선한다.
- 요청이 단순 query parameter 묶음이면 `SearchRequest`, command body면 `CreateRequest`/`UpdateRequest`를 쓴다.
- `SaveRequest`, `ModifyRequest`, `InfoResponse`, `DataResponse`처럼 의도가 모호한 이름은 쓰지 않는다.

## Request DTO Rule

Request DTO는 HTTP 요청 shape와 syntactic validation을 표현한다.
application 계층이 이해하는 command/query로 변환한 뒤 service에 전달한다.

Rules:

- `@RequestBody` DTO에는 `@Valid`를 붙인다.
- GET query DTO에도 Bean Validation을 적용한다.
- request field에는 `@Schema` 또는 `@Parameter` 설명과 realistic example을 작성한다.
- request DTO는 entity를 생성하거나 repository를 조회하지 않는다.
- request DTO는 security context, clock, external client, repository, service에 의존하지 않는다.
- path variable, 인증 사용자 id처럼 body 밖 값이 필요하면 `toCommand(postId, actorId)`처럼 method parameter로 명시한다.
- request DTO에서 business rule을 판단하지 않는다. 상태 전이, 권한, 존재 여부는 application/domain 계층에서 처리한다.
- 기본값과 최대값은 magic number로 흩뿌리지 않고 DTO 상수 또는 configuration properties로 관리한다.
- `Optional<T>`를 request field type으로 쓰지 않는다. nullable field와 명시적 normalization을 사용한다.

Allowed:

```java
public CreatePostCommand toCommand(Long actorId) {
    return new CreatePostCommand(actorId, title.trim(), content.trim());
}
```

Forbidden:

```java
public Post toEntity(MemberRepository memberRepository) {
    Member member = memberRepository.getById(memberId);
    return new Post(member, title, content);
}
```

## Request Mapper Method Naming

| Source | Target | Method |
| --- | --- | --- |
| request body -> command | command | `toCommand(...)` |
| query params -> query | query | `toQuery()` |
| paging params -> pageable | Spring `Pageable` | `toPageable(Sort sort)` |
| sort params -> sort | Spring `Sort` or internal sort | `toSort()` |
| filter params -> condition | repository/application condition | `toCondition()` |

Rules:

- 변환 method는 의미 있는 target 이름을 사용한다. `convert`, `map`, `make`는 쓰지 않는다.
- `toCommand`는 create/update/delete 같은 write use case에 사용한다.
- `toQuery`는 read use case의 application input에 사용한다.
- `toCondition`은 repository 조건 객체로 바로 내려가는 구조에서만 사용한다.
- request DTO 내부 mapper는 순수 함수여야 한다. 같은 입력이면 같은 output을 반환해야 한다.
- mapper 안에서 현재 시각 생성, UUID 생성, password hashing, token hashing, DB 조회를 하지 않는다.

## Response DTO Rule

Response DTO는 화면에 보여줄 데이터만 포함한다.
내부 상태, 원문 secret, hash, 관리자 메모, raw provider payload, lazy association 전체를 노출하지 않는다.

Rules:

- response field에는 `@Schema(description, example)`를 작성한다.
- list field는 `null` 대신 empty list를 반환한다.
- 날짜/시간은 프로젝트 기준 타입과 timezone을 고정하고 ISO-8601 example을 작성한다.
- nullable field는 nullable 이유를 Swagger description에 명시한다.
- entity를 response로 직접 반환하지 않는다.
- QueryDSL `*QueryDto`를 response로 직접 반환하지 않는다.
- response DTO factory가 lazy loading을 유발하지 않도록 한다.
- nested response는 필요한 수준까지만 포함한다. entity graph 전체를 DTO 트리로 복제하지 않는다.

## Response Mapper Method Naming

| Source | Method | Usage |
| --- | --- | --- |
| domain entity | `from(Entity entity)` | 단일 source 변환 |
| multiple sources | `of(Entity entity, Extra extra)` | 이미 조회된 값 조합 |
| application result | `from(Result result)` | service 결과 객체 변환 |
| repository projection | `from(QueryDto queryDto)` | projection을 API shape로 변환 |
| empty response | `empty()` | 빈 상태가 의미 있는 응답 |

Rules:

- source가 하나이면 `from`을 우선한다.
- source가 여러 개이면 `of`를 사용한다.
- collection 변환은 `fromAll`, `listOf`보다 service/controller에서 `items.stream().map(Response::from).toList()`를 우선한다.
- response DTO factory는 값 복사와 formatting만 수행한다.
- factory 안에서 permission check, masking 정책, external URL signing처럼 정책이 들어가면 assembler로 분리한다.

## Mapper Placement Rule

DTO 내부에 둔다:

- request DTO -> command/query 순수 변환
- entity/result/projection -> response 단순 field copy
- null-to-empty, trim, blank-to-null 같은 boundary normalization
- nested DTO도 같은 response factory로 순수 조립 가능한 경우

별도 assembler/mapper로 분리한다:

- repository, service, external client, security principal, clock, id generator가 필요하다.
- 여러 aggregate를 조합하고 조회 순서가 중요하다.
- 권한에 따라 field 노출 여부가 달라진다.
- public/admin/internal 응답이 같은 source를 서로 다른 정책으로 가공한다.
- locale, timezone, currency, masking, signed URL 생성 같은 presentation policy가 들어간다.
- N+1을 피하기 위해 projection, in-memory join, batch 조회 결과를 조합해야 한다.
- 변환 코드가 DTO 하나의 책임을 넘어 30줄 이상으로 커진다.

MapStruct 같은 mapping library는 기본 선택이 아니다.
반복 field copy가 매우 많고 규칙이 단순할 때만 도입하고, business rule이나 visibility policy를 숨기는 용도로 쓰지 않는다.

## Entity Dependency Rule

Response DTO factory가 entity를 받을 수는 있다.
다만 다음 규칙을 지킨다.

Rules:

- response DTO는 entity reference를 field로 보관하지 않는다.
- factory는 필요한 scalar 값만 복사한다.
- lazy association getter 호출이 필요한 경우 service에서 fetch join, projection, batch size, in-memory join 전략을 먼저 결정한다.
- `@Transactional`이 끝난 뒤 factory가 lazy association을 건드릴 가능성이 있으면 projection 또는 application result를 사용한다.
- entity 상태 변경 method를 DTO factory에서 호출하지 않는다.

Good:

```java
public static PublicPostListItemResponse from(PublicPostQueryDto post) {
    return new PublicPostListItemResponse(post.slug(), post.title(), post.companyName(), post.publishedAt());
}
```

Risky:

```java
public static PublicPostDetailResponse from(ArchivedPost post) {
    return new PublicPostDetailResponse(
            post.getSlug(),
            post.getTitle(),
            post.getTags().stream().map(TopicTag::getName).toList()
    );
}
```

위 코드는 `tags`가 lazy collection이면 N+1 또는 `LazyInitializationException`을 만들 수 있다.

## Validation And Normalization Rule

Request DTO validation은 shape 검증에 집중한다.

Rules:

- required body field는 `@NotNull`, `@NotBlank`를 사용한다.
- 길이 제한은 `@Size`, 숫자 범위는 `@Min`, `@Max`, list 크기는 `@Size(max = ...)`를 사용한다.
- email, URL, slug 같은 공통 패턴은 validation annotation 또는 공통 pattern 상수로 관리한다.
- validation message는 사용자 문구가 아니라 원인 파악 가능한 안정 문구로 둔다.
- blank string 정규화, trim, null-to-empty는 mapper에서 수행할 수 있다.
- semantic validation은 DTO에서 하지 않는다. 예: "게시 가능한 상태인가", "소유자인가", "기업이 존재하는가".
- manual validation이 필요하면 Controller에서 `@Validated` 또는 application validator로 분리한다.

## Null And Empty Rule

Request:

- absent query list는 `List.of()`로 변환한다.
- blank query string은 검색어 없음으로 볼지 validation error로 볼지 프로젝트에서 고정한다. 기본은 `null`로 정규화한다.
- body field가 nullable이면 nullable 이유를 Swagger에 쓴다.
- primitive보다 wrapper type을 우선해 "요청 없음"과 기본값 적용을 구분한다.

Response:

- list는 항상 non-null이다.
- count를 알 수 없으면 `0`으로 속이지 않는다. count가 없는 response shape를 사용한다.
- boolean에 unknown 상태가 있으면 `boolean` 대신 enum을 쓴다.
- optional nested object는 `null` 허용 또는 field omission 중 하나를 프로젝트에서 고정한다.
- `Optional<T>`를 response field type으로 쓰지 않는다.

## Swagger Schema Rule

DTO는 Swagger 문서의 schema 원천이다.

Rules:

- DTO record/class에 `@Schema(description = "...")`를 둔다.
- 모든 public field에는 `description`과 realistic `example`을 작성한다.
- required field는 Bean Validation과 `requiredMode = Schema.RequiredMode.REQUIRED`를 맞춘다.
- enum은 `allowableValues` 또는 enum schema 설명을 둔다.
- 날짜는 `"2026-05-02T10:15:30Z"`처럼 실제 ISO-8601 예시를 쓴다.
- URL은 실제 서비스와 유사한 도메인 예시를 쓴다.
- secret, password, token은 `WRITE_ONLY` 또는 별도 request DTO로 분리한다.
- response-only field와 request-only field를 같은 DTO에 섞지 않는다.

Bad:

```java
@Schema(description = "응답")
public record PostResponse(String title) {
}
```

Good:

```java
@Schema(description = "공개 기술 블로그 글 목록 item 응답")
public record PublicPostListItemResponse(
        @Schema(description = "글 slug", example = "naver-spring-boot-ops-20260502")
        String slug,

        @Schema(description = "원문 글 제목", example = "Spring Boot 3.5 운영 체크리스트")
        String title
) {
}
```

## Lombok Rule

- DTO는 기본적으로 `record`를 사용하므로 Lombok을 사용하지 않는다.
- legacy Java version, framework binding 제약, mutable form object가 필요한 경우에만 class DTO를 사용한다.
- class DTO가 필요하면 `@Getter`, `@NoArgsConstructor(access = AccessLevel.PROTECTED)`처럼 최소 Lombok만 사용한다.
- API DTO에 `@Data`를 사용하지 않는다. setter, equals, toString이 과도하게 열리고 contract가 흐려진다.
- response DTO class에는 setter를 두지 않는다.

## Request And Response Separation Rule

- request DTO와 response DTO를 하나로 합치지 않는다.
- create/update request를 같은 DTO로 합치지 않는다. 필수 field와 validation이 달라질 수 있다.
- public response와 admin response를 합치지 않는다.
- 내부 application result를 그대로 response로 쓰지 않는다.
- API version이 달라지면 v1/v2 DTO를 분리한다.

## Controller Usage Rule

Controller는 DTO mapper를 호출해 application input을 만든다.

Good:

```java
@PostMapping
@ResponseStatus(HttpStatus.CREATED)
public PublicPostCreateResponse createPost(
        @AuthenticationPrincipal LoginUser loginUser,
        @Valid @RequestBody PublicPostCreateRequest request
) {
    PublicPostCreateResult result = publicPostCommandService.create(request.toCommand(loginUser.id()));
    return PublicPostCreateResponse.from(result);
}
```

Avoid:

```java
@PostMapping
public Post createPost(@RequestBody PostCreateRequest request) {
    return postRepository.save(request.toEntity());
}
```

## Test Rule

- request DTO mapper는 기본값, trim, null-to-empty, body 밖 parameter 반영을 unit test로 검증한다.
- response DTO factory는 null optional field, empty list, nested response 변환을 unit test로 검증한다.
- controller slice test는 JSON field contract와 validation error를 검증한다.
- Swagger/OpenAPI smoke test는 DTO schema example과 required field가 누락되지 않았는지 확인한다.
- lazy association을 쓰는 response factory는 repository/service test에서 N+1 또는 `LazyInitializationException` 위험을 확인한다.

## Review Checklist

- DTO 이름이 role을 명확히 드러내는가?
- request와 response가 분리되어 있는가?
- request DTO가 service/repository/entity를 직접 참조하지 않는가?
- request mapper가 `toCommand`, `toQuery`처럼 target을 명확히 표현하는가?
- response factory가 lazy loading이나 N+1을 유발하지 않는가?
- 권한, masking, locale, signed URL 같은 정책이 DTO 내부에 숨어 있지 않은가?
- Swagger schema description/example이 실제 서비스 데이터처럼 작성되어 있는가?
- nullable field와 empty list 정책이 일관적인가?
- `*QueryDto`가 API response로 직접 반환되지 않는가?
- DTO 변경이 Controller test, Swagger docs, Wiki/API 문서에 반영됐는가?

## References

- [common-api-dto-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/common-api-dto-convention.md>)
- [controller-writing-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/controller-writing-convention.md>)
- [swagger-documentation-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/swagger-documentation-convention.md>)
- [repository-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/repository-design-convention.md>)
