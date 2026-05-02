# Common Module Method Snippet

## Use

Spring 공통 모듈 후보를 실제 코드로 옮길 때 참고하는 스니펫이다.
프로젝트에 그대로 복사하기 전에 package, error code, domain naming을 프로젝트 기준으로 조정한다.

## Guard

```java
package com.example.common.guard;

import java.util.Collection;
import java.util.Objects;

public final class Guard {

    private Guard() {
    }

    public static <T> T requireNonNull(T value, String fieldName) {
        return Objects.requireNonNull(value, fieldName + "은 null일 수 없습니다.");
    }

    public static String requireNonBlank(String value, String fieldName) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(fieldName + "은 비어 있을 수 없습니다.");
        }
        return value.trim();
    }

    public static int requirePositive(int value, String fieldName) {
        if (value <= 0) {
            throw new IllegalArgumentException(fieldName + "은 양수여야 합니다.");
        }
        return value;
    }

    public static int requireRange(int value, int min, int max, String fieldName) {
        if (value < min || value > max) {
            throw new IllegalArgumentException(fieldName + "은 " + min + " 이상 " + max + " 이하여야 합니다.");
        }
        return value;
    }

    public static String requireMaxLength(String value, int maxLength, String fieldName) {
        requireNonBlank(value, fieldName);
        if (value.length() > maxLength) {
            throw new IllegalArgumentException(fieldName + " 길이는 " + maxLength + " 이하여야 합니다.");
        }
        return value;
    }

    public static <T extends Collection<?>> T requireNotEmpty(T values, String fieldName) {
        if (values == null || values.isEmpty()) {
            throw new IllegalArgumentException(fieldName + "은 비어 있을 수 없습니다.");
        }
        return values;
    }

    public static void requireState(boolean expression, String message) {
        if (!expression) {
            throw new IllegalStateException(message);
        }
    }
}
```

## StringNormalizer

```java
package com.example.common.parser;

import java.util.Collection;
import java.util.regex.Pattern;

public final class StringNormalizer {

    private static final Pattern WHITESPACE = Pattern.compile("\\s+");

    private StringNormalizer() {
    }

    public static String blankToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    public static String trimToEmpty(String value) {
        return value == null ? "" : value.trim();
    }

    public static String normalizeWhitespace(String value) {
        String normalized = blankToNull(value);
        if (normalized == null) {
            return null;
        }
        return WHITESPACE.matcher(normalized).replaceAll(" ");
    }

    public static String truncate(String value, int maxLength) {
        if (value == null || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
    }

    public static String removeControlChars(String value) {
        if (value == null || value.isEmpty()) {
            return value;
        }
        StringBuilder builder = new StringBuilder(value.length());
        for (int index = 0; index < value.length(); index++) {
            char current = value.charAt(index);
            if (!Character.isISOControl(current)) {
                builder.append(current);
            }
        }
        return builder.toString();
    }

    public static boolean containsBlank(Collection<String> values) {
        if (values == null || values.isEmpty()) {
            return false;
        }
        for (String value : values) {
            if (value == null || value.isBlank()) {
                return true;
            }
        }
        return false;
    }
}
```

## CollectionSupport

