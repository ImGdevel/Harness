# Spring Integration Test Convention

## Purpose

Test end-to-end application flow with real Spring wiring.

## Rules

- Use `@SpringBootTest` for integration tests.
- Add `@AutoConfigureMockMvc` for HTTP flow.
- Use `webEnvironment = NONE` or equivalent for non-HTTP flow when needed.
- Test representative success and failure flows only.
- Verify real DB or system state change.
- Keep external integrations behind testable fake or stub adapters.
- Do not move every branch and edge case into integration tests.
- Let WebMvc tests own detailed HTTP contract checks.
- Let repository tests own JPA-specific checks.

## Checklist

- Does the test prove a real end-to-end flow?
- Is DB or system state verified?
- Are external integrations controlled?
- Are low-level edge cases delegated to lower test layers?

## References

- [controller-webmvc-test-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/test/controller-webmvc-test-convention.md>)
- [repository-test-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/test/repository-test-convention.md>)
