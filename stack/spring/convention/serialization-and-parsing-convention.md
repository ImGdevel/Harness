# Spring Serialization And Parsing Convention

## Purpose

Spring 애플리케이션에서 JSON 직렬화/역직렬화, 문자열 파싱, enum 변환, 외부 payload 파싱을 각 모듈이 임의로 구현하지 않도록 공통 기준을 둔다.
공통 parser/codec은 편의 유틸이 아니라 boundary 변환과 persistence 변환의 안정성을 책임지는 코드다.

이 문서는 모든 모듈에서 반복될 가능성이 높은 공통 메서드 후보, 공통화 승격 기준, Jackson `ObjectMapper` 사용 규칙, 파싱 실패 처리 방식을 고정한다.

## Scope

- Jackson `ObjectMapper`, `ObjectReader`, `ObjectWriter`
- JSON serialize/deserialize helper
- JSON list/map/tree parsing
- string normalization
- enum parsing
- date/time parsing
- URL/URI parsing
- CSV/simple delimiter parsing
- 공통 parser component와 feature-specific parser 분리 기준

## Core Decision

- `ObjectMapper`는 직접 `new ObjectMapper()`로 생성하지 않고 Spring Boot가 구성한 bean을 주입받아 재사용한다.
- 반복되는 JSON read/write 작업은 `ObjectReader`와 `ObjectWriter`를 재사용할 수 있게 별도 codec/parser component로 감싼다.
- 공통 parser는 domain 정책을 몰라야 한다.
- 파싱 실패를 조용히 삼키는 `tryParse`/`orDefault` 계열은 기본 금지다.
- fallback이 제품 정책이면 feature-specific parser 또는 assembler에서 명시적으로 처리한다.
- `common.util.JsonUtils` 같은 static 잡동사니 유틸은 만들지 않는다.

## Package Rule

공통 parser/codec은 프로젝트의 `common.serialization` 또는 `common.parser` 계열에 둔다.

```text
common/
  serialization/
    JsonCodec.java
    JsonSerializationException.java
  parser/
    StringNormalizer.java
    EnumParser.java
```

Rules:

- JSON처럼 format 중심 책임은 `common.serialization`에 둔다.
- 문자열 정규화처럼 format이 아닌 입력 변환은 `common.parser` 또는 `common.util`보다 더 명확한 패키지에 둔다.
- domain 의미가 들어가면 공통 패키지에 두지 않는다. 예: `EmailNormalizer`, `SlugGenerator`, `AiSummaryBulletParser`.
- feature-specific parser는 해당 feature의 `application`, `domain`, `infrastructure` 중 책임이 맞는 곳에 둔다.
- 공통 parser는 repository, service, security principal, HTTP request에 의존하지 않는다.

## Common Method Candidates

공통화 후보는 다음과 같다.

| Candidate | Package | Example Methods | Common화 기준 |
| --- | --- | --- | --- |
| JSON codec | `common.serialization` | `toJson`, `fromJson`, `fromJsonList`, `readTree` | 2개 이상 모듈에서 JSON text를 직접 다룬다 |
| JSON reader/writer factory | `common.serialization` | `readerFor`, `writerFor` | 같은 type/config로 반복 parse/write가 많다 |
| String normalizer | `common.parser` | `trimToNull`, `blankToNull`, `nullToEmpty`, `trimDistinct` | request query/body 정규화가 여러 API에서 반복된다 |
| Enum parser | `common.parser` | `parseEnumIgnoreCase`, `parseEnumOrThrow` | request enum 변환 규칙과 에러 메시지를 통일해야 한다 |
| Date/time parser | `common.parser` | `parseInstant`, `parseLocalDate`, `formatIsoInstant` | 외부 provider나 batch input의 날짜 포맷이 여러 곳에서 반복된다 |
| URI/URL parser | `common.parser` | `parseUri`, `normalizeUrl`, `originOf` | 외부 URL 정규화가 여러 모듈에서 반복된다 |
| Delimited text parser | `common.parser` | `splitCsvLike`, `splitPipe`, `joinCsvLike` | batch/admin import 등에서 간단한 구분자 파싱이 반복된다 |
| Safe log value formatter | `common.logging` | `maskEmail`, `truncate`, `safePayloadPreview` | 로그에 민감정보/긴 payload가 반복적으로 노출될 위험이 있다 |

Common화하지 않는 후보:

- AI 요약 bullet 파서처럼 특정 aggregate 저장 구조를 아는 parser
- 이메일/휴대폰/slug처럼 프로젝트 domain 정책이 강한 normalizer
- 특정 외부 API provider payload 전용 parser
- 화면 노출 fallback 문구를 결정하는 parser
- repository 조회나 권한 검사를 포함하는 mapper

## ObjectMapper Rule

Rules:

