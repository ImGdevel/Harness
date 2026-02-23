---
name: delivery-pipeline
description: Run the large-scale end-to-end delivery pipeline for a project. Use when the user wants work to continue from requirement shaping through design, implementation, testing, documentation, PR, and feedback handling without re-prompting each sub-step.
---

# Delivery Pipeline

Read this file once before starting the pipeline.

## Goal

Drive a project task from requirement to delivery completion through one continuous pipeline, not a sequence of isolated chat turns.

## Read Order

Read these files first:

1. `common/index.md`
2. `common/spec/workflow-model.md`
3. `common/spec/workflow-catalog.md`
4. `common/spec/delivery-pipeline.md`
5. Supporting skill docs only when the selected job needs them

## Standard Unit

This skill always selects the `delivery-pipeline` pipeline unless the request is clearly smaller.

Use a smaller `job` only when:

- the requirement is already fixed and designed
- the user only wants one narrow stage such as testing or PR delivery
- the work is explicitly limited to one sub-problem

## Execution Policy

- Once started, continue through the next registered `job` automatically.
- Do not wait for a new prompt between jobs.
- Do not stop at “analysis complete” if the next executable job is clear.
- Keep moving until the pipeline is completed or a real blocker is hit.

## Default Flow

1. `requirement-shaping`
2. `context-discovery`
3. `plan-sync`
4. `design-sync`
5. `work-bootstrap`
6. `implementation-cycle`
7. `test-authoring`
8. `quality-cycle`
9. `requirements-implementation-sync`
10. `full-test`
11. `troubleshooting-record` if needed
12. `implementation-doc-sync`
13. `backlog-capture`
14. `pr-delivery`
15. `feedback-response`

## Loop Policy

Repeat the relevant stage when one of these happens:

- design review fails -> return to `design-sync`
- implementation reveals a design gap -> return to `design-sync` or `requirement-shaping`
- tests fail -> return to `implementation-cycle` or `quality-cycle`
- troubleshooting occurs -> run troubleshooting sidecar, then resume
- PR feedback arrives -> run `feedback-response`, then re-run affected validation and doc sync

## Single Source Of Truth Rule

- Requirement notes, design docs, and implementation docs must converge before delivery close.
- If code changes invalidate the design doc, update the document in the same pipeline.
- If the design changes, update implementation and validation expectations in the same pipeline.
- Do not leave known design/code drift unresolved at pipeline exit.

## Supporting Skills

Use these skills as sub-workflows:

- `workspace-gatekeeper`
- `feature-planning`
- `spec-writing`
- `convention-writing`
- `troubleshooting-writing`
- `git-workflow`
- `github-collaboration`
- `workflow-orchestration`

## Stop Rules

Stop only when:

- repository or project scope is ambiguous
- external approval is required and cannot be inferred
- destructive action requires explicit confirmation
- validation failure blocks further progress
- the user explicitly pauses or redirects the work

## Output Expectations

When using this skill, always report:

- current pipeline stage
- completed jobs
- active loop or re-entry point when repeating
- artifacts produced
- final state: completed or blocked
