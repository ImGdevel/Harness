# Project Artifact Conventions

실제 프로젝트 안에서 남기는 계획 문서와 트러블슈팅 문서의 공통 규칙이다.

## Target Paths

- 프로젝트 규칙 문서: `project/<project-name>/docs/`
- 프로젝트 계획 문서: `project/<project-name>/plan/`
- 프로젝트 트러블슈팅 문서: `project/<project-name>/troubleshooting/`
- 실제 Git 저장소: `project/<project-name>/<repo-name>/`

## Filename Convention

기본 형식:

```text
YYYY-MM-DD_HHMM_<slug>.md
```

- 날짜와 시간은 로컬 작업 시간을 사용한다.
- `<slug>`는 소문자와 하이픈 중심으로 짧게 작성한다.
- 예시: `2026-04-21_1430-auth-flow-cleanup.md`

## Versioning Rule

같은 주제의 계획이 수정되거나, 같은 문제를 이어서 분석하는 후속 문서라면 새 파일을 만들지 말고 버전을 올린다.

```text
YYYY-MM-DD_HHMM_<slug>_v2.md
YYYY-MM-DD_HHMM_<slug>_v3.md
```

- 새 파일은 완전히 다른 작업 주제일 때만 만든다.
- 관련된 후속 변경이면 기존 파일명을 유지하고 버전만 올린다.

## Plan Rule

- Plan 모드나 구현 계획 요청이 있으면 결과를 대화로만 끝내지 말고 프로젝트 `plan/`에 저장한다.
- 계획은 실행 중 폐기하지 않고 기록으로 남긴다.
- 계획 템플릿은 `../templates/project-plan-template.md`를 사용한다.
- 프로젝트는 프레임워크와 무관하게 루트 `project/` 아래에서 관리한다.
- 계획 문서와 실제 저장소는 같은 컨테이너 안에서 분리해 관리한다.

## Troubleshooting Rule

- 반복될 가능성이 있거나 재발 방지 가치가 있는 문제는 `troubleshooting/`에 기록한다.
- 트러블슈팅 템플릿은 `../templates/troubleshooting-template.md`를 사용한다.
- 프로젝트 특화 이슈라도 프레임워크 공통 인사이트가 생기면 공통 또는 프레임워크 문서로 다시 추출한다.
- 루트 워크스페이스 Git은 `project/*/...` 아래 내용을 추적하지 않는다.
