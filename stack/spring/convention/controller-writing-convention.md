# Spring Controller Writing Convention

## Purpose

Spring MVC Controller를 HTTP contract adapter로만 유지한다.
Controller는 request mapping, binding, validation, response status를 소유하고, business rule, repository access, entity mutation은 service/application 계층에 위임한다.

## Scope

- `@RestController`, `@Controller`
- `@RequestMapping`, `@GetMapping`, `@PostMapping`, `@PatchMapping`, `@DeleteMapping`
- `@PathVariable`, `@RequestParam`, `@RequestBody`, `@ModelAttribute`
- Bean Validation
- `@InitBinder`, `WebDataBinder`
- response DTO, pagination DTO
- common API DTO
- controller-level exception mapping
- `@WebMvcTest`

## Package Rule

프로젝트가 기능 중심 구조를 쓰면 Controller는 해당 API boundary 안의 `api` 패키지에 둔다.

```text
publicapi/
  api/
    PublicPostController.java
  application/
    PublicPostQueryService.java
  dto/
    PublicPostListResponse.java
```

Rules:

- public/admin/internal API boundary를 package와 URL prefix 모두에서 분리한다.
- Controller 이름은 `{Feature}Controller` 또는 `{Boundary}{Feature}Controller`로 둔다.
- Controller가 entity, repository, QueryDSL DTO를 직접 반환하지 않는다.
- Controller가 service 반환 DTO를 그대로 반환해도 되지만, public response contract DTO여야 한다.

## Controller Responsibility

Controller가 한다:

- URL, HTTP method, consumes/produces 결정
- path/query/body binding
- shape validation
- HTTP status 결정
- response envelope 적용
- request DTO를 application command/query object로 변환

Controller가 하지 않는다:

- repository 호출
- transaction 선언
- entity 상태 변경
- business rule 판단
- token hash, password hash, secret 계산
- pagination count 보정
- external provider 호출

## Mapping Rules

- Class level `@RequestMapping`으로 API version과 resource prefix를 고정한다.
- Method level mapping은 endpoint별 세부 path만 둔다.
- `GET`은 read-only여야 한다.
- create는 `POST`, full replace는 `PUT`, partial update는 `PATCH`, remove는 `DELETE`를 사용한다.
- command endpoint는 동사 path를 허용하되 명확히 한다. 예: `POST /posts/{id}/summary/regenerate`
- trailing slash에 의존하지 않는다.
- 같은 Controller 안에서 public endpoint와 admin endpoint를 섞지 않는다.

```java
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/public/posts")
public class PublicPostController {

    private final PublicPostQueryService publicPostQueryService;

    @GetMapping
    public PageResponse<PublicPostListItemResponse> getPosts(@Valid PublicPostSearchRequest request) {
        return publicPostQueryService.getPosts(request.toQuery());
    }
}
```

## Request DTO Rule

