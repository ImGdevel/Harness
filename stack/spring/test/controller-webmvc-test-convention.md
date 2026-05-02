# Spring Controller WebMvc Test Convention

## Purpose

Test HTTP contract with `@WebMvcTest` and `MockMvc`.

## Rules

- Use `@WebMvcTest` for controller slice tests.
- Use `MockMvc`.
- Mock or stub service and repository collaborators.
- Test request mapping, binding, validation, exception mapping, status, and JSON contract.
- Use `jsonPath()` for response contract checks.
- Keep service and domain business logic out of WebMvc tests.
- Do not use WebMvc tests for full filter-chain coverage.
- Add minimal security context only when the controller contract depends on it.

## Checklist

- Does the test verify HTTP contract only?
- Are validation and exception mappings explicit?
- Are response fields asserted with `jsonPath()`?
- Are service and repository details mocked, not re-tested?

## References

- [service-test-convention.md](service-test-convention.md)
- [integration-test-convention.md](integration-test-convention.md)