```java
package com.example.common.collection;

import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.function.Function;
import java.util.function.Predicate;

public final class CollectionSupport {

    private CollectionSupport() {
    }

    public static <T> List<T> nullToEmptyList(List<T> values) {
        return values == null ? List.of() : values;
    }

    public static <T> Set<T> nullToEmptySet(Set<T> values) {
        return values == null ? Set.of() : values;
    }

    public static <T, K> Predicate<T> distinctByKey(Function<T, K> keyExtractor) {
        Set<K> seen = new LinkedHashSet<>();
        return value -> seen.add(keyExtractor.apply(value));
    }

    public static <T, K> boolean hasDuplicate(Collection<T> values, Function<T, K> keyExtractor) {
        if (values == null || values.size() < 2) {
            return false;
        }
        Set<K> seen = new LinkedHashSet<>();
        for (T value : values) {
            if (!seen.add(keyExtractor.apply(value))) {
                return true;
            }
        }
        return false;
    }

    public static <T, K> Map<K, T> toMapStrict(Collection<T> values, Function<T, K> keyExtractor) {
        Map<K, T> result = new LinkedHashMap<>();
        if (values == null) {
            return result;
        }
        for (T value : values) {
            K key = keyExtractor.apply(value);
            T previous = result.putIfAbsent(key, value);
            if (previous != null) {
                throw new IllegalArgumentException("중복 key가 존재합니다. key=" + key);
            }
        }
        return result;
    }

    public static <T, K> Map<K, List<T>> groupingByKey(Collection<T> values, Function<T, K> keyExtractor) {
        Map<K, List<T>> result = new LinkedHashMap<>();
        if (values == null) {
            return result;
        }
        for (T value : values) {
            result.computeIfAbsent(keyExtractor.apply(value), ignored -> new ArrayList<>()).add(value);
        }
        return result;
    }

    public static <T> List<List<T>> chunk(List<T> values, int chunkSize) {
        if (values == null || values.isEmpty()) {
            return List.of();
        }
        if (chunkSize <= 0) {
            throw new IllegalArgumentException("chunkSize는 양수여야 합니다.");
        }
        List<List<T>> chunks = new ArrayList<>((values.size() + chunkSize - 1) / chunkSize);
        for (int start = 0; start < values.size(); start += chunkSize) {
            chunks.add(List.copyOf(values.subList(start, Math.min(start + chunkSize, values.size()))));
        }
        return List.copyOf(chunks);
    }

    public static <T> Map<Boolean, List<T>> partition(Collection<T> values, Predicate<T> predicate) {
        Map<Boolean, List<T>> result = new LinkedHashMap<>();
        result.put(Boolean.TRUE, new ArrayList<>());
        result.put(Boolean.FALSE, new ArrayList<>());
        if (values == null) {
            return result;
        }
        for (T value : values) {
            result.get(predicate.test(value)).add(value);
        }
        return result;
    }

    public static <T> T firstOrNull(List<T> values) {
        return values == null || values.isEmpty() ? null : values.get(0);
    }

    public static <T> T singleOrThrow(List<T> values, String message) {
        if (values == null || values.size() != 1) {
            throw new IllegalArgumentException(message);
        }
        return values.get(0);
    }

    public static <T> Optional<T> first(List<T> values) {
        return Optional.ofNullable(firstOrNull(values));
    }
}
```

## EnumParser

```java
package com.example.common.parser;

import java.util.Arrays;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Function;
import java.util.stream.Collectors;

public final class EnumParser {

    private static final Map<Class<?>, Map<String, ? extends Enum<?>>> CACHE = new ConcurrentHashMap<>();

    private EnumParser() {
    }

    public static <E extends Enum<E>> E parseIgnoreCase(Class<E> enumType, String value, String fieldName) {
        if (value == null || value.isBlank()) {
            throw invalidEnum(fieldName, enumType);
        }
        E result = findIgnoreCase(enumType, value);
        if (result == null) {
            throw invalidEnum(fieldName, enumType);
        }
        return result;
    }

    @SuppressWarnings("unchecked")
    public static <E extends Enum<E>> E findIgnoreCase(Class<E> enumType, String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        Map<String, E> enumMap = (Map<String, E>) CACHE.computeIfAbsent(enumType, EnumParser::indexByUpperName);
        return enumMap.get(value.trim().toUpperCase(Locale.ROOT));
    }

    public static String allowedValues(Class<?> enumType) {
        return String.join(
                ", ",
                Arrays.stream(enumType.asSubclass(Enum.class).getEnumConstants())
                        .map(Enum::name)
                        .toList()
        );
    }

    public static <E extends Enum<E> & CodeEnum> E codeToEnum(Class<E> enumType, String code, String fieldName) {
        if (code == null || code.isBlank()) {
            throw invalidCode(fieldName, enumType);
        }
        for (E value : enumType.getEnumConstants()) {
            if (value.code().equalsIgnoreCase(code.trim())) {
                return value;
            }
        }
        throw invalidCode(fieldName, enumType);
    }

    public static <E extends Enum<E> & CodeEnum> String enumToCode(E value) {
        return value.code();
    }

    public static <E extends Enum<E> & CodeEnum> void validateCodeIn(Class<E> enumType, String code, String fieldName) {
        codeToEnum(enumType, code, fieldName);
    }

    private static Map<String, ? extends Enum<?>> indexByUpperName(Class<?> enumType) {
        return Arrays.stream(enumType.asSubclass(Enum.class).getEnumConstants())
                .collect(Collectors.toUnmodifiableMap(
                        value -> value.name().toUpperCase(Locale.ROOT),
                        Function.identity()
                ));
    }

    private static IllegalArgumentException invalidEnum(String fieldName, Class<?> enumType) {
        return new IllegalArgumentException(
                fieldName + " 값이 올바르지 않습니다. 허용값: " + allowedValues(enumType)
        );
    }

    private static <E extends Enum<E> & CodeEnum> IllegalArgumentException invalidCode(String fieldName, Class<E> enumType) {
        String allowedCodes = Arrays.stream(enumType.getEnumConstants())
                .map(CodeEnum::code)
                .collect(Collectors.joining(", "));
        return new IllegalArgumentException(fieldName + " 코드가 올바르지 않습니다. 허용값: " + allowedCodes);
    }

    public interface CodeEnum {

        String code();
    }
}
```

