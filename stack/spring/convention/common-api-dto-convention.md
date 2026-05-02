# Spring Common API DTO Convention

## Purpose

Spring API에서 반복되는 응답 모양을 프로젝트마다 임의로 만들지 않도록 공통 DTO 기준을 고정한다.
공통 DTO는 HTTP contract의 일부이므로 이름, 필드, null 처리, 페이지네이션 메타데이터, error field 구조를 안정적으로 유지해야 한다.

## Scope

- success response DTO
- list response DTO
- page response DTO
- slice/cursor response DTO
- error response DTO
- field error DTO
- request DTO의 공통 paging/sort query
- DTO package, naming, serialization rule

## Package Rule

공통 DTO는 web/api boundary에서 재사용되므로 프로젝트의 `common.dto` 또는 `common.api.dto` 계열에 둔다.

```text
common/
  dto/
    ListResponse.java
    PageResponse.java
    SliceResponse.java
  error/
    ErrorCode.java
    ErrorResponse.java
    FieldErrorResponse.java
```

Rules:

- 공통 DTO는 domain, entity, repository 패키지에 두지 않는다.
- 공통 DTO는 JPA entity, QueryDSL type, security principal에 의존하지 않는다.
- domain-specific response는 각 feature boundary의 `dto` 패키지에 둔다.
- 공통 DTO와 domain DTO의 이름이 충돌하지 않게 한다. 예: `PageResponse<T>`와 `PublicPostListItemResponse`.
- 공통 DTO를 바꾸면 모든 API contract에 영향이 있으므로 Wiki/OpenAPI/테스트를 함께 갱신한다.

## DTO Implementation Rule

- DTO는 기본적으로 Java `record`로 작성한다.
- Jackson/JPA proxy 문제가 있는 entity는 DTO 생성 시점에 필요한 값만 복사한다.
- DTO에는 setter를 두지 않는다.
- DTO field는 API 응답 이름과 동일하게 명확히 둔다.
- `Map<String, Object>` 응답은 임시 디버깅 외에는 금지한다.
- `Object` field는 versioned extension 영역이 필요할 때만 사용한다.
- 날짜와 시간은 `Instant`, `LocalDate`, `LocalDateTime` 중 프로젝트 기준을 정하고 ISO-8601로 직렬화한다.
- enum은 응답 contract에 노출되는 순간 값 변경 비용이 크므로 명시적으로 문서화한다.
- `@JsonInclude(Include.NON_EMPTY)`는 error `errors`처럼 비어 있을 수 있는 field에만 제한적으로 쓴다.

## Success Envelope Rule

프로젝트는 성공 응답 envelope 정책을 하나로 고정한다.

Allowed:

- 단건 API는 domain response DTO를 직접 반환한다.
- 목록 API는 `ListResponse<T>`, 페이지 API는 `PageResponse<T>`, cursor API는 `SliceResponse<T>`처럼 공통 DTO를 반환한다.
- 프로젝트가 `ApiResponse<T>` envelope를 채택했다면 모든 성공 응답에 일관 적용한다.

Avoid:

- 같은 프로젝트에서 어떤 API는 `{ "data": ... }`, 어떤 API는 DTO direct, 어떤 API는 `{ "items": ... }`처럼 섞지 않는다.
- `ResponseEntity.ok(Map.of(...))`로 일회성 shape를 만들지 않는다.
- 성공 envelope 안에 error field를 넣지 않는다.

Decision rule:

- API가 작고 프론트가 직접 소비하는 MVP에서는 단건 DTO direct와 목록/page 공통 DTO를 우선한다.
- BFF, public SDK, multi-client API처럼 공통 metadata가 계속 필요하면 `ApiResponse<T>`를 검토한다.

## ListResponse Rule

단순 목록이면서 전체 count, page metadata가 필요 없으면 `ListResponse<T>`를 사용한다.

Required fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `items` | `List<T>` | 목록 데이터 |

Optional fields:

| Field | Type | Usage |
| --- | --- | --- |
| `count` | `int` | 현재 응답 item 수를 명시해야 할 때 |

Rules:

