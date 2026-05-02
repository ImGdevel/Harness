# Spring Common Module Method Candidates

## Purpose

Spring 백엔드에서 반복되는 작은 helper를 매번 새로 만들지 않도록 공통 모듈 후보를 정리한다.
목표는 “모든 것을 공통화”가 아니라, 자주 반복되고 실패 비용이 큰 메서드를 일관된 이름과 책임으로 관리하는 것이다.

공통 모듈은 편의성보다 안정성, 성능, 테스트 가능성, 보안성을 우선한다.
공통화가 애매하면 feature 내부 private method로 시작하고, 2개 이상 모듈에서 같은 규칙이 반복될 때 승격한다.

## Core Decision

- JDK와 Spring이 이미 제공하는 기능을 먼저 검토한다.
- 이미 프로젝트에 들어온 라이브러리가 해결하는 문제라면 직접 구현보다 라이브러리를 우선한다.
- 새 외부 라이브러리는 “반복 구현 비용, 보안 위험, 표준 준수 필요성”이 분명할 때만 추가한다.
- 공통 모듈은 domain 정책을 몰라야 한다.
- `CommonUtils`, `DateUtils`, `StringUtils` 같은 잡동사니 이름은 금지한다. 책임별로 `StringNormalizer`, `SafeLogFormatter`, `JsonCodec`처럼 나눈다.
- 성능 민감 helper는 알고리즘 복잡도, allocation, regex compile 여부, stream 사용 여부를 문서화한다.

## Package Candidate

```text
common/
  guard/
    Guard.java
  parser/
    StringNormalizer.java
    EnumParser.java
    DateTimeParser.java
    UrlParser.java
  serialization/
    JsonCodec.java
  security/
    CryptoSupport.java
    TokenGenerator.java
    SensitiveDataMasker.java
  logging/
    SafeLogFormatter.java
  web/
    PagingParams.java
    SortParser.java
    UriBuilderSupport.java
  persistence/
    RepositoryGuards.java
  collection/
    CollectionSupport.java
  file/
    FileNameSanitizer.java
    ContentTypeDetector.java
```

Rules:

- `common`은 기술적 공통 책임만 가진다.
- domain 단어가 들어가면 해당 domain/application 패키지에 둔다.
- 외부 provider payload 전용 parser는 `common`에 두지 않는다.
- common 메서드는 가능하면 pure function으로 작성한다.
- Spring bean이 필요한 경우에만 component로 둔다. 그 외에는 final class static method 또는 value object를 검토한다.

## Library Selection Matrix

| Area | Prefer | Library Option | Use When | Avoid When |
| --- | --- | --- | --- | --- |
| 문자열 | JDK `String`, Apache Commons Lang `StringUtils` | `org.apache.commons:commons-lang3` | null-safe 문자열 작업, `trimToNull`, `abbreviate`, `normalizeSpace`가 반복된다 | 몇 개 메서드만 필요하고 직접 구현이 더 명확하다 |
| 컬렉션 | JDK `List`, `Map`, `Collectors` | Guava, Apache Commons Collections | `Multimap`, immutable collection, partition, unique index가 넓게 반복된다 | JDK Stream으로 충분하다 |
| JSON | Jackson auto-configured `ObjectMapper` | Jackson `ObjectReader`, `ObjectWriter` | JSON text를 저장/파싱하거나 반복 read/write가 많다 | DTO factory에 파싱을 숨기려는 목적이다 |
| URI | JDK `URI`, Spring `UriComponentsBuilder` | Apache Commons Validator `UrlValidator` | query parameter encoding, URL validation 정책이 필요하다 | 단순 string concat으로 URL을 만들 수 있다고 착각한다 |
| CSV | 직접 split 금지 | Apache Commons CSV | header, quote, escape, row limit가 필요하다 | 단순 query delimiter split이다 |
| MIME | JDK `Files.probeContentType` | Apache Tika | content 기반 MIME detection이 필요하다 | 파일 확장자만으로 충분한 내부 기능이다 |
| Hash/HMAC | JDK `MessageDigest`, `Mac` | Apache Commons Codec | digest/hmac helper가 반복되고 코드량을 줄이고 싶다 | password hashing 용도다. password는 BCrypt/Argon2를 사용한다 |
| 출력 인코딩 | template engine 기본 escape | OWASP Java Encoder | HTML/JS 문자열을 직접 생성해야 한다 | JSON API만 제공한다 |
| Retry/Circuit | 명시적 client policy | Resilience4j | 외부 API 호출 retry, circuit breaker, rate limit가 필요하다 | 단순 helper로 retry loop를 만들려는 경우 |
| Email/URL validation | Bean Validation | Apache Commons Validator | framework 밖에서 email/url validation이 반복된다 | Controller request validation이면 `@Email`, `@Pattern`이 충분하다 |
| Benchmark | 단위 테스트 + profiling | JMH | microbenchmark가 의사결정에 필요하다 | CI에서 일반 unit test처럼 돌리려는 경우 |