## DateTimeSupport

```java
package com.example.common.parser;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeParseException;

public final class DateTimeSupport {

    private DateTimeSupport() {
    }

    public static Instant parseInstant(String value, String fieldName) {
        try {
            return Instant.parse(value);
        } catch (DateTimeParseException exception) {
            throw new IllegalArgumentException(fieldName + "은 ISO-8601 instant 형식이어야 합니다.", exception);
        }
    }

    public static LocalDate parseLocalDate(String value, String fieldName) {
        try {
            return LocalDate.parse(value);
        } catch (DateTimeParseException exception) {
            throw new IllegalArgumentException(fieldName + "은 yyyy-MM-dd 형식이어야 합니다.", exception);
        }
    }

    public static String formatIsoInstant(Instant value) {
        return value == null ? null : value.toString();
    }

    public static Instant startOfDay(LocalDate date, ZoneId zoneId) {
        return date.atStartOfDay(zoneId).toInstant();
    }

    public static Instant exclusiveEndOfDay(LocalDate date, ZoneId zoneId) {
        return date.plusDays(1).atStartOfDay(zoneId).toInstant();
    }

    public static void validateDateRange(Instant start, Instant end) {
        if (start != null && end != null && start.isAfter(end)) {
            throw new IllegalArgumentException("시작 시각은 종료 시각보다 늦을 수 없습니다.");
        }
    }

    public static boolean isExpired(Instant expiresAt, Clock clock) {
        return expiresAt != null && !Instant.now(clock).isBefore(expiresAt);
    }
}
```

## UrlSupport

```java
package com.example.common.parser;

import java.net.URI;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Locale;

public final class UrlSupport {

    private UrlSupport() {
    }

    public static URI parseHttpUri(String value, String fieldName) {
        URI uri = URI.create(value);
        String scheme = uri.getScheme();
        if (scheme == null || (!scheme.equalsIgnoreCase("http") && !scheme.equalsIgnoreCase("https"))) {
            throw new IllegalArgumentException(fieldName + "은 http 또는 https URL이어야 합니다.");
        }
        if (uri.getHost() == null || uri.getHost().isBlank()) {
            throw new IllegalArgumentException(fieldName + "은 host를 포함해야 합니다.");
        }
        return uri;
    }

    public static boolean isHttpUrl(String value) {
        try {
            parseHttpUri(value, "url");
            return true;
        } catch (IllegalArgumentException exception) {
            return false;
        }
    }

    public static String extractHost(String value) {
        return parseHttpUri(value, "url").getHost().toLowerCase(Locale.ROOT);
    }

    public static String extractOrigin(String value) {
        URI uri = parseHttpUri(value, "url");
        int port = uri.getPort();
        String portPart = port < 0 ? "" : ":" + port;
        return uri.getScheme().toLowerCase(Locale.ROOT) + "://" + uri.getHost().toLowerCase(Locale.ROOT) + portPart;
    }

    public static String normalizeUrl(String value) {
        URI uri = parseHttpUri(removeTrailingSlash(value), "url");
        String origin = extractOrigin(uri.toString());
        String path = uri.getRawPath() == null ? "" : removeTrailingSlash(uri.getRawPath());
        String query = uri.getRawQuery() == null ? "" : "?" + uri.getRawQuery();
        return origin + path + query;
    }

    public static String urlEncode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    public static String urlDecode(String value) {
        return URLDecoder.decode(value, StandardCharsets.UTF_8);
    }

    public static String removeTrailingSlash(String value) {
        if (value == null || value.length() <= 1 || !value.endsWith("/")) {
            return value;
        }
        int end = value.length();
        while (end > 1 && value.charAt(end - 1) == '/') {
            end--;
        }
        return value.substring(0, end);
    }
}
```

