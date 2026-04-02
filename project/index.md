# Project Registry Index

이 디렉터리는 하네스가 참조하는 외부 프로젝트 레지스트리를 관리한다.

## Authoritative Source

- 단일 진실 원천은 `registry.yaml`이다.
- 이 문서는 사람이 빠르게 찾기 위한 요약 인덱스다.
- 실제 프로젝트 코드와 문서는 하네스 내부가 아니라 registry가 가리키는 외부 저장소에 있다.

## Rule

- 하네스 내부 `project/`에는 메타데이터만 둔다.
- 실제 프로젝트 저장소를 이 디렉터리 아래에 clone하거나 이동하지 않는다.
- `scripts/register-project.ps1`는 `registry.yaml`과 이 요약 인덱스를 같은 변경에서 함께 갱신해야 한다.
- registry와 요약 인덱스 정합성 검증은 `scripts/audit-project-registry.ps1`를 기준으로 한다.
- 실제 프로젝트 문서 골격 정렬은 `scripts/bootstrap-project-docs.ps1`를 기준으로 한다.
- 프로젝트 작업을 시작할 때는 먼저 `registry.yaml`에서 `repo_path`를 확인한다.
- 프로젝트 전용 문서는 실제 저장소의 `<project-root>/docs/`에 둔다.
- 계획 문서는 `<project-root>/plan/`에 둔다.
- 트러블슈팅 문서는 `<project-root>/troubleshooting/`에 둔다.
- 파일명과 버전 규칙은 `common/convention/project-artifact-conventions.md`를 따른다.
- `docs/` 표준 구조는 `common/convention/project-doc-structure.md`를 따른다.

## Registered Projects

| id | name | path | default branch | stacks | status |
| --- | --- | --- | --- | --- | --- |
| `miyou` | `MIYOU` | `C:\Users\imdls\workspace\MIYOU_ai-voice-chat` | `develop` | `spring`, `react` | `active` |