## Promotion Rule

공통 모듈로 승격한다:

- 같은 코드가 2개 이상 module 또는 feature에서 반복된다.
- 실패 처리 방식이 전체 프로젝트에서 같아야 한다.
- 보안/마스킹/인코딩처럼 실수 비용이 크다.
- 성능 특성이 중요하고 한 곳에서 튜닝해야 한다.
- 테스트 fixture를 공유해야 일관성이 생긴다.

공통 모듈로 승격하지 않는다:

- 특정 aggregate, table, provider payload 구조를 안다.
- 화면 문구나 fallback 정책을 결정한다.
- repository, service, security principal에 의존한다.
- 호출부마다 정책이 달라질 가능성이 높다.
- 단순히 한 파일이 길어져서 옮기는 목적이다.

## Candidate Catalog

### String

| Method | Responsibility | Performance Note | Library |
| --- | --- | --- | --- |
| `blankToNull` | null/blank string을 null로 정규화 | allocation 없음. `trim`이 필요한 경우만 호출 | Apache Commons Lang `StringUtils.trimToNull` |
| `trimToNull` | 앞뒤 공백 제거 후 빈 문자열이면 null | `String.strip`은 Unicode whitespace를 더 넓게 처리 | Apache Commons Lang |
| `trimToEmpty` | null을 empty string으로 정규화 | response보다 request normalization에 제한 사용 | Apache Commons Lang |
| `normalizeWhitespace` | 연속 whitespace를 단일 space로 축약 | regex는 static precompiled `Pattern` 사용 | Apache Commons Lang `normalizeSpace` |
| `truncate` | 긴 문자열을 최대 길이로 자름 | substring allocation. log path에서 max length 필수 | Apache Commons Lang `abbreviate`, `truncate` |
| `removeControlChars` | 로그/파일명에서 제어 문자 제거 | char loop가 regex보다 예측 가능 | 직접 구현 |
| `containsBlank` | collection 내 blank 존재 여부 | short-circuit stream 또는 for loop | 직접 구현 |
| `maskEmail` | 이메일 local part 마스킹 | email validation과 분리 | 직접 구현 |
| `maskPhone` | 전화번호 일부 마스킹 | 숫자만 추출할지 정책 명시 | 직접 구현 |

### Collection

| Method | Responsibility | Performance Note | Library |
| --- | --- | --- | --- |
| `nullToEmptyList` | null list를 immutable empty list로 변환 | 새 list 생성 금지 | JDK `List.of` |
| `nullToEmptySet` | null set을 immutable empty set으로 변환 | 새 set 생성 금지 | JDK `Set.of` |
| `distinctByKey` | stream distinct key predicate 생성 | concurrent set allocation 있음. 대량이면 loop 검토 | 직접 구현 |
| `hasDuplicate` | 중복 key 존재 여부 | set size 조기 종료 | 직접 구현 |
| `toMapStrict` | duplicate key면 예외 | silent overwrite 금지 | JDK `Collectors.toMap` merge function |
| `groupingByKey` | key별 list grouping | `LinkedHashMap`으로 순서 보존 여부 결정 | JDK `Collectors.groupingBy` |
| `chunk` | list를 일정 크기로 분할 | view 반환은 원본 변경 영향 주의 | Guava `Lists.partition` |
| `partition` | predicate 기준 true/false 분리 | 한 번 순회 | JDK custom |
| `firstOrNull` | 첫 항목 또는 null | stream보다 index 접근이 빠름 | 직접 구현 |
| `singleOrThrow` | 정확히 1개 항목 요구 | size 체크가 O(1)인 list 우선 | 직접 구현 |

### Guard And Validation

| Method | Responsibility | Performance Note | Library |
| --- | --- | --- | --- |
| `requireNonNull` | null guard | JDK `Objects.requireNonNull` 우선 | JDK |
| `requireNonBlank` | blank guard | domain invariant에 사용 | Spring `Assert.hasText` 가능 |
| `requirePositive` | 양수 검증 | primitive compare | 직접 구현 |
| `requireRange` | 숫자 범위 검증 | primitive compare | 직접 구현 |
| `requireMaxLength` | 문자열 길이 검증 | code point 기준 필요 여부 명시 | 직접 구현 |
| `requireNotEmpty` | collection empty 검증 | `Collection.isEmpty` | Spring `CollectionUtils` 가능 |
| `requireState` | 상태 조건 검증 | domain message 명확화 | 직접 구현 |
| `requireEnumValue` | enum 허용값 검증 | enum set cache 검토 | 직접 구현 |