## SlugAndIdSupport

```java
package com.example.common.identifier;

import java.security.SecureRandom;
import java.text.Normalizer;
import java.util.Base64;
import java.util.Locale;
import java.util.UUID;
import java.util.regex.Pattern;

public final class SlugAndIdSupport {

    private static final Pattern NON_SLUG = Pattern.compile("[^a-z0-9-]+");
    private static final Pattern MULTI_DASH = Pattern.compile("-+");
    private static final Pattern EDGE_DASH = Pattern.compile("^-|-$");
    private static final Pattern DIACRITICS = Pattern.compile("\\p{M}");
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private SlugAndIdSupport() {
    }

    public static String slugify(String value) {
        String ascii = DIACRITICS.matcher(Normalizer.normalize(value, Normalizer.Form.NFD))
                .replaceAll("")
                .toLowerCase(Locale.ROOT)
                .trim();
        String slug = NON_SLUG.matcher(ascii).replaceAll("-");
        return EDGE_DASH.matcher(MULTI_DASH.matcher(slug).replaceAll("-")).replaceAll("");
    }

    public static void validateSlug(String slug) {
        if (slug == null || !slug.matches("^[a-z0-9]+(?:-[a-z0-9]+)*$")) {
            throw new IllegalArgumentException("slug 형식이 올바르지 않습니다.");
        }
    }

    public static String uuidWithoutDash() {
        return UUID.randomUUID().toString().replace("-", "");
    }

    public static String secureToken(int byteLength) {
        byte[] bytes = new byte[byteLength];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
```

## PagingAndSortSupport

```java
package com.example.common.web;

import java.util.Map;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;

public final class PagingAndSortSupport {

    private PagingAndSortSupport() {
    }

    public static int normalizePage(Integer page) {
        if (page == null) {
            return 0;
        }
        if (page < 0) {
            throw new IllegalArgumentException("page는 0 이상이어야 합니다.");
        }
        return page;
    }

    public static int normalizeSize(Integer size, int defaultSize, int maxSize) {
        int normalizedSize = size == null ? defaultSize : size;
        if (normalizedSize < 1 || normalizedSize > maxSize) {
            throw new IllegalArgumentException("size는 1 이상 " + maxSize + " 이하여야 합니다.");
        }
        return normalizedSize;
    }

    public static Sort parseSort(String value, Map<String, Sort> whitelist, String defaultKey) {
        String key = value == null || value.isBlank() ? defaultKey : value.trim();
        Sort sort = whitelist.get(key);
        if (sort == null) {
            throw new IllegalArgumentException("sort 값이 올바르지 않습니다. 허용값: " + whitelist.keySet());
        }
        return sort;
    }

    public static PageRequest toPageRequest(int page, int size, Sort sort) {
        return PageRequest.of(page, size, sort);
    }
}
```

## CursorSupport

```java
package com.example.common.web;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

import com.example.common.serialization.JsonCodec;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class CursorSupport {

    private final JsonCodec jsonCodec;

    public String cursorEncode(Object cursor) {
        String json = jsonCodec.toJson(cursor);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(json.getBytes(StandardCharsets.UTF_8));
    }

    public <T> T cursorDecode(String cursor, Class<T> cursorType) {
        try {
            byte[] decoded = Base64.getUrlDecoder().decode(cursor);
            return jsonCodec.fromJson(new String(decoded, StandardCharsets.UTF_8), cursorType);
        } catch (IllegalArgumentException exception) {
            throw new IllegalArgumentException("cursor 형식이 올바르지 않습니다.", exception);
        }
    }
}
```

## CryptoAndMaskingSupport

```java
package com.example.common.security;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public final class CryptoAndMaskingSupport {

    private CryptoAndMaskingSupport() {
    }

    public static String hashSha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 알고리즘을 사용할 수 없습니다.", exception);
        }
    }

    public static String hmacSha256(String secret, String value) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return HexFormat.of().formatHex(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception exception) {
            throw new IllegalStateException("HMAC-SHA256 생성에 실패했습니다.", exception);
        }
    }

    public static boolean constantTimeEquals(String left, String right) {
        if (left == null || right == null) {
            return false;
        }
        return MessageDigest.isEqual(left.getBytes(StandardCharsets.UTF_8), right.getBytes(StandardCharsets.UTF_8));
    }

    public static String maskEmail(String email) {
        if (email == null || !email.contains("@")) {
            return "***";
        }
        int at = email.indexOf('@');
        String local = email.substring(0, at);
        String domain = email.substring(at);
        String visible = local.length() <= 2 ? local.substring(0, 1) : local.substring(0, 2);
        return visible + "***" + domain;
    }

    public static String maskBearerToken(String authorization) {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            return "***";
        }
        String token = authorization.substring("Bearer ".length());
        if (token.length() <= 8) {
            return "Bearer ***";
        }
        return "Bearer " + token.substring(0, 4) + "***" + token.substring(token.length() - 4);
    }

    public static String maskSecret(String value) {
        if (value == null || value.length() <= 4) {
            return "***";
        }
        return value.substring(0, 2) + "***" + value.substring(value.length() - 2);
    }
}
```

