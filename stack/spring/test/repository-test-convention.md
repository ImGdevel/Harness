# Spring Repository Test Convention

## Purpose

Test JPA mapping, query, relation, and persistence behavior.

## Rules

- Prefer `@DataJpaTest`.
- Import only minimal JPA-related config needed by the project.
- Focus on query, pagination, join, relation, constraint, and modifying-query behavior.
- Keep service, controller, and security concerns out of repository tests.
- Add save/find smoke tests when entity fields or relations change.
- Keep one or two representative cases per query method.
- Verify actual persisted state by reloading from DB.
- Do not use fake or stub repository in repository tests.

## Checklist

- Does the test validate mapping or query behavior?
- Are service and controller concerns excluded?
- Is at least one boundary case covered?
- Is the result verified from DB state, not from stubbed behavior?

## References

- [integration-test-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/test/integration-test-convention.md>)