### Enum And Code

| Method | Responsibility | Performance Note | Library |
| --- | --- | --- | --- |
| `parseEnumIgnoreCase` | request 문자열을 enum으로 변환 | 대량 반복이면 enum map cache | 직접 구현 |
| `findEnumIgnoreCase` | Optional enum lookup | 예외 없는 path | 직접 구현 |
| `allowedValues` | 허용 enum 값 문자열 | static cache 가능 | 직접 구현 |
| `codeToEnum` | external code -> enum | map 기반 O(1) lookup | 직접 구현 |
| `enumToCode` | enum -> external code | enum method 권장 | 직접 구현 |
| `validateCodeIn` | code whitelist 검증 | `Set.contains` | 직접 구현 |

### Date Time

| Method | Responsibility | Performance Note | Library |
| --- | --- | --- | --- |
| `parseInstant` | ISO instant parsing | `DateTimeFormatter`는 immutable 재사용 가능 | JDK |
| `parseLocalDate` | date parsing | formatter static final | JDK |
| `formatIsoInstant` | ISO instant format | formatter 재사용 | JDK |
| `startOfDay` | zone 기준 하루 시작 | timezone 명시 | JDK |
| `endOfDay` | zone 기준 하루 끝 | inclusive/exclusive 정책 명시 | JDK |
| `validateDateRange` | 시작/끝 범위 검증 | null 허용 정책 분리 | 직접 구현 |
| `isExpired` | clock 기준 만료 여부 | `Clock` 주입으로 테스트 가능 | JDK |
| `ClockHolder` | 현재 시각 dependency | static now 금지 | Spring bean |

### JSON And Serialization

| Method | Responsibility | Performance Note | Library |
| --- | --- | --- | --- |
| `toJson` | object -> JSON string | `ObjectMapper` bean 재사용 | Jackson |
| `fromJson` | JSON string -> object | checked exception 래핑 | Jackson |
| `fromJsonList` | JSON array -> list | `JavaType`/`TypeReference` 재사용 | Jackson |
| `readTree` | JSON tree parse | tree model은 allocation 큼 | Jackson |
| `safeJsonPreview` | log용 JSON preview | length limit + masking | 직접 구현 |
| `ObjectReader/ObjectWriter factory` | 반복 read/write 최적화 | reader/writer immutable 재사용 | Jackson |

### URL URI

| Method | Responsibility | Performance Note | Library |
| --- | --- | --- | --- |
| `parseHttpUri` | http/https URI 검증 | `URI.create` 예외 처리 | JDK |
| `normalizeUrl` | trailing slash, host case 등 정규화 | canonical key 영향 주의 | feature-specific |
| `extractHost` | host 추출 | URI parse 1회 | JDK |
| `extractOrigin` | scheme://host[:port] | port 처리 명시 | JDK |
| `urlEncode` | query value encoding | charset UTF-8 고정 | Spring `UriComponentsBuilder` |
| `urlDecode` | query decode | `+` 처리 주의 | JDK/Spring |
| `isHttpUrl` | HTTP URL 여부 | scheme whitelist | Apache Commons Validator 가능 |
| `removeTrailingSlash` | path 끝 slash 제거 | root path 보존 | 직접 구현 |

### Slug And Identifier

| Method | Responsibility | Performance Note | Library |
| --- | --- | --- | --- |
| `slugify` | display text -> slug candidate | locale, Unicode 정책 명시 | feature-specific |
| `normalizeSlug` | slug trim/lowercase | regex precompile | 직접 구현 |
| `validateSlug` | slug pattern 검증 | pattern static final | Bean Validation 가능 |
| `generateSlugCandidate` | base slug 생성 | collision 처리 제외 | feature-specific |
| `deduplicateSlug` | 중복 slug suffix | repository 필요하므로 service/policy | feature-specific |
| `shortUuid` | 짧은 random id | collision 가능성 문서화 | JDK/SecureRandom |
| `uuidWithoutDash` | UUID compact string | replace allocation | JDK |

### Paging And Sorting

