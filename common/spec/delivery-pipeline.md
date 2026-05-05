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
- Treat the work as unfinished until a PR URL exists and the first PR automation/AI review check is complete, unless the user explicitly requests no PR.
- If PR creation is blocked, report the blocker instead of marking the work complete.
- After opening a PR or pushing new commits to an existing PR, wait 10 to 20 minutes for CI and AI review automation.
- Inspect Gemini Code Assist or equivalent AI review comments after the wait.
- Accept comments that match requirements, conventions, safety, or product quality; then fix, revalidate, document, commit, and push.
- Reject comments only with a concrete reason, and leave a reply on the review thread when permissions allow it.
- Accepted review comments must be resolved or otherwise closed on the PR thread before reporting completion.
- After fixes are pushed, re-query PR review threads and confirm there are zero unresolved accepted comments.
- If the GitHub connector blocks resolving or replying, try an authenticated non-interactive path such as `gh` or GitHub API with the local Git Credential Manager token before declaring a blocker.
- Do not operate the user's GitHub Web UI to resolve review threads unless the user explicitly asks for browser-based interaction.

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
- PR automation and Gemini Code Assist first-pass review were checked after the required wait window.
- Accepted PR review feedback was addressed or explicitly recorded as pending/blocking.
- Accepted PR review threads were resolved or confirmed blocked after authenticated CLI/API resolve/reply attempts.
- Final PR review-thread re-query shows no unresolved accepted comments, unless a documented permission blocker remains.
- Requested non-PR delivery artifact was completed only when the user explicitly scoped the work away from PR delivery.

## References

- [workflow-catalog.md](</C:/Users/imdls/workspace/Project Workspace/common/spec/workflow-catalog.md>)
- [workflow-model.md](</C:/Users/imdls/workspace/Project Workspace/common/spec/workflow-model.md>)