- 빈 목록은 `items: []`로 반환한다. `null`로 반환하지 않는다.
- `List<T>`는 `List.copyOf` 또는 불변 list로 보관한다.
- `count`는 전체 DB count가 아니라 현재 응답 item 수일 때만 둔다.
- 전체 count가 필요하면 `PageResponse<T>`를 사용한다.

## PageResponse Rule

offset page 기반 목록은 `PageResponse<T>`를 사용한다.

Required fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `items` | `List<T>` | 현재 페이지 데이터 |
| `page` | `int` | 0-based page index |
| `size` | `int` | 요청 page size |
| `totalElements` | `long` | 전체 item 수 |
| `totalPages` | `int` | 전체 page 수 |
| `first` | `boolean` | 첫 페이지 여부 |
| `last` | `boolean` | 마지막 페이지 여부 |

Rules:

- page index는 0-based를 기본으로 한다.
- `totalElements`가 필요 없는 API는 `PageResponse<T>` 대신 `SliceResponse<T>`를 사용한다.
- `items`는 항상 non-null list다.
- `size`, `page` 기본값과 최대값은 request DTO 상수 또는 configuration properties로 관리한다.
- page/sort magic number는 Controller에 직접 쓰지 않는다.
- Spring Data `Page<T>`를 그대로 JSON으로 반환하지 않는다. 내부 필드가 불안정하고 contract가 과하게 노출된다.
- `PageResponse.of(items, page)` 같은 factory를 두어 변환을 표준화한다.

## SliceResponse and Cursor Rule

무한 스크롤, feed, deep pagination 비용 회피가 필요하면 `SliceResponse<T>` 또는 `CursorResponse<T>`를 사용한다.

Required fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `items` | `List<T>` | 현재 구간 데이터 |
| `size` | `int` | 요청 size |
| `hasNext` | `boolean` | 다음 구간 존재 여부 |
| `nextCursor` | `String` or `null` | 다음 요청 cursor |

Rules:

- cursor는 stable sort key를 포함해야 한다.
- cursor 값은 client가 해석하지 않는 opaque string으로 둔다.
- cursor에는 secret, raw internal id 조합, SQL 조건을 노출하지 않는다.
- `nextCursor`가 없으면 `null` 또는 field omission 중 하나를 프로젝트에서 고정한다.
- 최신순 feed의 cursor tie-breaker는 `publishedAt + id`처럼 deterministic해야 한다.

## ErrorResponse Rule

error DTO는 모든 API에서 동일한 shape를 사용한다.

Required fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `code` | `String` | machine-readable error code |
| `message` | `String` | safe default message |

Optional fields:

| Field | Type | Usage |
| --- | --- | --- |
| `errors` | `List<FieldErrorResponse>` | binding/validation field errors |
| `traceId` | `String` | tracing이 있는 프로젝트에서만 |

Rules:

- client 분기는 `code`로만 한다.
- `message`는 contract key가 아니다.
- `errors`는 없으면 `[]` 또는 field omission 중 하나로 통일한다. 기본은 `@JsonInclude(NON_EMPTY)`로 omission한다.
- fallback `Exception`의 raw message는 응답하지 않는다.
- error DTO에는 HTTP status를 중복 field로 넣지 않는다. 필요하면 프로젝트에서 명시적으로 채택한다.
- error timestamp는 관측 시스템에서 처리하는 것을 우선한다. 넣는다면 모든 error response에 동일하게 넣는다.

## FieldErrorResponse Rule

validation/binding 오류는 field 단위로 구조화한다.

Required fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `field` | `String` | request field path |
| `reason` | `String` | safe validation failure reason |

Optional fields:

| Field | Type | Usage |
| --- | --- | --- |
| `rejectedValue` | `Object` or `String` | 민감하지 않은 값만 |

Rules:

- password, token, secret, full email, phone number는 `rejectedValue`에 넣지 않는다.
- nested field는 `companySlugs[0]`처럼 Spring binding field path를 따른다.
- reason은 annotation message나 type mismatch reason을 사용하되 내부 class명, enum package명은 노출하지 않는다.
- enum mismatch는 허용 값을 알려줄 수 있지만, 값 목록이 보안상 민감하면 일반 메시지만 반환한다.