- `ObjectMapper`는 Spring Boot auto-configured bean을 constructor injection으로 받는다.
- `new ObjectMapper()`는 테스트 fixture나 독립 CLI를 제외하고 금지한다.
- `ObjectMapper` configuration은 `spring.jackson.*`, `Jackson2ObjectMapperBuilderCustomizer`, `@JsonComponent` 중 하나로 일관되게 관리한다.
- 모듈별로 별도 `ObjectMapper`를 만들지 않는다. 정말 필요한 경우 bean name과 사용 범위를 문서화한다.
- runtime 중 `ObjectMapper`를 계속 mutate하지 않는다. 설정 완료 후 read/write에 사용한다.
- 같은 target type을 반복해서 읽고 쓰면 `ObjectReader`/`ObjectWriter`를 component field로 만들어 재사용한다.

Allowed:

```java
@Component
@RequiredArgsConstructor
public class JsonCodec {

    private final ObjectMapper objectMapper;

    public <T> T fromJson(String json, Class<T> type) {
        try {
            return objectMapper.readValue(json, type);
        } catch (JsonProcessingException exception) {
            throw new JsonSerializationException("JSON 역직렬화에 실패했습니다.", exception);
        }
    }
}
```

Forbidden:

```java
public List<String> parse(String json) throws JsonProcessingException {
    return new ObjectMapper().readValue(json, new TypeReference<>() {});
}
```

## ObjectReader And ObjectWriter Rule

Jackson 문서 기준으로 `ObjectReader`와 `ObjectWriter`는 immutable/thread-safe하게 재사용할 수 있다.
동일 type과 동일 configuration으로 반복 작업을 수행하면 `ObjectMapper` 직접 호출보다 reader/writer를 field로 고정하는 것을 검토한다.

Use when:

- 같은 type을 batch에서 대량 parse한다.
- 같은 type을 반복 serialize한다.
- feature-specific parser가 같은 `TypeReference`를 반복 사용한다.

Avoid when:

- 한 번만 쓰는 단순 변환이다.
- target type이 요청마다 동적으로 바뀐다.
- reader/writer 생성을 공통화하면서 오히려 코드 이해가 어려워진다.

## JSON Codec Method Rule

공통 `JsonCodec`을 둔다면 최소 메서드는 다음으로 시작한다.

```java
String toJson(Object value);
<T> T fromJson(String json, Class<T> type);
<T> T fromJson(String json, TypeReference<T> typeReference);
<T> List<T> fromJsonList(String json, Class<T> elementType);
JsonNode readTree(String json);
```

Rules:

- `fromJson`은 실패 시 checked exception을 외부로 그대로 던지지 않는다.
- 공통 exception은 `JsonSerializationException`처럼 format 책임이 드러나는 이름을 사용한다.
- `fromJsonOrNull`, `fromJsonOrDefault`는 공통 API로 만들지 않는다.
- default fallback이 필요하면 호출부에서 `try/catch`와 정책 사유를 드러낸다.
- raw JSON을 API response로 그대로 내려주지 않는다.
- unknown field 허용 여부는 프로젝트 설정으로 통일한다.

## String Normalizer Rule

반복되는 request 정규화는 공통화 후보가 될 수 있다.

Candidates:

```java
String trimToNull(String value);
String blankToNull(String value);
String trimToEmpty(String value);
List<String> trimDistinct(List<String> values);
List<String> nullToEmpty(List<String> values);
```

Rules:

- request DTO 내부에서 한 번만 쓰는 정규화는 DTO private method로 둔다.
- 같은 정규화가 2개 이상 API에서 반복되면 공통 normalizer로 승격한다.
- domain 의미가 있는 정규화는 공통 normalizer로 올리지 않는다.
- `null`과 empty string의 의미가 다른 domain에서는 공통 normalizer를 무조건 적용하지 않는다.

## Enum Parser Rule

request query/path enum 변환은 에러 메시지와 허용값 노출 정책이 중요하다.

Candidates:

```java
<E extends Enum<E>> E parseEnumIgnoreCase(Class<E> enumType, String value, String fieldName);
<E extends Enum<E>> Optional<E> findEnumIgnoreCase(Class<E> enumType, String value);
```

Rules:

- client 입력을 enum으로 바꿀 때 허용값과 대소문자 정책을 문서화한다.
- enum mismatch는 `BusinessException` 또는 validation error로 변환하되 내부 enum package명을 노출하지 않는다.
- `Enum.valueOf`를 controller/service 곳곳에서 직접 호출하지 않는다.
- domain 내부 상태 전이는 enum parser가 아니라 domain method에서 검증한다.

## Date Time Parser Rule

Spring MVC request binding이 처리할 수 있는 ISO-8601 입력은 기본 binding을 우선한다.
외부 provider, batch file, legacy format처럼 여러 포맷을 허용해야 할 때만 parser를 둔다.

Candidates:

```java
Instant parseInstant(String value, String fieldName);
LocalDate parseLocalDate(String value, String fieldName);
String formatIsoInstant(Instant value);
```

Rules:

- API request는 가능한 ISO-8601 하나로 제한한다.
- 여러 날짜 포맷을 허용하는 parser는 public API보다 batch/import boundary에 둔다.
- timezone 보정 정책은 parser 내부에 숨기지 말고 이름이나 문서에 드러낸다.
- 날짜 parse 실패는 invalid request인지 external provider data error인지 구분한다.

