# Spring Test Fixture Convention

## Purpose

Keep test setup short without hiding test intent.

## Rules

- Put shared fixture in `src/testFixtures/java` or the project test-fixture source set.
- Keep fixture classes stateless and utility-style.
- Name fixture class as `<Target>Fixture`.
- Use method names such as `create`, `createWithId`, `createRequest`, `createRequestWithoutXxx`.
- Prefer real factory creation for the target entity in domain tests.
- Use fixture mainly for supporting objects and repeated setup.
- Keep assertions explicit in the test body.
- Do not hide business logic inside fixture.
- Do not add excessive overloads that hide scenario meaning.

## Checklist

- Does fixture reduce repetition?
- Does fixture keep valid default state?
- Is business logic kept out of fixture?
- Is the test body still readable?

## References

- [test-double-writing-guide.md](test-double-writing-guide.md)
