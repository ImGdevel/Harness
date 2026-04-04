# Spring Swagger Documentation Convention

## Purpose

Fix one `springdoc-openapi` documentation pattern for Spring HTTP APIs.

## Rules

- Use one shared `SwaggerConfig` per application.
- Keep `OpenAPI`, `Info`, `SecurityScheme`, tag sort, and `OperationCustomizer` in the shared config only.
- Use `*Docs` or `*ApiDocs` interface for controller documentation.
- Let controller classes `implements` the docs interface.
- Keep Swagger annotations on the docs interface when the docs interface pattern is used.
- Put `@Tag` on the docs interface. Do not scatter the same tag across many controllers.
- If tag order matters, use one shared ordering rule such as `@SwaggerTagOrder` plus global tag sort.
- Put endpoint `@Operation` and primary success `@ApiResponse` on the docs interface.
- Use `@Schema` on request or response DTO fields that need explicit docs.
- Use one shared custom error annotation pattern for repeated error responses.
- Map repeated error responses from `ErrorCode` metadata in `OperationCustomizer`. Do not hand-write the same `4xx` or `5xx` block on many endpoints.
- Keep one fixed error response schema for Swagger examples.
- Add security scheme once in shared config.
- Add operation security from a shared rule or annotation. Do not duplicate bearer config on every endpoint.
- Keep Swagger docs separate from business logic.
- Keep Swagger-only placeholders explicit when an endpoint is handled by filter or infrastructure code.

## Checklist

- Is there exactly one shared `SwaggerConfig`?
- Does the controller implement a docs interface?
- Are `@Tag`, `@Operation`, and success response docs kept in the docs interface?
- Are repeated error responses generated from one custom annotation path?
- Is the security scheme defined once?
- Does Swagger code stay out of service or domain logic?

## References

- [error-handling-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/error-handling-convention.md>)
- [security-exception-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/security-exception-convention.md>)
- [swagger-config-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/swagger-config-snippet.md>)
- [swagger-docs-interface-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/swagger-docs-interface-snippet.md>)
- [swagger-custom-error-response-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/swagger-custom-error-response-snippet.md>)
- Source: [Tasteam SwaggerConfig.java](</C:/Users/imdls/workspace/Tasteam/3-team-Tasteam-be/module-internal/web/src/main/java/com/tasteam/global/swagger/config/SwaggerConfig.java>)
- Source: [Tasteam AuthApiDocs.java](</C:/Users/imdls/workspace/Tasteam/3-team-Tasteam-be/app-api/src/main/java/com/tasteam/domain/auth/controller/docs/AuthApiDocs.java>)
- Source: [Devon Swagger custom exception note](</C:/Users/imdls/workspace/3-devon-woo-community-BE/docs/api/SWAGGER_CUSTOM_EXCEPTION.md>)