## Request Common DTO Rule

반복되는 query parameter는 공통 request DTO나 base policy를 둔다.

Examples:

- `PageRequestParams`
- `CursorRequestParams`
- `SortRequestParams`
- `DateRangeRequestParams`

Rules:

- 상속 기반 request DTO보다 record composition 또는 factory method를 우선한다.
- request DTO는 controller/api boundary에서 application query/command로 변환한다.
- request DTO를 service/repository로 그대로 전달하지 않는다.
- 기본값, 최대값, whitelist는 magic number가 아니라 상수 또는 configuration properties로 둔다.
- Bean Validation annotation과 수동 validation을 섞을 때는 오류 code가 동일하게 매핑되는지 확인한다.

## Naming Rule

| Type | Name |
| --- | --- |
| 단건 응답 | `{Feature}Response` |
| 목록 item | `{Feature}ListItemResponse` |
| 상세 응답 | `{Feature}DetailResponse` |
| 생성 요청 | `{Feature}CreateRequest` |
| 수정 요청 | `{Feature}UpdateRequest` |
| 검색 query request | `{Feature}SearchRequest` |
| application query | `{Feature}Query` |
| repository projection | `{Feature}QueryDto` |
| 공통 목록 응답 | `ListResponse<T>` |
| 공통 페이지 응답 | `PageResponse<T>` |
| 공통 cursor 응답 | `SliceResponse<T>` or `CursorResponse<T>` |
| 공통 error 응답 | `ErrorResponse` |
| 공통 field error | `FieldErrorResponse` |

Rules:

- repository projection인 `*QueryDto`를 controller response로 직접 반환하지 않는다.
- controller response DTO에는 `Dto` suffix를 붙이지 않는다. API contract임을 `Response`로 드러낸다.
- 내부 application object는 web 용어인 `Request`, `Response`보다 `Command`, `Query`, `Result`를 우선한다.

## Null and Empty Rule

- response list는 `null` 대신 empty list를 반환한다.
- optional text는 `null` 또는 field omission 중 하나로 프로젝트에서 고정한다.
- count는 알 수 없으면 `0`으로 속이지 않는다. count가 필요 없는 DTO를 사용한다.
- boolean은 알 수 없는 상태가 있으면 primitive `boolean` 대신 `Boolean` 또는 enum을 검토한다.
- 빈 문자열은 의미가 없으면 응답 생성 전에 `null`로 정규화한다.

## Versioning and Compatibility

- 공통 DTO field rename은 breaking change다.
- field 추가는 일반적으로 backward compatible이지만 mobile/client SDK가 있으면 릴리즈 노트에 기록한다.
- field 삭제는 deprecated 기간을 둔다.
- `ErrorResponse.code` 값은 삭제하지 않고 deprecated 처리한다.
- Page metadata field는 client paging UI에 직접 영향이 있으므로 변경 전 API 문서를 먼저 갱신한다.

## Test Rule

- 공통 DTO factory는 unit test로 non-null list, page metadata, empty error omission을 검증한다.
- Controller test는 JSON field contract를 `jsonPath`로 검증한다.
- error response test는 validation error, business error, fallback error를 분리해 검증한다.
- pagination test는 first/last/totalPages 계산을 검증한다.

## Checklist

- 공통 DTO가 `common.dto` 또는 `common.error`에 모여 있는가?
- 목록 응답이 `items: []`를 보장하는가?
- Spring Data `Page`를 그대로 노출하지 않는가?
- page/cursor 정책이 API별로 섞이지 않는가?
- error shape가 모든 Controller에서 동일한가?
- `FieldErrorResponse`가 민감한 rejected value를 노출하지 않는가?
- request DTO 기본값과 최대값이 상수나 properties로 관리되는가?
- DTO field 변경이 Wiki/OpenAPI/test에 반영됐는가?

## References

- [request-response-dto-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/request-response-dto-convention.md>)
- [api-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/api-design-convention.md>)
- [controller-writing-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/controller-writing-convention.md>)
- [error-handling-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/error-handling-convention.md>)
