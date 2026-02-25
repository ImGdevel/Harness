---
name: workflow-orchestration
description: Select and run the workspace workflow hierarchy using standard step, job, and pipeline units. Use when the user asks for a workflow or pipeline, wants automatic multi-step execution, asks for full-test or PR delivery, or clearly implies an end-to-end flow without listing every atomic step.
---

# Workflow Orchestration

Read this file once before choosing a workflow.

## Goal

Choose the smallest registered workflow unit that fully satisfies the request, then run it without requiring the user to spell every step out.

## Read Order

Read these files first:

1. `common/index.md`
2. `common/spec/workflow-model.md`
3. `common/spec/workflow-catalog.md`
4. Supporting skill docs only when the selected workflow needs them

## Workflow Units

- `step`: atomic execution unit
- `job`: reusable mid-level workflow made of steps
- `pipeline`: integrated workflow made of jobs

## Selection Rule

- If one command or one atomic action is enough, use a `step`.
- If the request implies several ordered steps but one narrow outcome, use a `job`.
- If the request implies multiple jobs across a delivery phase, use a `pipeline`.

Do not force a pipeline when a job is enough.

## Automatic Trigger Map

Use these mappings by default:

- `전체 테스트`, `전체 검증`, `머지 전 검증` -> `full-test`
- `문서 인덱스 갱신`, `index 맞춰`, `nearest index 업데이트`, `문서 구조 정리해` -> `index-sync`
- `커밋하고 푸시`, `PR 올려`, `PR 준비` -> `pr-delivery`
- `계획도 남겨`, `작업 시작 전에 계획 정리` -> `plan-sync`
- `문제 정리해`, `트러블슈팅 문서 남겨` -> `troubleshooting-record`
- `기능 작업해서 PR까지` -> `implementation-delivery`
- `요구사항부터 끝까지`, `설계부터 구현, 테스트, PR, 피드백까지`, `프롬프트 다시 안 쓰고 끝까지` -> `delivery-pipeline`
- `버그 원인 분석해서 고치고 올려` -> `incident-response`
- `프로젝트 등록해`, `프로젝트 레지스트리에 추가해`, `프로젝트 기본 구조부터 만들어` -> `project-bootstrap`

## Supporting Skill Map

When the selected workflow needs sub-workflows, use these skills:

- context alignment: `workspace-gatekeeper`
- plan persistence: `feature-planning`
- project troubleshooting docs: `troubleshooting-writing`
- Git execution: `git-workflow`
- PR and issue body drafting: `github-collaboration`
- spec or rule docs: `spec-writing`, `convention-writing`

## Execution Rules

- Start from repository and scope validation.
- Treat `common/spec/workflow-catalog.md` as the single source of truth for registered `job` and `pipeline` membership and order.
- Run prerequisite steps automatically when the workflow definition requires them.
- Stop immediately on failed gates, missing prerequisites, or ambiguous repository boundaries.
- If a workflow cannot finish because one required command is unknown, report the missing command instead of inventing it.

## Output Expectations

When using this skill, always report:

- selected workflow unit type: `step`, `job`, or `pipeline`
- selected workflow name
- executed steps or jobs
- skipped items and reason
- final status: success, blocked, or failed
