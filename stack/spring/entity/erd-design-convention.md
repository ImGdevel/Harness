# Spring ERD Design Convention

## Purpose

Keep ERD and physical schema consistent, explicit, and domain-driven.

## Rules

- Give each table one responsibility.
- Keep relationships meaningful.
- Partition ERD by domain boundary when possible.
- Use `snake_case` for table and column names.
- Fix singular or plural table naming per project. Do not mix.
- Avoid meaningless prefixes and suffixes.
- Use `id` for PK.
- Use `{target}_id` for FK.
- Use `{action}_at` for time columns.
- Use `status` or `{concept}_type` consistently.
- Prefer one PK strategy per project.
- Review composite PK or composite `UNIQUE` first for pure relation tables.
- Match FK column type with target PK type.
- Fix one referential-integrity policy per project and document it.
- Avoid names that collide with framework core terms.

## Checklist

- Does each table have one responsibility?
- Are relation names meaningful?
- Are naming rules consistent?
- Is PK/FK strategy consistent?
- Is referential-integrity policy documented?

## References

- [entity-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/entity/entity-design-convention.md>)
