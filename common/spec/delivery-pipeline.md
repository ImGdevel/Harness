# Delivery Pipeline

## Purpose

Run one end-to-end delivery flow from requirement to handoff.

## Rules

- Treat `delivery-pipeline` as a `pipeline`.
- Use [workflow-catalog.md](</C:/Users/imdls/workspace/Project Workspace/common/spec/workflow-catalog.md>) as the execution source of truth.
- Do not redefine runtime order in this file.
- Allow long-running execution.
- Auto-advance to the next `job` unless a stop condition is hit.
- Keep requirement, design, implementation, and docs in sync.
- Re-enter the loop after review failure, validation failure, or feedback.
- Run troubleshooting as a sidecar flow, then return to the main flow.
- Commit in small intent-based slices when useful.
- Use `pr-delivery` for commit, push, and PR creation.
- Treat the work as unfinished until a PR URL exists, unless the user explicitly requests no PR.
- If PR creation is blocked, report the blocker instead of marking the work complete.

## Stop Conditions

- Repository context is unclear.
- Project identity or requirement is unclear.
- External approval is required.
- A destructive action is required.
- Validation failed and there is no safe basis for the next step.
- Requirement and design conflict and need user direction.

## Outputs

- `<project-root>/docs/...`
- `<project-root>/docs/plan/`
- `<project-root>/docs/troubleshooting/`
- commits, pushes, PR URL, or explicitly requested non-PR handoff artifact

## Exit Criteria

- Requirement, design, implementation, and docs are aligned.
- Required tests and validation are complete.
- Reusable troubleshooting was documented.
- Remaining work was captured.
- PR URL was created for implementation work.
- Requested non-PR delivery artifact was completed only when the user explicitly scoped the work away from PR delivery.

## References

- [workflow-catalog.md](</C:/Users/imdls/workspace/Project Workspace/common/spec/workflow-catalog.md>)
- [workflow-model.md](</C:/Users/imdls/workspace/Project Workspace/common/spec/workflow-model.md>)
