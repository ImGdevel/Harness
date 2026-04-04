# Spring Table Definition Writing Guide

## Purpose

Keep table definition docs readable, comparable, and reviewable.

## Rules

- Match the real DB table name exactly.
- Use `snake_case`.
- Write one-line `Description`.
- State `Responsibility` and non-responsibility explicitly.
- State `Lifecycle`.
- State `Deletion Policy`.
- State main query patterns.
- State non-trivial `Constraints`.
- State required `Indexes`.
- Keep `Design Rationale` only as short bullets.
- Keep the column table explicit: `Column`, `Type`, `Nullable`, `Key`, `Unique`, `Default`, `Note`.
- Explain business meaning, not ORM noise.
- Do not turn the table definition into a long tutorial.

## Checklist

- Can a new reader understand table purpose quickly?
- Is lifecycle explicit?
- Are query patterns tied to indexes?
- Are column meanings explicit?
- Are future-change notes short and useful?

## References

- [erd-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/entity/erd-design-convention.md>)