## PayloadRedactor

```java
package com.example.common.security;

import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

public final class PayloadRedactor {

    private static final Set<String> SENSITIVE_KEYS = Set.of(
            "password",
            "token",
            "secret",
            "authorization",
            "access_token",
            "refresh_token"
    );

    private PayloadRedactor() {
    }

    public static Map<String, Object> redactPayload(Map<String, Object> payload) {
        Map<String, Object> redacted = new LinkedHashMap<>();
        if (payload == null) {
            return redacted;
        }
        payload.forEach((key, value) -> {
            String normalizedKey = key == null ? "" : key.toLowerCase(Locale.ROOT);
            redacted.put(key, SENSITIVE_KEYS.contains(normalizedKey) ? "***" : value);
        });
        return redacted;
    }
}
```

## SafeLogFormatter

```java
package com.example.common.logging;

public final class SafeLogFormatter {

    private SafeLogFormatter() {
    }

    public static String truncatePayload(String value, int maxLength) {
        if (value == null) {
            return null;
        }
        if (value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength) + "...(truncated)";
    }

    public static String safeExceptionMessage(Throwable throwable) {
        if (throwable == null || throwable.getMessage() == null) {
            return throwable == null ? "unknown" : throwable.getClass().getSimpleName();
        }
        return truncatePayload(throwable.getMessage(), 300);
    }

    public static String safeLogValue(Object value) {
        return value == null ? "null" : truncatePayload(String.valueOf(value), 300);
    }

    public static String requestId() {
        String value = org.slf4j.MDC.get("requestId");
        return value == null ? "unknown" : value;
    }

    public static String traceId() {
        String value = org.slf4j.MDC.get("traceId");
        return value == null ? "unknown" : value;
    }

    public static String keyValue(String key, Object value) {
        return key + "=" + (value == null ? "null" : truncatePayload(String.valueOf(value), 300));
    }
}
```

## FileSupport

```java
package com.example.common.file;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Locale;
import java.util.Set;

public final class FileSupport {

    private FileSupport() {
    }

    public static String getExtension(String fileName) {
        if (fileName == null) {
            return "";
        }
        String safeName = sanitizeFileName(fileName);
        int dot = safeName.lastIndexOf('.');
        return dot < 0 ? "" : safeName.substring(dot + 1).toLowerCase(Locale.ROOT);
    }

    public static String sanitizeFileName(String fileName) {
        if (fileName == null || fileName.isBlank()) {
            throw new IllegalArgumentException("파일명이 비어 있습니다.");
        }
        String name = fileName.replace("\\", "/");
        name = name.substring(name.lastIndexOf('/') + 1);
        name = name.replaceAll("[\\r\\n\\t\\u0000]", "_");
        if (name.equals(".") || name.equals("..") || name.isBlank()) {
            throw new IllegalArgumentException("파일명이 올바르지 않습니다.");
        }
        return name;
    }

    public static void validateContentType(String contentType, Set<String> allowedTypes) {
        if (contentType == null || !allowedTypes.contains(contentType.toLowerCase(Locale.ROOT))) {
            throw new IllegalArgumentException("허용되지 않은 content type입니다.");
        }
    }

    public static void validateFileSize(long size, long maxSize) {
        if (size < 0 || size > maxSize) {
            throw new IllegalArgumentException("파일 크기가 허용 범위를 초과했습니다.");
        }
    }

    public static byte[] readBytesWithLimit(InputStream inputStream, int maxBytes) throws IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream(Math.min(maxBytes, 8192));
        byte[] buffer = new byte[8192];
        int total = 0;
        int read;
        while ((read = inputStream.read(buffer)) != -1) {
            total += read;
            if (total > maxBytes) {
                throw new IllegalArgumentException("입력 크기가 허용 범위를 초과했습니다.");
            }
            output.write(buffer, 0, read);
        }
        return output.toByteArray();
    }
}
```

