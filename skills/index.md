# Skills Index

이 디렉터리는 워크스페이스 전반에서 재사용하는 스킬 문서를 모아두는 공간이다.

## Usage

- 공통 작업 흐름
- 문서 작성 규칙
- 프레임워크별 반복 작업 패턴

## Registered Skills

- `workspace-gatekeeper/`
  작업 시작 전에 공통/프레임워크/프로젝트 범위와 실제 Git 저장소 범위를 먼저 정렬하는 기본 스킬이다.
  어떤 문서를 먼저 읽을지, 작업이 루트 워크스페이스인지 실제 프로젝트 저장소인지 먼저 결정할 때 사용한다.

- `feature-planning/`
  기능 계획, 단계 분해, 로드맵, 구현 전 플랜 문서 작성 시 먼저 읽는 기본 스킬이다.
  핵심 규칙은 `SKILL.md`에 있고, 실제 플랜 문서는 `common/templates/project-plan-template.md`를 출발점으로 사용한다.

- `spec-writing/`
  공통, 프레임워크, 프로젝트 범위의 스펙 문서를 작성하거나 갱신할 때 사용하는 기본 스킬이다.
  구조화된 기술 문서와 워크플로우 문서를 남기고, 관련 `index.md` 갱신까지 같이 처리한다.

- `convention-writing/`
  공통, 프레임워크, 프로젝트 범위의 규칙 문서를 작성하거나 갱신할 때 사용하는 기본 스킬이다.
  강제 규칙, 권장 규칙, 금지 패턴, 예외 처리 순서를 문서화할 때 사용한다.

- `troubleshooting-writing/`
  프로젝트 이슈 분석, 원인 정리, 해결 과정 기록, 재발 방지 문서를 남길 때 먼저 읽는 기본 스킬이다.
  실제 문서는 `common/templates/troubleshooting-template.md`를 출발점으로 사용한다.

- `git-workflow/`
  브랜치 생성, 하네스 저장소 또는 실제 프로젝트 저장소의 Git 전략 판별, 커밋 범위 분리, 커밋 메시지 규칙 적용 시 먼저 읽는 기본 스킬이다.
  상세 기준은 `common/convention/git-commit-conventions.md`, `common/convention/workspace-git-governance.md`, `common/convention/git-branch-gitflow.md`를 따른다.

- `github-collaboration/`
  GitHub 이슈와 PR 본문을 템플릿 기준으로 작성하거나 수정할 때 사용하는 기본 스킬이다.
  실제 템플릿 구조와 강제 규칙은 `common/convention/github-collaboration-conventions.md`와 `common/templates/`를 따른다.

- `workflow-orchestration/`
  `step`, `job`, `pipeline` 계층으로 작업 흐름을 선택하고 자동 실행할 때 사용하는 기본 스킬이다.
  `full-test`, `pr-delivery`, `implementation-delivery` 같은 등록된 워크플로우를 기준으로 동작한다.

- `delivery-pipeline/`
  요구사항 상세화부터 설계, 구현, 테스트, 문서화, PR, 피드백 반영까지 장시간 연속 실행하는 대단위 delivery pipeline 스킬이다.
  사용자가 중간 프롬프트를 다시 쓰지 않아도 완료 또는 실제 blocker까지 계속 전진하는 것을 기본으로 한다.

## Registration Rule

- 새 스킬 문서를 추가하면 이 인덱스에 목적과 경로를 기록한다.
- 프로젝트 전용 스킬은 가능하면 해당 실제 프로젝트의 `docs/` 아래에 둔다.