## URI URL Parser Rule

URL은 보안과 정규화 영향이 있으므로 단순 `new URL(value)`를 여러 곳에 흩뿌리지 않는다.

Candidates:

```java
URI parseHttpUri(String value, String fieldName);
String normalizeUrl(String value);
String originOf(String value);
```

Rules:

- 허용 scheme은 기본 `http`, `https`로 제한한다.
- SSRF 방어가 필요한 outbound URL은 별도 security policy로 검증한다.
- canonical URL 정규화는 domain/persistence 정책이므로 feature-specific component로 둔다.
- normalize 결과가 uniqueness key에 쓰이면 migration과 테스트를 함께 둔다.

## Delimited Text Parser Rule

CSV/pipe/comma separated value를 request query나 batch import에서 반복하면 parser를 둔다.

Rules:

- 진짜 CSV 파일은 직접 split하지 말고 CSV library 도입을 검토한다.
- 단순 query value split은 empty token 제거, trim, distinct 정책을 고정한다.
- delimiter parser는 escape/quote 지원 여부를 명시한다.
- 모호하면 delimiter text 대신 JSON array나 multipart file format을 선택한다.

## Failure Handling Rule

파싱 실패는 발생 위치에 따라 다르게 처리한다.

| Boundary | Failure Type | Handling |
| --- | --- | --- |
| client request | invalid request | 400 계열 error code |
| DB stored JSON | data corruption or migration drift | error log + system exception, 또는 명시적 fallback |
| external provider payload | provider data error | retry/failure record/review_required |
| optional display data | graceful degradation | feature policy로 fallback 문구나 empty list |
| log preview | safe fallback | truncate/mask 후 safe string |

Rules:

- 공통 parser가 business fallback 문구를 결정하지 않는다.
- `catch (Exception)`으로 모든 파싱 실패를 삼키지 않는다.
- 실패 로그에는 record id, provider, field name처럼 추적 가능한 key를 남긴다.
- raw payload 전체를 로그에 남기지 않는다. 길이 제한 preview와 masking을 적용한다.
- fallback이 필요한 경우 테스트로 그 fallback 정책을 고정한다.

## Mapper And Parser Boundary

DTO factory, response assembler, parser의 책임은 분리한다.

DTO factory:

- 이미 준비된 값을 API shape로 복사한다.
- `from`/`of`로 순수 변환만 한다.
- JSON parse, repository 조회, 권한 판단을 하지 않는다.

Response assembler:

- 여러 source를 조합한다.
- nullable/fallback/presentation policy를 적용할 수 있다.
- 필요하면 parser component를 호출한다.

Parser/codec:

- format 변환만 한다.
- domain 정책과 화면 문구를 모른다.
- 실패 시 의미 있는 exception을 던진다.

## MapStruct Rule

MapStruct는 serialization/parsing 문제를 해결하는 도구가 아니다.

Use MapStruct only when:

- 반복 field copy가 매우 많다.
- 변환이 대부분 순수하고 정책이 없다.
- mapper interface와 generated code가 팀에 실질적인 유지보수 이득을 준다.

Do not use MapStruct when:

- JSON parse, masking, URL signing, locale, fallback 문구 같은 정책이 핵심이다.
- N+1 회피를 위한 in-memory join이나 batch 조회 결과 조합이 핵심이다.
- 단순 DTO가 몇 개 없고 직접 factory가 더 명확하다.

## Test Rule

- `JsonCodec`은 valid JSON, invalid JSON, list parsing, null/blank 입력 정책을 테스트한다.
- feature-specific parser는 fallback 여부와 실패 로그 key를 테스트한다.
- request normalizer는 trim, blank, duplicate 제거, max size를 테스트한다.
- enum parser는 대소문자, unknown value, error message를 테스트한다.
- date/time parser는 timezone과 invalid format을 테스트한다.
- URL parser는 scheme 제한, invalid URL, normalization을 테스트한다.

## Review Checklist

- `new ObjectMapper()`가 production code에 없는가?
- `ObjectMapper`가 Spring bean으로 주입되고 있는가?
- 반복 parse/write에 `ObjectReader`/`ObjectWriter` 재사용을 검토했는가?
- 공통 parser가 domain 정책이나 화면 문구를 몰라야 하는가?
- `fromJsonOrDefault`처럼 실패를 숨기는 API가 생기지 않았는가?
- 파싱 실패가 request error, data corruption, provider error 중 무엇인지 구분되는가?
- raw payload가 로그/API response에 그대로 노출되지 않는가?
- DTO factory에 JSON parse나 repository 조회가 들어가지 않았는가?
- feature-specific parser가 공통 패키지로 잘못 승격되지 않았는가?

## References

- [request-response-dto-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/request-response-dto-convention.md>)
- [common-api-dto-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/common-api-dto-convention.md>)
- [error-handling-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/error-handling-convention.md>)
- [serialization-and-parsing-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/serialization-and-parsing-snippet.md>)