## HttpSupport

```java
package com.example.common.web;

import java.net.URI;
import java.time.Duration;
import java.time.Instant;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Optional;

import org.springframework.http.HttpStatusCode;
import org.springframework.web.util.UriComponentsBuilder;

public final class HttpSupport {

    private HttpSupport() {
    }

    public static URI buildUri(String baseUrl, String path, String queryName, String queryValue) {
        return UriComponentsBuilder.fromUriString(baseUrl)
                .path(path)
                .queryParam(queryName, queryValue)
                .encode()
                .build()
                .toUri();
    }

    public static UriComponentsBuilder appendQueryParam(UriComponentsBuilder builder, String name, Object value) {
        if (value == null) {
            return builder;
        }
        return builder.queryParam(name, value);
    }

    public static boolean is2xx(HttpStatusCode statusCode) {
        return statusCode != null && statusCode.is2xxSuccessful();
    }

    public static boolean retryableStatus(HttpStatusCode statusCode) {
        return statusCode != null && (statusCode.value() == 429 || statusCode.is5xxServerError());
    }

    public static Optional<Duration> parseRetryAfterSeconds(String value) {
        if (value == null || value.isBlank()) {
            return Optional.empty();
        }
        try {
            long seconds = Long.parseLong(value.trim());
            return Optional.of(Duration.ofSeconds(seconds));
        } catch (NumberFormatException exception) {
            return Optional.empty();
        }
    }

    public static Optional<Instant> parseRetryAfterHttpDate(String value) {
        if (value == null || value.isBlank()) {
            return Optional.empty();
        }
        try {
            return Optional.of(DateTimeFormatter.RFC_1123_DATE_TIME.parse(value.trim(), Instant::from));
        } catch (DateTimeParseException exception) {
            return Optional.empty();
        }
    }

    public static String safeResponsePreview(String body, int maxLength) {
        return com.example.common.logging.SafeLogFormatter.truncatePayload(body, maxLength);
    }
}
```

## ErrorAndRepositorySupport

```java
package com.example.common.error;

import java.util.Optional;

public final class ErrorAndRepositorySupport {

    private ErrorAndRepositorySupport() {
    }

    public static <T> T requireFound(Optional<T> value, RuntimeException exception) {
        return value.orElseThrow(() -> exception);
    }

    public static Throwable unwrapRootCause(Throwable throwable) {
        Throwable current = throwable;
        while (current != null && current.getCause() != null && current.getCause() != current) {
            current = current.getCause();
        }
        return current == null ? throwable : current;
    }

    public static void validateAffectedRows(int affectedRows, int expectedRows) {
        if (affectedRows != expectedRows) {
            throw new IllegalStateException("영향 row 수가 예상과 다릅니다. expected=" + expectedRows + ", actual=" + affectedRows);
        }
    }
}
```

## KeySupport

```java
package com.example.common.key;

import java.util.Arrays;
import java.util.stream.Collectors;

public final class KeySupport {

    private KeySupport() {
    }

    public static String cacheKeyOf(String prefix, Object... parts) {
        return prefix + ":" + Arrays.stream(parts)
                .map(KeySupport::normalizeCachePart)
                .collect(Collectors.joining(":"));
    }

    public static String normalizeCachePart(Object value) {
        if (value == null) {
            return "_";
        }
        return String.valueOf(value).trim().replace(":", "_");
    }

    public static String versionedKey(String version, String key) {
        return version + ":" + key;
    }

    public static String aggregateKey(String aggregateType, Object aggregateId) {
        return aggregateType + ":" + aggregateId;
    }

    public static String idempotencyKey(String operation, Object... parts) {
        return cacheKeyOf("idem:" + operation, parts);
    }

    public static String lockKeyOf(String resource, Object id) {
        return cacheKeyOf("lock", resource, id);
    }

    public static String eventId(String eventType, Object aggregateId) {
        return cacheKeyOf("event", eventType, aggregateId, java.util.UUID.randomUUID());
    }
}
```

## TransactionSupport

