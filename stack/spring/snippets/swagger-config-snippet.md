# Spring Swagger Config Snippet

## Use

- shared `OpenAPI`
- `GroupedOpenApi`
- `SecurityScheme`
- tag sort
- error response `OperationCustomizer`
- common operation metadata

## application.yml

```yaml
springdoc:
  api-docs:
    enabled: true
    path: /v3/api-docs
    version: openapi_3_1
  swagger-ui:
    enabled: true
    path: /swagger-ui.html
    display-request-duration: true
    operations-sorter: method
    tags-sorter: alpha
  packages-to-scan: com.example
```

## OpenAPI Bean

```java
@Configuration
@RequiredArgsConstructor
public class SwaggerConfig {

    private static final String BEARER_AUTH = "BearerAuth";

    private final ApplicationContext applicationContext;

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("T-Log API")
                        .description("""
                                T-Log 서비스 API 문서입니다.

                                - Public API: 프론트 공개 화면에서 사용
                                - Admin API: 운영자 화면에서 사용
                                - Error response: 모든 API는 공통 ErrorResponse shape를 사용
                                """)
                        .version("1.0.0"))
                .components(new Components()
                        .addSecuritySchemes(BEARER_AUTH, new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")));
    }
}
```

## GroupedOpenApi

```java
@Bean
public GroupedOpenApi publicApi() {
    return GroupedOpenApi.builder()
            .group("public-api")
            .displayName("Public API")
            .pathsToMatch("/api/v1/public/**")
            .packagesToScan("com.example.publicapi")
            .build();
}

@Bean
public GroupedOpenApi adminApi() {
    return GroupedOpenApi.builder()
            .group("admin-api")
            .displayName("Admin API")
            .pathsToMatch("/api/v1/admin/**")
            .packagesToScan("com.example.admin")
            .addOperationCustomizer((operation, handlerMethod) -> {
                operation.addSecurityItem(new SecurityRequirement().addList(BEARER_AUTH));
                return operation;
            })
            .build();
}
```

## Tag Sort Customizer

```java
@Bean
public GlobalOpenApiCustomizer sortTagsCustomizer() {
    return openApi -> {
        Map<String, Integer> tagOrderMap = new HashMap<>();

        applicationContext.getBeansWithAnnotation(RestController.class).values().stream()
                .map(AopUtils::getTargetClass)
                .flatMap(clazz -> Arrays.stream(clazz.getInterfaces()))
                .distinct()
                .filter(iface -> iface.isAnnotationPresent(SwaggerTagOrder.class)
                        && iface.isAnnotationPresent(Tag.class))
                .forEach(iface -> tagOrderMap.putIfAbsent(
                        iface.getAnnotation(Tag.class).name(),
                        iface.getAnnotation(SwaggerTagOrder.class).value()));

        if (openApi.getTags() != null) {
            openApi.getTags().sort(
                    Comparator.comparingInt(tag -> tagOrderMap.getOrDefault(tag.getName(), Integer.MAX_VALUE)));
        }
    };
}
```

## Common Header Customizer

```java
@Bean
public OperationCustomizer requestIdHeaderCustomizer() {
    return (operation, handlerMethod) -> {
        operation.addParametersItem(new Parameter()
                .in("header")
                .name("X-Request-ID")
                .required(false)
                .description("요청 추적용 ID. 클라이언트가 전달하지 않으면 서버에서 생성할 수 있다.")
                .schema(new StringSchema().format("uuid"))
                .example("01HR7R2Y8G6Y8K8Z7Z4Y7N0K4M"));
        return operation;
    };
}
```

## Rules

- OpenAPI metadata는 shared config 한 곳에 둔다.
- public/admin/internal group을 분리한다.
- security scheme은 한 번만 등록하고 operation 또는 group 단위에서 적용한다.
- tag 정렬은 공통 customizer로 처리한다.
- error response customizer는 `swagger-custom-error-response-snippet.md` 기준으로 둔다.
- Swagger UI와 api-docs path는 `application.yml`에서 관리한다.
- actuator, internal infrastructure endpoint는 기본적으로 제외한다.

## References

- [swagger-documentation-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/swagger-documentation-convention.md>)
- [swagger-custom-error-response-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/swagger-custom-error-response-snippet.md>)
