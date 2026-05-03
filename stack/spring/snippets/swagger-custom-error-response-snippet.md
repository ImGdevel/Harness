# Spring Swagger Custom Error Response Snippet

## Use

- endpoint별 반복 error response 자동 문서화
- `ErrorCode` 기반 HTTP status, code, message, example 생성
- Swagger UI에서 프론트가 오류 상황과 처리 방식을 확인할 수 있게 구성

## Custom Annotation

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface CustomErrorResponseDescription {

    Class<? extends SwaggerErrorResponseDescription> value();

    String group();
}
```

## Error Description Contract

```java
public interface SwaggerErrorResponseDescription {

    Set<SwaggerErrorDescriptor> getErrorDescriptors(String group);

    default Set<SwaggerErrorDescriptor> withCommonErrors(Set<SwaggerErrorDescriptor> descriptors) {
        Set<SwaggerErrorDescriptor> merged = new LinkedHashSet<>(descriptors);
        merged.add(SwaggerErrorDescriptor.of(
                CommonErrorCode.INVALID_REQUEST,
                "요청 파라미터, path variable, request body validation이 실패했을 때 발생한다. 프론트는 입력값을 유지하고 field error를 표시한다."
        ));
        merged.add(SwaggerErrorDescriptor.of(
                CommonErrorCode.INTERNAL_ERROR,
                "예상하지 못한 서버 오류다. 프론트는 일시적 오류 메시지와 재시도 CTA를 표시한다."
        ));
        return merged;
    }
}
```

```java
public record SwaggerErrorDescriptor(
        ErrorCode errorCode,
        String situation
) {
    public static SwaggerErrorDescriptor of(ErrorCode errorCode, String situation) {
        return new SwaggerErrorDescriptor(errorCode, situation);
    }
}
```

## Domain Error Group

```java
public enum PublicPostSwaggerErrorResponseDescription implements SwaggerErrorResponseDescription {

    PUBLIC_POST_LIST(Set.of()),

    PUBLIC_POST_DETAIL(Set.of(
            SwaggerErrorDescriptor.of(
                    PublicApiErrorCode.PUBLIC_POST_NOT_FOUND,
                    "slug에 해당하는 공개 글이 없거나 hidden/blocked 상태일 때 발생한다. 프론트는 404 화면 또는 목록 복귀 CTA를 표시한다."
            )
    ));

    private final Set<SwaggerErrorDescriptor> descriptors;

    PublicPostSwaggerErrorResponseDescription(Set<SwaggerErrorDescriptor> descriptors) {
        this.descriptors = descriptors;
    }

    @Override
    public Set<SwaggerErrorDescriptor> getErrorDescriptors(String group) {
        PublicPostSwaggerErrorResponseDescription description = valueOf(group);
        return withCommonErrors(description.descriptors);
    }
}
```

## OperationCustomizer

```java
@Bean
public OperationCustomizer errorResponseCustomizer() {
    return (operation, handlerMethod) -> {
        CustomErrorResponseDescription annotation =
                handlerMethod.getMethodAnnotation(CustomErrorResponseDescription.class);

        if (annotation == null) {
            return operation;
        }

        SwaggerErrorResponseDescription description = resolveDescription(annotation.value());
        Set<SwaggerErrorDescriptor> descriptors = description.getErrorDescriptors(annotation.group());
        ApiResponses responses = operation.getResponses();

        descriptors.stream()
                .collect(Collectors.groupingBy(
                        descriptor -> String.valueOf(descriptor.errorCode().httpStatus().value()),
                        LinkedHashMap::new,
                        Collectors.toList()
                ))
                .forEach((status, groupedDescriptors) -> responses.addApiResponse(
                        status,
                        createApiResponse(groupedDescriptors)
                ));

        return operation;
    };
}
```

```java
private ApiResponse createApiResponse(List<SwaggerErrorDescriptor> descriptors) {
    Content content = new Content();
    MediaType mediaType = new MediaType()
            .schema(new Schema<ErrorResponse>().$ref("#/components/schemas/ErrorResponse"));

    descriptors.forEach(descriptor -> mediaType.addExamples(
            descriptor.errorCode().code(),
            new Example()
                    .summary(descriptor.errorCode().message())
                    .description(descriptor.situation())
                    .value(Map.of(
                            "code", descriptor.errorCode().code(),
                            "message", descriptor.errorCode().message()
                    ))
    ));

    content.addMediaType("application/json", mediaType);

    String description = descriptors.stream()
            .map(descriptor -> descriptor.errorCode().code() + ": " + descriptor.situation())
            .collect(Collectors.joining("\n"));

    return new ApiResponse()
            .description(description)
            .content(content);
}
```

## Validation Error Example

```java
private Example invalidRequestExample() {
    return new Example()
            .summary("요청 값 검증 실패")
            .description("size가 최대값 100을 초과했을 때 발생한다.")
            .value(Map.of(
                    "code", "INVALID_REQUEST",
                    "message", "요청 값이 올바르지 않습니다.",
                    "errors", List.of(Map.of(
                            "field", "size",
                            "reason", "size must be between 1 and 100"
                    ))
            ));
}
```

## Rules

- endpoint별 error group을 반드시 정의한다.
- error group에는 실제 발생 가능한 domain error만 넣는다.
- 공통 validation/internal error는 `withCommonErrors`에서 추가한다.
- 같은 HTTP status에 여러 error code가 있으면 examples로 나눈다.
- example name은 error code로 둔다.
- description에는 발생 상황과 프론트 처리 기준을 적는다.
- error response schema는 프로젝트 공통 `ErrorResponse`를 참조한다.
- 민감한 `rejectedValue`는 error example에 넣지 않는다.

## References

- [swagger-documentation-convention.md](../convention/swagger-documentation-convention.md)
- [common-api-dto-convention.md](../convention/common-api-dto-convention.md)
