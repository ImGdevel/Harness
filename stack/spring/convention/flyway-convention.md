# Spring Flyway Convention

## Purpose

Keep DB migration history linear, reviewable, and safe.

## Rules

- Keep SQL migrations in `db/migration`.
- Keep Java migrations in `db.migration`.
- Use timestamp-based versioned filenames.
- Use `lower_snake_case` description.
- Keep one intent per migration.
- Use `R__...` only for repeatable and idempotent logic.
- Do not modify an already deployed versioned migration.
- Split DDL and large DML when possible.
- Name constraints explicitly.
- Review lock range and downtime before large table changes.
- Mark non-transactional migrations explicitly.
- Split large backfill into separate migration or batch flow.
- Use Java migration only when SQL-only migration is not enough.
- Stage schema removal: add -> backfill -> code switch -> remove.
- Do not make manual production SQL the default migration path.
- Do not overuse `flyway repair` without root-cause analysis.

## Checklist

- Does the filename follow Flyway rules?
- Does the migration contain one intent only?
- Are destructive changes staged?
- Was lock or downtime risk reviewed?
- Was a real DB test run prepared or executed?

## References

- Project Flyway config
- Project release checklist
