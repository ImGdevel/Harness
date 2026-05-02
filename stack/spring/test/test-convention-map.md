# Spring Test Convention Map

## Purpose

Resolve the correct Spring test document fast.

## Rules

- Use [domain-test-convention.md](domain-test-convention.md) for `Entity` and `Policy` rule tests.
- Use [repository-test-convention.md](repository-test-convention.md) for JPA mapping and query tests.
- Use [service-test-convention.md](service-test-convention.md) for use-case orchestration tests.
- Use [controller-webmvc-test-convention.md](controller-webmvc-test-convention.md) for HTTP contract tests.
- Use [integration-test-convention.md](integration-test-convention.md) for end-to-end application flow tests.
- Use [test-fixture-convention.md](test-fixture-convention.md) for fixture rules.
- Use [test-double-writing-guide.md](test-double-writing-guide.md) for double selection.
- Use [validator-vs-policy-pattern.md](../convention/validator-vs-policy-pattern.md) when domain rule and input validation boundaries are unclear.

## Checklist

- Did you pick the lowest-cost test layer?
- Did you avoid re-testing the same concern in a higher layer?
