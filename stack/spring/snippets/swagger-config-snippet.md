# Spring Swagger Config Snippet

## Use

- shared `OpenAPI`
- `SecurityScheme`
- tag sort
- `OperationCustomizer`

## Snippet

```java
@Configuration
@RequiredArgsConstructor
public class SwaggerConfig {

    private static final String BEARER_AUTH = "BearerAuth";

    private final ApplicationContext applicationContext;

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info().title("Example API").version("1.0.0"))
                .components(new Components()
                        .addSecuritySchemes(BEARER_AUTH, new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")))
                .addSecurityItem(new SecurityRequirement().addList(BEARER_AUTH));
    }

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

    @Bean
    public OperationCustomizer operationCustomizer() {
        return (operation, handlerMethod) -> {
            CustomErrorResponseDescription annotation =
                    handlerMethod.getMethodAnnotation(CustomErrorResponseDescription.class);

            if (annotation != null) {
                SwaggerErrorResponseDescription group = resolveGroup(annotation);
                addErrorResponses(operation, group);
            }

            return operation;
        };
    }
}
```

## Rules

- Keep shared Swagger wiring in one config.
- Register security once.
- Register tag sort once.
- Register error response customization once.

## References

- [swagger-documentation-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/swagger-documentation-convention.md>)