```java
package com.example.common.transaction;

import java.util.function.Supplier;

import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.transaction.support.TransactionSynchronizationManager;

public final class TransactionSupport {

    private TransactionSupport() {
    }

    public static void requireActiveTransaction() {
        if (!TransactionSynchronizationManager.isActualTransactionActive()) {
            throw new IllegalStateException("활성 트랜잭션이 필요합니다.");
        }
    }

    public static <T> T retryOnOptimisticLock(Supplier<T> action, int maxAttempts) {
        if (maxAttempts < 1) {
            throw new IllegalArgumentException("maxAttempts는 1 이상이어야 합니다.");
        }
        OptimisticLockingFailureException lastException = null;
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                return action.get();
            } catch (OptimisticLockingFailureException exception) {
                lastException = exception;
            }
        }
        throw lastException;
    }
}
```

## EmailNotificationSupport

```java
package com.example.common.notification;

import java.util.Locale;

import com.example.common.security.CryptoAndMaskingSupport;

public final class EmailNotificationSupport {

    private EmailNotificationSupport() {
    }

    public static String normalizeEmail(String email) {
        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("email은 비어 있을 수 없습니다.");
        }
        return email.trim().toLowerCase(Locale.ROOT);
    }

    public static void validateEmailFormat(String email) {
        if (email == null || !email.contains("@")) {
            throw new IllegalArgumentException("email 형식이 올바르지 않습니다.");
        }
    }

    public static String buildUnsubscribeToken(String secret, Long subscriberId, long expiresAtEpochSecond) {
        String payload = subscriberId + ":" + expiresAtEpochSecond;
        return payload + ":" + CryptoAndMaskingSupport.hmacSha256(secret, payload);
    }

    public static String notificationDedupKey(Long subscriberId, Long postId, String channel) {
        return subscriberId + ":" + postId + ":" + channel;
    }
}
```

## MoneyNumberSupport

```java
package com.example.common.number;

import java.math.BigDecimal;
import java.math.RoundingMode;

public final class MoneyNumberSupport {

    private MoneyNumberSupport() {
    }

    public static BigDecimal requireNonNegative(BigDecimal value, String fieldName) {
        if (value == null || value.signum() < 0) {
            throw new IllegalArgumentException(fieldName + "은 0 이상이어야 합니다.");
        }
        return value;
    }

    public static BigDecimal scaleMoney(BigDecimal value, int scale) {
        return requireNonNegative(value, "amount").setScale(scale, RoundingMode.HALF_UP);
    }

    public static BigDecimal safeDivide(BigDecimal numerator, BigDecimal denominator, int scale) {
        if (denominator == null || denominator.signum() == 0) {
            return BigDecimal.ZERO.setScale(scale, RoundingMode.HALF_UP);
        }
        return numerator.divide(denominator, scale, RoundingMode.HALF_UP);
    }

    public static BigDecimal percentOf(BigDecimal numerator, BigDecimal denominator, int scale) {
        return safeDivide(numerator, denominator, scale + 2)
                .multiply(BigDecimal.valueOf(100))
                .setScale(scale, RoundingMode.HALF_UP);
    }

    public static BigDecimal roundHalfUp(BigDecimal value, int scale) {
        return value.setScale(scale, RoundingMode.HALF_UP);
    }

    public static int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }
}
```

## Test Prefix Examples

```java
package com.example.common.collection;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.IntStream;

import org.junit.jupiter.api.Test;

class CollectionSupportTests {

    @Test
    void normal_chunk_splitsListBySize() {
        List<List<Integer>> chunks = CollectionSupport.chunk(List.of(1, 2, 3, 4, 5), 2);

        assertThat(chunks).containsExactly(List.of(1, 2), List.of(3, 4), List.of(5));
    }

    @Test
    void edge_chunk_returnsEmptyWhenInputIsNull() {
        assertThat(CollectionSupport.chunk(null, 10)).isEmpty();
    }

    @Test
    void error_singleOrThrow_throwsWhenMultipleItems() {
        assertThatThrownBy(() -> CollectionSupport.singleOrThrow(List.of("a", "b"), "하나만 존재해야 합니다."))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("하나만");
    }

    @Test
    void perf_hasDuplicate_handlesLargeInputWithoutQuadraticLoop() {
        List<Integer> values = new ArrayList<>(IntStream.range(0, 100_000).boxed().toList());
        values.add(99_999);

        assertThat(CollectionSupport.hasDuplicate(values, value -> value)).isTrue();
    }
}
```

