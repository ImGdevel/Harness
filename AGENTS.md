# AGENTS Guide

이 워크스페이스는 Codex와 Claude가 함께 사용하는 하네스 저장소다.
작업 전에는 아래 순서로 문서 컨텍스트를 확인한다.

## Lookup Order

1. `common/index.md`
2. `stack/index.md`
3. 대상 프레임워크의 `index.md`
4. 실제 프로젝트가 있다면 `project/index.md`와 `project/registry.yaml`
5. registry에서 경로를 찾았으면 실제 프로젝트 문서 원천
   - repo 문서 원천이면 실제 프로젝트의 `docs/index.md`
   - Wiki 문서 원천이면 Wiki의 `Home.md`와 문서 정책

## Core Rules

- 변경은 작고 명확하게 유지한다.
- 문서 폴더에는 항상 `index.md`를 유지한다.
- 새로운 문서를 추가하면 해당 `index.md`도 함께 갱신한다.
- 사용자가 요청하지 않은 실제 프로젝트 코드는 루트 워크스페이스 Git에 추가하지 않는다.
- 하네스 내부 `project/`를 실제 프로젝트 clone 위치로 사용하지 않는다.
- 계획이나 트러블슈팅이 필요하면 대화에서 끝내지 말고 문서로 남긴다.
- 이슈와 PR을 다룰 때는 `.github` 템플릿과 공통 템플릿 구조를 따른다.
- 요청이 등록된 `job` 또는 `pipeline`에 명확히 대응되면 세부 step을 다시 물어보지 말고 자동으로 수행한다.
- `delivery-pipeline`에 해당하는 요청이면 요구사항, 설계, 구현, 검증, 문서화, PR, 피드백까지 연속적으로 전진한다.
- 하네스 저장소 자체의 Git 작업은 `common/convention/workspace-git-governance.md`를 기준으로 `main`에서 분기한다.

## Documentation Rule

라이브러리, 프레임워크, SDK, API, CLI, 클라우드 서비스 관련 질문은 Context7 기준으로 답한다.

1. `resolve-library-id`로 정확한 라이브러리를 식별한다.
2. `query-docs`로 사용자의 전체 질문을 조회한다.
3. 조회된 문서를 기준으로 답한다.

다음에는 Context7을 쓰지 않는다.

- 일반 리팩터링
- 비즈니스 로직 디버깅
- 일반 프로그래밍 개념 설명

## Project Rules

- `project/registry.yaml`는 프로젝트 이름과 실제 저장소 경로를 연결하는 단일 진실 원천이다.
- `project/index.md`는 사람이 보는 레지스트리 요약이다.
- 실제 프로젝트 Git 저장소는 하네스 밖 sibling 경로에 둔다.
- 사용자가 프로젝트 이름을 말하면 먼저 registry에서 `repo_path`를 찾는다.
- 프로젝트 전용 규칙과 스펙은 실제 저장소의 `<project-root>/docs/`에 둔다.
- 프로젝트 `docs/`는 최소한 `api/`, `architecture/`, `convention/`, `domain-tech-spec/`, `erd/`, `infrastructure/`, `local-setup/`, `references/`, `security/`, `stack-selection/` 구조를 유지한다.
- 실제 프로젝트 계획 문서는 기본적으로 `<project-root>/docs/plan/`에 둔다.
- 실제 프로젝트 트러블슈팅 문서는 기본적으로 `<project-root>/docs/troubleshooting/`에 둔다.
- 실제 프로젝트의 정확한 문서 경로는 registry의 `docs_path`, `plan_path`, `troubleshooting_path`를 따른다.
- registry 또는 프로젝트 정책이 `docs_source: wiki`를 명시하면 Wiki가 실제 프로젝트 `docs/` 역할을 대신한다.
- `docs/plan/`과 `docs/troubleshooting/`는 실제 프로젝트 저장소 안의 필수 디렉터리로 간주한다.
- 프로젝트 문서 경로가 없다면 실제 프로젝트 저장소 안에 만든다.
- 파일명은 `YYYY-MM-DD_HHMM_<slug>.md` 형식을 기본으로 한다.
- 기존 계획이나 같은 이슈의 후속 문서면 `_v2`, `_v3`처럼 버전을 올린다.
- 공통 Git 규칙 문서는 기본적으로 실제 프로젝트 저장소 Git에 적용된다.
- 실제 프로젝트 구현, 커밋, 푸시, PR 전에는 `scripts/validate-project-git-context.ps1`로 원격 기준 브랜치와 문서 원천을 검증한다.
- 하네스 저장소 자체는 `workspace-git-governance.md`를 따른다.
- 하네스 저장소 Git은 별도 맥락이며 자동 기본 대상이 아니다.

## Workspace Conventions

- `skills/`에는 재사용 가능한 작업 스킬 문서를 둔다.
- `common/`에는 공통 컨벤션, 공통 스펙, 공통 템플릿을 둔다.
- 각 프레임워크 루트에는 프레임워크 전용 컨벤션과 스펙을 둔다.
- 모든 프레임워크 스택은 `stack/` 아래에서 함께 관리한다.
- 짧은 재사용 코드 조각은 각 프레임워크 `snippets/`에 둔다.
- `scripts/`에는 반복 실행할 자동화 스크립트를 둔다.
- GitHub 이슈/PR 강제 템플릿은 `.github/`에서 관리한다.
- 공통 워크플로우 모델은 `common/spec/workflow-model.md`와 `common/spec/workflow-catalog.md`를 기준으로 한다.
