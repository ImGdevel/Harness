# Project Artifact Conventions

실제 프로젝트 Git 저장소 안에서 남기는 계획 문서와 트러블슈팅 문서의 공통 규칙이다.

## Target Paths

- 하네스 레지스트리: `project/registry.yaml`
- 프로젝트 규칙 문서: `<project-root>/docs/`
- 프로젝트 계획 문서: `<project-root>/plan/`
- 프로젝트 트러블슈팅 문서: `<project-root>/troubleshooting/`
- 실제 Git 저장소: `<project-root>/`
- 프로젝트 `docs/` 내부 표준 구조는 `project-doc-structure.md`를 따른다.
- 공통 문서 배치와 `index.md` 유지 기준은 `documentation-governance.md`를 따른다.

## Resolution Rule

- 프로젝트 이름이 주어지면 먼저 하네스의 `project/registry.yaml`에서 `repo_path`를 찾는다.
- 하네스 내부 `project/`는 메타데이터만 저장한다.
- 실제 프로젝트 코드와 산출물은 registry가 가리키는 외부 저장소에만 둔다.

## Minimum Structure

```text
<project-root>/
  docs/
    api/
    architecture/
    convention/
    domain-tech-spec/
    erd/
    infrastructure/
    local-setup/
    references/
    security/
    stack-selection/
  plan/
  troubleshooting/
```

- `docs/`, `plan/`, `troubleshooting/`가 없으면 실제 프로젝트 저장소 안에 먼저 만든다.
- `plan/`과 `troubleshooting/`는 선택 디렉터리가 아니라 표준 디렉터리다.
- `docs/` 안의 세부 구조는 프로젝트 표준 문서 트리로 유지한다.

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

- Plan 모드나 구현 계획 요청이 있으면 결과를 대화로만 끝내지 말고 실제 프로젝트 저장소의 `plan/`에 저장한다.
- 계획은 실행 중 폐기하지 않고 기록으로 남긴다.
- 계획 템플릿은 `../templates/project-plan-template.md`를 사용한다.
- 계획 경로는 항상 registry가 가리키는 `<project-root>`를 기준으로 잡는다.
- 하네스 내부 `project/`에 계획 문서를 저장하지 않는다.
- 실제 프로젝트 저장소에 `plan/`이 없으면 먼저 생성한 뒤 저장한다.
- 유지 가치가 있는 프로젝트 계획을 문서로 남기지 않는 것은 규칙 위반이다.

## Troubleshooting Rule

- 반복될 가능성이 있거나 재발 방지 가치가 있는 문제는 `troubleshooting/`에 기록한다.
- 트러블슈팅 템플릿은 `../templates/troubleshooting-template.md`를 사용한다.
- 프로젝트 특화 이슈라도 프레임워크 공통 인사이트가 생기면 공통 또는 프레임워크 문서로 다시 추출한다.
- 하네스 내부 `project/`에는 트러블슈팅 문서를 저장하지 않는다.
- 실제 프로젝트 저장소에 `troubleshooting/`이 없으면 먼저 생성한 뒤 저장한다.
- 재발 방지 가치가 있는 디버깅 결과를 문서로 남기지 않는 것은 규칙 위반이다.
