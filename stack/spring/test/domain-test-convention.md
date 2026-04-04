# Spring Domain Test Convention

## Purpose

Test pure domain rule, invariant, and state transition only.

## Rules

- Keep domain tests free from Spring context.
- Test factory rule, default state, invariant, and state transition.
- Test `Policy` allow, deny, and expected exception code.
- Keep JPA, HTTP, security, and infrastructure out of domain tests.
- Use real factory methods for the target entity when possible.
- Use fixture only for supporting objects when it improves readability.
- Add explicit boundary-case tests for null, blank, limit, and count edges.
- Do not force tests for trivial setter-like methods with no rule or guard.

## Checklist

- Is the test purely domain-focused?
- Are success, failure, and boundary cases covered?
- Are JPA or service concerns excluded?
- Does the test name describe domain behavior?

## References

- [entity-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/entity/entity-design-convention.md>)