| Method | Responsibility | Performance Note | Library |
| --- | --- | --- | --- |
| `normalizePage` | default page 적용 | primitive compare | 직접 구현 |
| `normalizeSize` | default/max size 적용 | primitive compare | 직접 구현 |
| `validateMaxSize` | size 상한 검증 | API별 상수/properties | 직접 구현 |
| `toPageRequest` | Spring `PageRequest` 생성 | sort whitelist 적용 후 생성 | Spring Data |
| `parseSort` | sort key whitelist | map lookup | 직접 구현 |
| `defaultSort` | default sort 결정 | API contract | 직접 구현 |
| `cursorEncode` | cursor object -> opaque string | JSON + Base64 URL-safe | Jackson/JDK |
| `cursorDecode` | opaque string -> cursor object | invalid cursor는 400 | Jackson/JDK |

### Security And Masking

| Method | Responsibility | Performance Note | Library |
| --- | --- | --- | --- |
| `hashSha256` | non-password hash | password 금지 | JDK/Commons Codec |
| `hmacSha256` | signed token/message | key 관리 별도 | JDK/Commons Codec |
| `constantTimeEquals` | timing attack 완화 비교 | length 차이 처리 명시 | JDK `MessageDigest.isEqual` |
| `generateSecureToken` | random token 생성 | `SecureRandom` bean 재사용 | JDK |
| `maskSecret` | secret 일부 마스킹 | 전체 길이 노출 여부 결정 | 직접 구현 |
| `maskBearerToken` | Authorization header 마스킹 | prefix 보존 | 직접 구현 |
| `redactPayload` | payload 민감정보 제거 | field whitelist/blacklist | 직접 구현 |

### Logging

| Method | Responsibility | Performance Note | Library |
| --- | --- | --- | --- |
| `truncatePayload` | 긴 payload 제한 | max length 필수 | 직접 구현 |
| `safeLogValue` | null/blank/long/sensitive 처리 | string concat 지양 | 직접 구현 |
| `safeExceptionMessage` | 외부 응답용 안전 메시지 | raw exception 노출 금지 | 직접 구현 |
| `requestId` | request id 획득/생성 | MDC 사용 | Spring/MDC |
| `traceId` | tracing id 획득 | observability stack 연동 | Micrometer/Brave/Otel |
| `formatKeyValueLog` | key=value 로그 포맷 | structured logging 우선 | 직접 구현 |

### File And Multipart

| Method | Responsibility | Performance Note | Library |
| --- | --- | --- | --- |
| `getExtension` | 파일 확장자 추출 | path separator 방어 | Apache Commons IO 가능 |
| `sanitizeFileName` | 파일명 안전화 | path traversal 방어 | 직접 구현 |
| `validateContentType` | 허용 content type 검증 | header 신뢰 금지 | 직접 구현 |
| `validateFileSize` | size 상한 검증 | streaming 전 선검증 | Spring MultipartFile |
| `readBytesWithLimit` | 제한된 byte read | OOM 방지 | 직접 구현 |
| `detectMimeType` | content 기반 MIME 감지 | 대용량 full read 금지 | Apache Tika |

### HTTP And External API

| Method | Responsibility | Performance Note | Library |
| --- | --- | --- | --- |
| `buildUri` | endpoint URI 구성 | query encoding 자동화 | Spring `UriComponentsBuilder` |
| `appendQueryParam` | query param 추가 | null skip 정책 | Spring |
| `is2xx` | 성공 status 판단 | status abstraction | Spring `HttpStatusCode` |
| `retryableStatus` | retry 대상 status 판단 | idempotency 고려 | feature-specific |
| `parseRetryAfter` | Retry-After header 해석 | HTTP-date/delta-seconds 지원 | 직접 구현 |
| `safeResponsePreview` | 외부 응답 log preview | length limit + masking | 직접 구현 |

### Error

| Method | Responsibility | Performance Note | Library |
| --- | --- | --- | --- |
| `notFound` | not found exception 생성 | error code 일관화 | project-specific |
| `invalidRequest` | invalid request exception 생성 | message 안정화 | project-specific |
| `conflict` | conflict exception 생성 | error code 일관화 | project-specific |
| `requireFound` | Optional empty면 not found | service readability | 직접 구현 |
| `unwrapRootCause` | root cause 추출 | loop guard | Apache Commons Lang 가능 |
| `toErrorResponse` | exception -> API error | controller advice 책임 | project-specific |
| `fieldErrorOf` | binding field error 변환 | rejected value masking | project-specific |

### JPA Repository

