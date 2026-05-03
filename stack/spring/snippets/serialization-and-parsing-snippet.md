# Serialization And Parsing Snippet

## JsonCodec

```java
package com.example.common.serialization;

import java.util.List;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class JsonCodec {

    private final ObjectMapper objectMapper;

    public String toJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException exception) {
            throw new JsonSerializationException("JSON 직렬화에 실패했습니다.", exception);
        }
    }

    public <T> T fromJson(String json, Class<T> type) {
        try {
            return objectMapper.readValue(json, type);
        } catch (JsonProcessingException exception) {
            throw new JsonSerializationException("JSON 역직렬화에 실패했습니다.", exception);
        }
    }

    public <T> T fromJson(String json, TypeReference<T> typeReference) {
        try {
            return objectMapper.readValue(json, typeReference);
        } catch (JsonProcessingException exception) {
            throw new JsonSerializationException("JSON 역직렬화에 실패했습니다.", exception);
        }
    }

    public <T> List<T> fromJsonList(String json, Class<T> elementType) {
        try {
            return objectMapper.readValue(
                    json,
                    objectMapper.getTypeFactory().constructCollectionType(List.class, elementType)
            );
        } catch (JsonProcessingException exception) {
            throw new JsonSerializationException("JSON 목록 역직렬화에 실패했습니다.", exception);
        }
    }

    public JsonNode readTree(String json) {
        try {
            return objectMapper.readTree(json);
        } catch (JsonProcessingException exception) {
            throw new JsonSerializationException("JSON tree 파싱에 실패했습니다.", exception);
        }
    }
}
```

## JsonSerializationException

```java
package com.example.common.serialization;

public class JsonSerializationException extends RuntimeException {

    public JsonSerializationException(String message, Throwable cause) {
        super(message, cause);
    }
}
```

## Feature Specific Parser

```java
package com.example.content.application;

import java.util.List;

import com.example.common.serialization.JsonCodec;
import com.example.common.serialization.JsonSerializationException;
import com.fasterxml.jackson.core.type.TypeReference;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class AiSummaryBulletParser {

    private static final TypeReference<List<String>> STRING_LIST_TYPE = new TypeReference<>() {
    };

    private final JsonCodec jsonCodec;

    public List<String> parseOrEmpty(Long summaryId, String bulletsJson) {
        try {
            return jsonCodec.fromJson(bulletsJson, STRING_LIST_TYPE);
        } catch (JsonSerializationException exception) {
            log.warn("AI 요약 bullet 파싱에 실패했습니다. summaryId={}", summaryId, exception);
            return List.of();
        }
    }
}
```

## StringNormalizer

```java
package com.example.common.parser;

import java.util.List;

public final class StringNormalizer {

    private StringNormalizer() {
    }

    public static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    public static List<String> trimDistinct(List<String> values) {
        if (values == null || values.isEmpty()) {
            return List.of();
        }
        return values.stream()
                .map(StringNormalizer::blankToNull)
                .filter(value -> value != null)
                .distinct()
                .toList();
    }
}
```

## EnumParser

```java
package com.example.common.parser;

import java.util.Arrays;
import java.util.Locale;

import com.example.common.error.BusinessException;
import com.example.common.error.CommonErrorCode;

public final class EnumParser {

    private EnumParser() {
    }

    public static <E extends Enum<E>> E parseIgnoreCase(Class<E> enumType, String value, String fieldName) {
        if (value == null || value.isBlank()) {
            throw invalidEnum(fieldName, enumType);
        }
        String normalizedValue = value.trim().toUpperCase(Locale.ROOT);
        return Arrays.stream(enumType.getEnumConstants())
                .filter(candidate -> candidate.name().equalsIgnoreCase(normalizedValue))
                .findFirst()
                .orElseThrow(() -> invalidEnum(fieldName, enumType));
    }

    private static BusinessException invalidEnum(String fieldName, Class<?> enumType) {
        String allowedValues = String.join(
                ", ",
                Arrays.stream(enumType.getEnumConstants())
                        .map(Object::toString)
                        .toList()
        );
        return new BusinessException(
                CommonErrorCode.INVALID_REQUEST,
                fieldName + " 값이 올바르지 않습니다. 허용값: " + allowedValues
        );
    }
}
```

## Response Assembler With Parser

```java
package com.example.publicapi.application;

import java.util.Optional;

import com.example.content.application.AiSummaryBulletParser;
import com.example.content.domain.AiSummary;
import com.example.content.domain.SummaryState;
import com.example.publicapi.dto.PublicPostSummaryResponse;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class PublicPostSummaryAssembler {

    private final AiSummaryBulletParser aiSummaryBulletParser;

    public Optional<PublicPostSummaryResponse> assemble(AiSummary summary) {
        if (summary.getSummaryState() != SummaryState.READY) {
            return Optional.empty();
        }
        return Optional.of(PublicPostSummaryResponse.of(
                summary.getHeadline(),
                aiSummaryBulletParser.parseOrEmpty(summary.getId(), summary.getBulletsJson())
        ));
    }
}
```

## Rules

- `ObjectMapper`는 Spring bean으로 주입받는다.
- 반복 작업은 `ObjectReader`/`ObjectWriter` 재사용을 검토한다.
- 공통 codec은 format 변환만 담당한다.
- fallback 정책은 feature-specific parser나 assembler에서 명시한다.
- DTO factory에는 JSON parse, repository 조회, 권한 판단을 넣지 않는다.

## References

- [serialization-and-parsing-convention.md](../convention/serialization-and-parsing-convention.md)