- query parameter가 3개 이상이면 개별 `@RequestParam` 나열보다 request record/class를 사용한다.
- `@ModelAttribute`는 생략 가능하지만, 복잡 query object에는 명시해도 된다.
- request DTO는 controller/api boundary에 둔다.
- request DTO는 service나 repository로 직접 전달하지 않는다. `toCommand`, `toQuery`, mapper method로 application object로 변환한다.
- `@RequestBody`에는 `@Valid`를 붙인다.
- GET query DTO에도 Bean Validation을 적용한다.

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

    public PublicPostQuery toQuery() {
        return new PublicPostQuery(
                normalize(q),
                nullToEmpty(company),
                nullToEmpty(job),
                nullToEmpty(tag),
                page == null ? DEFAULT_PAGE : page,
                size == null ? DEFAULT_SIZE : size
        );
    }
}
```

## Null and Default Value Rule

- Controller boundary에서 null을 application 기본값으로 확정한다.
- 기본값은 magic number로 흩뿌리지 않고 상수, properties, enum으로 둔다.
- `@RequestParam(defaultValue = "...")`는 단순 scalar에만 사용한다.
- query object를 사용할 때는 DTO 내부 상수 또는 properties를 통해 기본값을 적용한다.
- blank string은 `null` 또는 empty collection으로 정규화한다.
- collection query parameter가 없으면 빈 list로 변환한다.
- collection query parameter가 blank만 포함하면 validation error 또는 empty로 처리한다. 프로젝트에서 하나로 고정한다.
- boolean query parameter는 의미가 불명확하면 primitive `boolean`보다 `Boolean`으로 받아 명시적으로 기본값을 적용한다.

Bad:

```java
@GetMapping
public PageResponse<PostResponse> getPosts(@RequestParam(defaultValue = "24") int size) {
    ...
}
```

Good:

```java
private static final int DEFAULT_PAGE_SIZE = 24;
private static final int MAX_PAGE_SIZE = 100;
```

## Validation Rule

- syntactic validation은 Bean Validation으로 처리한다.
- semantic validation은 service/application 계층에서 처리한다.
- path variable, request param 단건 검증이 필요하면 Controller class에 `@Validated`를 붙인다.
- validation message는 클라이언트 표시용 문장보다 개발자가 원인을 알 수 있는 짧고 안정적인 문장으로 둔다.
- message를 contract key로 쓰지 않는다. client 분기는 error `code`로 한다.
- numeric range는 `@Min`, `@Max`, string length는 `@Size`, required body field는 `@NotNull`/`@NotBlank`를 사용한다.
- list size 제한은 `@Size(max = ...)`로 둔다.
- enum query parameter는 대소문자 정책을 문서화한다. 기본은 exact match다.

## Binder Rule

`WebDataBinder`는 강력하지만 위험하므로 기본은 사용하지 않는다.
사용해야 한다면 범위를 좁힌다.

Use when:

- legacy form/object binding에서 허용 필드를 제한해야 한다.
- 특정 controller에만 custom editor/converter가 필요하다.
- request field binding 보안이 필요한 admin form이 있다.

Rules:

- 전역 binder보다 controller-local `@InitBinder`를 우선한다.
- `setAllowedFields`를 사용해 binding 가능한 필드를 제한한다.
- `setDisallowedFields` 단독 사용은 우회 가능성이 있어 지양한다.
- entity를 binder target으로 사용하지 않는다.
- binder에서 business validation을 수행하지 않는다.
- type conversion은 가능하면 `Converter` 또는 `Formatter`로 분리한다.

```java
@InitBinder("request")
void initBinder(WebDataBinder binder) {
    binder.setAllowedFields("email", "companySlugs");
}
```

## Response Rule

- response body는 DTO 또는 공통 envelope로 반환한다.
- JPA entity를 반환하지 않는다.
- 반복되는 목록, page, cursor, error 응답은 프로젝트 공통 DTO를 사용한다.
- Spring Data `Page`를 그대로 반환하지 않고 `PageResponse<T>`로 변환한다.
- `ResponseEntity`는 status/header를 동적으로 제어해야 할 때만 사용한다.
- 단순 `200 OK`는 DTO를 직접 반환한다.
- create는 `201 Created`, body가 없으면 `204 No Content`를 사용한다.
- ISO-8601 timestamp는 `Instant` 또는 명시적 string formatter를 사용한다.
- 내부 상태, token hash, 원문 전문, 관리자 메모는 public response에 포함하지 않는다.

## Error Rule

- Controller에서 `try-catch`로 error payload를 만들지 않는다.
- `BusinessException`과 `ErrorCode`를 사용하고 `GlobalExceptionHandler`에서 변환한다.
- not found는 service에서 `BusinessException(ErrorCode.NOT_FOUND)` 또는 도메인별 code로 변환한다.
- validation error는 field list를 포함한다.
- fallback exception은 sanitized `INTERNAL_ERROR`로 반환한다.
- 예외 message에 secret, SQL, stack trace, token 원문을 포함하지 않는다.

## Pagination Rule

- page index는 0-based를 기본으로 한다.
- size 기본값과 최대값은 상수나 properties로 관리한다.
- public list와 admin list의 기본 size가 다르면 각각 명시한다.
- sort field는 whitelist만 허용한다.
- invalid sort field는 validation error로 처리하거나 무시한다. 프로젝트에서 하나로 고정한다.
- 목록 response에는 `page`, `size`, `totalElements`, `totalPages`, `items`를 명시한다.
- 단순 목록은 `ListResponse<T>`, offset page는 `PageResponse<T>`, cursor feed는 `SliceResponse<T>` 또는 `CursorResponse<T>`로 구분한다.

## Magic Number Rule

- page size, token length, title length, retry count, timeout, max list size는 상수 또는 configuration properties로 둔다.
- 테스트에서도 같은 숫자가 반복되면 test fixture constant로 둔다.
- API contract에 노출되는 숫자는 Wiki/OpenAPI에도 기록한다.

## Test Rule

- Controller를 추가하면 최소 `@WebMvcTest`를 추가한다.
- happy path, validation failure, not found/business exception mapping을 검증한다.
- service/repository logic은 mock 처리한다.
- JSON contract는 `jsonPath`로 필드 단위 검증한다.
- query default, max size, blank/null handling은 controller slice test에 포함한다.

## Checklist

- Controller가 repository/entity에 직접 의존하지 않는가?
- request DTO가 service object로 변환되는가?
- null/default/blank 처리 정책이 명시되어 있는가?
- page/size/sort 제한이 magic number 없이 관리되는가?
- validation error와 business error가 공통 error contract로 반환되는가?
- `@InitBinder`를 쓴다면 allowed fields가 지정되어 있는가?
- response에 내부 상태나 secret이 노출되지 않는가?
- `@WebMvcTest`가 mapping, validation, error contract를 검증하는가?

## References

- [api-design-convention.md](api-design-convention.md)
- [common-api-dto-convention.md](common-api-dto-convention.md)
- [request-response-dto-convention.md](request-response-dto-convention.md)
- [error-handling-convention.md](error-handling-convention.md)
- [controller-webmvc-test-convention.md](../test/controller-webmvc-test-convention.md)