| Method | Responsibility | Performance Note | Library |
| --- | --- | --- | --- |
| `getReferenceOrThrow` | reference 조회 실패 처리 | lazy proxy 예외 위치 주의 | Spring Data/JPA |
| `findByIdOrThrow` | Optional 조회 guard | N+1 아님. 단건 조회 | 직접 구현 |
| `existsOrThrow` | 존재 여부 검증 | exists query 비용 | Spring Data |
| `validateAffectedRows` | update/delete row count 검증 | bulk update 결과 확인 | 직접 구현 |
| `pageableOf` | PageRequest 생성 | count 필요 여부 결정 | Spring Data |
| `countQueryNeeded` | count 실행 여부 판단 | slice/limit+1 우선 검토 | 직접 구현 |

### Transaction Lock Cache Event

| Area | Method | Responsibility | Performance Note |
| --- | --- | --- | --- |
| transaction | `requireActiveTransaction` | 트랜잭션 존재 검증 | test/debug 용도 |
| lock | `lockKeyOf` | distributed lock key 생성 | key cardinality 관리 |
| lock | `retryOnOptimisticLock` | optimistic lock retry | 무한 retry 금지 |
| cache | `cacheKeyOf` | cache key 조립 | delimiter collision 방지 |
| cache | `normalizeCachePart` | key part 정규화 | null token 정책 |
| cache | `versionedKey` | cache version prefix | deploy/cache migration |
| event | `eventId` | event id 생성 | idempotency |
| event | `aggregateKey` | aggregate type/id key | ordering |
| event | `idempotencyKey` | 중복 처리 key | stable input 기반 |
| event | `payloadToJson` | event payload serialize | JsonCodec 사용 |

### Email Notification Money Number

| Area | Method | Responsibility | Performance Note |
| --- | --- | --- | --- |
| email | `normalizeEmail` | lower/trim email | international email 정책 주의 |
| email | `validateEmailFormat` | email shape 검증 | Bean Validation/Commons Validator |
| email | `buildUnsubscribeToken` | unsubscribe token 생성 | HMAC/expiry 포함 |
| notification | `notificationDedupKey` | 알림 중복 방지 key | stable unique key |
| money | `requireNonNegative` | 음수 금지 | BigDecimal compare |
| money | `scaleMoney` | scale/rounding | currency policy |
| number | `percentOf` | percentage 계산 | divide by zero 처리 |
| number | `safeDivide` | 0 처리 | rounding mode 명시 |
| number | `clamp` | min/max 제한 | primitive compare |
| number | `roundHalfUp` | 반올림 | BigDecimal policy |

## Test Prefix Rule

공통 모듈 테스트는 메서드별 테스트 이름 앞에 다음 prefix를 붙인다.

| Prefix | Purpose | Example |
| --- | --- | --- |
| `normal_` | 일반 성공 경로 | `normal_blankToNull_trimsValue` |
| `edge_` | null, empty, boundary 값 | `edge_chunk_returnsEmptyWhenInputIsNull` |
| `error_` | 예외와 실패 메시지 | `error_singleOrThrow_throwsWhenMultipleItems` |
| `security_` | secret, masking, encoding, timing 비교 | `security_maskBearerToken_neverExposesFullToken` |
| `perf_` | 성능 회귀 guard | `perf_distinctByKey_handlesLargeInputWithoutQuadraticLoop` |

Rules:

- `perf_` unit test는 정확한 latency를 보장하지 않는다. O(n^2) 회귀, 과도한 allocation, regex 재컴파일 같은 구조적 회귀를 막는 용도다.
- microbenchmark가 필요하면 JMH를 별도 source set이나 별도 module로 둔다.
- CI에서 JMH를 일반 unit test처럼 돌리지 않는다.
- 시간 기반 assertion은 flakiness가 높으므로 가능하면 operation count, object reuse, algorithmic behavior를 검증한다.

## Implementation Checklist

- JDK/Spring/이미 도입된 라이브러리로 충분한가?
- 새 라이브러리 도입 사유가 README 또는 ADR에 남았는가?
- 메서드 이름이 domain이 아닌 기술 책임을 표현하는가?
- null/empty/failure 정책이 테스트로 고정됐는가?
- 성능 민감 path에서 regex, stream, collection copy가 과도하지 않은가?
- 보안 관련 helper가 raw secret을 로그에 노출하지 않는가?
- 파싱 실패가 request error, data corruption, provider error 중 무엇인지 구분되는가?

## References

- [serialization-and-parsing-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/serialization-and-parsing-convention.md>)
- [request-response-dto-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/request-response-dto-convention.md>)
- [repository-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/repository-design-convention.md>)
- [common-module-method-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/common-module-method-snippet.md>)
