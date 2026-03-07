# GitHub Collaboration Conventions

이 문서는 이 저장소의 GitHub 이슈와 PR 작성 규칙, 템플릿 사용 규칙, 강제 수단을 정의한다.

## Goal

- 이슈와 PR 본문을 일관된 형태로 유지한다.
- 대화나 커밋 로그에만 맥락이 남지 않게 한다.
- GitHub UI와 자동 검증에서 같은 기준을 사용한다.

## Issue Rule

- 이슈는 `.github/ISSUE_TEMPLATE/` 아래 템플릿을 기본으로 사용한다.
- 빈 이슈는 허용하지 않는다. `config.yml`에서 `blank_issues_enabled: false`를 유지한다.
- 작업 이슈는 `work-item.yml`을 사용한다.
- 버그, 장애, 회귀 이슈는 `bug-report.yml`을 사용한다.
- 템플릿의 필수 항목은 비워 두지 않는다.

## Issue Template Selection

- 기능, 리팩터링, 문서, 설정, 운영 작업: `work-item.yml`
- 버그, 회귀, 장애, 예외 상황: `bug-report.yml`

## PR Rule

- PR 본문은 `.github/PULL_REQUEST_TEMPLATE.md`를 기본으로 사용한다.
- 다음 섹션은 항상 유지한다.
  - `## Summary`
  - `## Scope`
  - `## Validation`
  - `## Checklist`
- `Validation`은 비워 두지 않는다.
- 검증을 하지 않았다면 `not run`과 이유를 적는다.
- `Checklist`는 삭제하지 않는다. 필요 없는 항목은 체크 대신 이유를 `Notes`에 남긴다.

## Enforcement

- 이슈 강제는 GitHub Issue Form과 `blank_issues_enabled: false`로 처리한다.
- PR 강제는 `.github/workflows/validate-pr-template.yml`에서 처리한다.
- PR 본문에 필수 섹션이 없거나 `Summary`, `Scope`, `Validation`이 비어 있으면 검사에 실패한다.
- 문서 구조 강제는 `.github/workflows/validate-documentation-governance.yml`에서 처리한다.
- `common/`, `stack/`, `project/` 변경으로 문서 거버넌스 규칙이 깨지면 검사에 실패한다.
- 프로젝트 registry 정합성 강제는 `.github/workflows/validate-project-registry.yml`에서 처리한다.
- `project/registry.yaml`, `project/index.md`, registry 관련 스크립트 변경으로 요약 정합성이 깨지면 검사에 실패한다.

## Agent Rule

- 에이전트가 이슈를 작성할 때는 `common/templates/github-issue-work-item-template.md` 또는 `common/templates/github-issue-bug-template.md` 구조를 먼저 맞춘다.
- 에이전트가 PR 본문을 작성할 때는 `common/templates/github-pr-template.md` 구조를 먼저 맞춘다.
- 이슈나 PR을 자동 생성하는 스크립트가 생기면 `.github` 템플릿과 같은 필드를 유지해야 한다.

## Do Not

- 빈 이슈를 우회해서 생성하지 않는다.
- PR 본문에서 필수 섹션을 지우지 않는다.
- `Summary`에 커밋 목록만 붙여 넣고 설명을 생략하지 않는다.
- `Validation` 없이 PR을 올리고 검증 여부를 숨기지 않는다.