```java
package com.example.common.security;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class CryptoAndMaskingSupportTests {

    @Test
    void security_maskBearerToken_neverExposesFullToken() {
        String masked = CryptoAndMaskingSupport.maskBearerToken("Bearer abcdefghijklmnop");

        assertThat(masked).isEqualTo("Bearer abcd***mnop");
        assertThat(masked).doesNotContain("abcdefghijklmnop");
    }
}
```

## Library Usage Examples

```java
// Apache Commons Lang: 문자열 null-safe 처리
String value = org.apache.commons.lang3.StringUtils.trimToNull("  hello  ");
String preview = org.apache.commons.lang3.StringUtils.abbreviate("very long payload", 10);
```

```java
// Spring UriComponentsBuilder: query parameter encoding
java.net.URI uri = org.springframework.web.util.UriComponentsBuilder
        .fromUriString("https://api.example.com")
        .path("/posts")
        .queryParam("q", "Spring Boot 운영")
        .encode()
        .build()
        .toUri();
```

```java
// Apache Commons Codec: SHA-256/HMAC helper
String sha256 = org.apache.commons.codec.digest.DigestUtils.sha256Hex("payload");
String hmac = org.apache.commons.codec.digest.HmacUtils.hmacSha256Hex("secret".getBytes(), "payload");
```

```java
// Apache Commons Validator: framework 밖 email/url validation
boolean validEmail = org.apache.commons.validator.routines.EmailValidator.getInstance().isValid("user@example.com");
boolean validUrl = org.apache.commons.validator.routines.UrlValidator.getInstance().isValid("https://example.com");
```

```java
// Apache Commons IO: file name/path component 추출
String name = org.apache.commons.io.FilenameUtils.getName("/tmp/report.pdf");
String extension = org.apache.commons.io.FilenameUtils.getExtension(name);
```

```java
// Apache Commons CSV: header 기반 CSV parsing
try (org.apache.commons.csv.CSVParser parser = org.apache.commons.csv.CSVParser.parse(
        csvText,
        org.apache.commons.csv.CSVFormat.DEFAULT.builder().setHeader().setSkipHeaderRecord(true).get()
)) {
    for (org.apache.commons.csv.CSVRecord record : parser) {
        String email = record.get("email");
    }
}
```

```java
// Apache Tika: content 기반 MIME detection
String mimeType = new org.apache.tika.Tika().detect(file);
```

```java
// OWASP Java Encoder: HTML 출력 인코딩
String safeHtml = org.owasp.encoder.Encode.forHtml(userInput);
```

```java
// Resilience4j: 외부 API fault tolerance는 직접 retry loop 대신 전용 라이브러리 검토
@io.github.resilience4j.retry.annotation.Retry(name = "blogSource")
@io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker(name = "blogSource")
public String fetchFeed(String feedUrl) {
    return httpClient.get(feedUrl);
}
```

## JMH Benchmark Skeleton

정확한 microbenchmark가 필요하면 unit test가 아니라 JMH를 별도 benchmark source set에서 실행한다.

```java
package com.example.common.benchmark;

import java.util.List;
import java.util.concurrent.TimeUnit;

import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.BenchmarkMode;
import org.openjdk.jmh.annotations.Fork;
import org.openjdk.jmh.annotations.Measurement;
import org.openjdk.jmh.annotations.Mode;
import org.openjdk.jmh.annotations.OutputTimeUnit;
import org.openjdk.jmh.annotations.Scope;
import org.openjdk.jmh.annotations.State;
import org.openjdk.jmh.annotations.Warmup;

@State(Scope.Thread)
@BenchmarkMode(Mode.Throughput)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@Warmup(iterations = 3)
@Measurement(iterations = 5)
@Fork(1)
public class CollectionSupportBenchmark {

    private final List<Integer> values = java.util.stream.IntStream.range(0, 100_000).boxed().toList();

    @Benchmark
    public boolean hasDuplicate() {
        return CollectionSupport.hasDuplicate(values, value -> value);
    }
}
```

## Rules

- 스니펫은 시작점이다. 프로젝트 error type, message, package로 반드시 조정한다.
- security helper는 리뷰 우선순위를 높인다.
- `perf_` unit test는 microbenchmark가 아니다. 성능 회귀 가능성이 큰 구조를 막는 guard다.
- 외부 라이브러리는 이미 dependency에 있거나 명확한 도입 사유가 있을 때만 사용한다.

## References

- [common-module-method-candidates.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/common-module-method-candidates.md>)
- [serialization-and-parsing-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/serialization-and-parsing-snippet.md>)
