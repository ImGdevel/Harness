# Spring Test Double Writing Guide

## Purpose

Choose the smallest test double that makes the test fast and stable.

## Rules

- Use `Dummy` only to fill unused parameters.
- Use `Stub` to return fixed answers.
- Use `Fake` for lightweight contract-preserving replacement.
- Use `Mock` only when interaction verification matters.
- Use `Spy` only when partial override is unavoidable.
- Do not overuse `verify`.
- Do not replace repository tests with fake repository behavior.
- Do not hide business logic inside `Fake`.
- Keep test doubles aligned with the real interface contract.
- Prefer no double at the domain layer when possible.
- Prefer `Mock` or `Stub` in service unit tests.
- Prefer real DB in repository tests.
- Prefer fake or stub for external network dependencies in integration tests.

## Checklist

- Is a test double actually needed?
- Is the chosen double type correct?
- Is interaction verification minimal?
- Does the fake/stub honor the real contract?
- Does the double improve speed or stability?

## References

- [service-test-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/test/service-test-convention.md>)
- [integration-test-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/test/integration-test-convention.md>)
