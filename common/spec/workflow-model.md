# Workflow Model

## Purpose

Use one runtime hierarchy for work selection.

## Terms

- `step`: smallest executable unit
- `job`: ordered group of `step`
- `pipeline`: ordered group of `job`

## Rules

- Use `step` for atomic requests.
- Use `job` when one outcome needs multiple `step`.
- Use `pipeline` when one outcome needs multiple `job`.
- Auto-select the smallest unit that can complete the user intent.
- Stop when repository context is unclear.
- Stop when a destructive action is required.
- Stop when a required precondition is missing.
- Stop when validation fails and the next step has no safe basis.
- Every `job` and `pipeline` must define `Trigger`, `Preconditions`, `Steps`, `Stop Conditions`, `Output`.
- Every looping `pipeline` must define loop and re-entry behavior.
- Any workflow that creates or moves docs must include index sync responsibility.

## Examples

- `full-test` -> `job`
- `pr-delivery` -> `job`
- `delivery-pipeline` -> `pipeline`

## Checklist

- Is the selected unit the smallest valid unit?
- Are preconditions explicit?
- Are stop conditions explicit?
- Does the workflow own index sync when docs change?

## References

- [workflow-catalog.md](</C:/Users/imdls/workspace/Project Workspace/common/spec/workflow-catalog.md>)
- [delivery-pipeline.md](</C:/Users/imdls/workspace/Project Workspace/common/spec/delivery-pipeline.md>)
