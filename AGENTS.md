# AGENTS Guide

이 워크스페이스는 Codex와 Claude가 함께 사용하는 하네스 저장소다.
작업 전에는 아래 순서로 문서 컨텍스트를 확인한다.

## Lookup Order

1. `common/index.md`
2. `stack/index.md`
3. 대상 프레임워크의 `index.md`
4. 실제 프로젝트가 있다면 `project/<name>/docs/index.md`

## Core Rules

- 변경은 작고 명확하게 유지한다.
- 문서 폴더에는 항상 `index.md`를 유지한다.
- 새로운 문서를 추가하면 해당 `index.md`도 함께 갱신한다.
- 사용자가 요청하지 않은 실제 프로젝트 코드는 루트 워크스페이스 Git에 추가하지 않는다.
- 계획이나 트러블슈팅이 필요하면 대화에서 끝내지 말고 문서로 남긴다.
- 이슈와 PR을 다룰 때는 `.github` 템플릿과 공통 템플릿 구조를 따른다.

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

- 프로젝트 컨테이너는 `project/<name>/` 아래에 둔다.
- 실제 Git 저장소는 `project/<name>/<repo-name>/` 아래에 둔다.
- 루트 Git은 `project/*/...` 아래 내용을 추적하지 않는다.
- 프로젝트 전용 규칙과 스펙은 컨테이너 루트의 `docs/`에 둔다.
- 실제 프로젝트 계획 문서는 컨테이너 루트의 `plan/`에 둔다.
- 실제 프로젝트 트러블슈팅 문서는 컨테이너 루트의 `troubleshooting/`에 둔다.
- 파일명은 `YYYY-MM-DD_HHMM_<slug>.md` 형식을 기본으로 한다.
- 기존 계획이나 같은 이슈의 후속 문서면 `_v2`, `_v3`처럼 버전을 올린다.
- 프로젝트는 특정 프레임워크 트리 아래에 두지 않는다.

## Workspace Conventions

- `skills/`에는 재사용 가능한 작업 스킬 문서를 둔다.
- `common/`에는 공통 컨벤션, 공통 스펙, 공통 템플릿을 둔다.
- 각 프레임워크 루트에는 프레임워크 전용 컨벤션과 스펙을 둔다.
- 모든 프레임워크 스택은 `stack/` 아래에서 함께 관리한다.
- 짧은 재사용 코드 조각은 각 프레임워크 `snippets/`에 둔다.
- `scripts/`에는 반복 실행할 자동화 스크립트를 둔다.
- GitHub 이슈/PR 강제 템플릿은 `.github/`에서 관리한다.
