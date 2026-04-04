# Spring Service Test Convention

## Purpose

Test use-case orchestration and service branching without Spring context.

## Rules

- Prefer plain JUnit plus Mockito.
- Mock repository, external client, and complex collaborator by default.
- Use real lightweight policy objects only when that improves clarity.
- Test success flow, failure flow, branch, side effect, and composition logic.
- Keep JPA mapping, HTTP contract, filter, and AOP detail out of service tests.
- Use fixture for request and input setup when it shortens `Given`.
- Assert response and side effect explicitly.
- Do not force tests for trivial pass-through service methods.

## Checklist

- Is the test focused on orchestration and branching?
- Are JPA and HTTP concerns excluded?
- Do mocks support intent instead of hiding it?
- Are both success and failure paths covered?

## References

- [domain-test-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/test/domain-test-convention.md>)
- [test-double-writing-guide.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/test/test-double-writing-guide.md>)
