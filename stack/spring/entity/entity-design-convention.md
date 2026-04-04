# Spring Entity Design Convention

## Purpose

Make JPA Entity express state, invariant, and transition explicitly.

## Rules

- Do not expose meaningless setter methods.
- Enter `Entity` through static factory or controlled builder.
- Change state only through named business methods.
- Validate on create and on state change.
- Use `snake_case` for table and column names.
- Use `EnumType.STRING` by default.
- Fix one ID strategy per project.
- Keep audit fields consistent across entities.
- Use verbs such as `create`, `changeXxx`, `activate`, `deactivate`, `withdraw`.
- Keep impossible state impossible with guard logic.
- Do not rely on another layer to repair invalid entity state.

## Checklist

- Is state mutation explicit?
- Is create flow controlled?
- Are guard checks local to the entity?
- Are enum and ID strategies aligned with project rules?
- Does the entity express domain behavior, not just table shape?

## References

- [erd-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/entity/erd-design-convention.md>)
- [table-definition-writing-guide.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/entity/table-definition-writing-guide.md>)
