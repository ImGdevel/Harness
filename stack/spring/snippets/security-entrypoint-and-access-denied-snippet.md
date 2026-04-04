# Spring Security EntryPoint and AccessDenied Snippet

## Use

- `AuthenticationEntryPoint`
- `AccessDeniedHandler`
- JSON security error response

## Snippet

```java
@Component
public class JsonAuthenticationEntryPoint implements AuthenticationEntryPoint {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void commence(
            HttpServletRequest request,
            HttpServletResponse response,
            AuthenticationException ex
    ) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        objectMapper.writeValue(response.getWriter(), Map.of(
                "code", "UNAUTHORIZED",
                "message", "authentication required"
        ));
    }
}
```

```java
@Component
public class JsonAccessDeniedHandler implements AccessDeniedHandler {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void handle(
            HttpServletRequest request,
            HttpServletResponse response,
            AccessDeniedException ex
    ) throws IOException {
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        objectMapper.writeValue(response.getWriter(), Map.of(
                "code", "FORBIDDEN",
                "message", "access denied"
        ));
    }
}
```

## Rules

- Return JSON, not HTML.
- Keep response shape aligned with normal API error contract.
- Wire both handlers explicitly in `SecurityConfig`.

## References

- [security-exception-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/security-exception-convention.md>)
