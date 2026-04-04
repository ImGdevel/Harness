# Spring Swagger Docs Interface Snippet

## Use

- controller docs split
- `@Tag`
- `@Operation`
- Swagger-only endpoint docs

## Snippet

```java
@SwaggerTagOrder(10)
@Tag(name = "Auth", description = "Authentication API")
public interface AuthApiDocs {

    @Operation(summary = "Refresh access token")
    @ApiResponse(
            responseCode = "200",
            description = "Refresh success",
            content = @Content(schema = @Schema(implementation = RefreshTokenResponse.class))
    )
    @CustomErrorResponseDescription(
            value = AuthSwaggerErrorResponseDescription.class,
            group = "AUTH_TOKEN_REFRESH"
    )
    SuccessResponse<RefreshTokenResponse> refreshToken(
            @RefreshToken String refreshToken,
            HttpServletResponse response);

    @Operation(summary = "Logout")
    @ApiResponse(responseCode = "200", description = "Logout success")
    SuccessResponse<Void> logout(HttpServletRequest request, HttpServletResponse response);
}

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController implements AuthApiDocs {

    private final AuthService authService;

    @PostMapping("/refresh")
    @Override
    public SuccessResponse<RefreshTokenResponse> refreshToken(
            @RefreshToken String refreshToken,
            HttpServletResponse response) {
        return SuccessResponse.of(authService.refreshToken(refreshToken, response));
    }
}
```

## Rules

- Put doc annotations on the interface.
- Keep controller implementation free from annotation noise.
- Use Swagger-only method declarations when the route is infrastructure-driven.

## References

- [swagger-documentation-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/swagger-documentation-convention.md>)
