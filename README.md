# Project Workspace

이 저장소는 Codex와 Claude가 함께 사용하는 하네스 워크스페이스다.
공통 컨벤션, 스펙 문서, 프레임워크별 지식, 실제 프로젝트 저장소를 한 공간에서 관리한다.

## Goals

- 공통 규칙과 스펙을 빠르게 찾을 수 있어야 한다.
- 프레임워크별 문서를 독립적으로 축적할 수 있어야 한다.
- 실제 프로젝트는 워크스페이스 안에 두되, 루트 Git과는 분리되어야 한다.

## Root Structure

```text
skills/                  # 재사용 가능한 스킬 문서
common/                  # 공통 컨벤션, 공통 스펙, 공통 템플릿
stack/                   # 모든 프레임워크 스택 묶음
stack/spring/            # Spring 문서 인덱스와 세부 문서
stack/spring-webflux/    # Spring WebFlux 문서 인덱스와 세부 문서
stack/fastapi/           # FastAPI 문서 인덱스와 세부 문서
stack/react/             # React 문서 인덱스와 세부 문서
project/                 # 실제 프로젝트 보관 위치
scripts/                 # 워크플로우 자동화 스크립트
AGENTS.md                # Codex/Claude 공통 작업 규칙
CLAUDE.MD                # Claude 전용 작업 규칙
```

## Document Rules

- 모든 문서 폴더는 상단에 `index.md`를 둔다.
- `index.md`는 문서 전체를 읽지 않아도 어떤 문서가 있는지 빠르게 찾을 수 있어야 한다.
- 공통 규칙은 `common/`에 둔다.
- 프레임워크별 규칙은 `stack/<framework>/` 아래에 둔다.
- 모든 프레임워크 스택은 `stack/` 아래에서 함께 관리한다.
- 공통 템플릿은 `common/templates/`에 둔다.
- 짧게 재사용하는 코드 예제는 각 프레임워크의 `snippets/`에 둔다.
- GitHub 이슈/PR 템플릿은 `.github/`에 두고, 설명용 공통 템플릿은 `common/templates/`에 둔다.

## Project Rules

실제 프로젝트는 아래와 같은 형태로 들어간다.

```text
project/miyou/docs/index.md
project/miyou/plan/
project/miyou/troubleshooting/
project/miyou/miyou/src/
project/miyou/miyou/.git
```

- `project/<name>/`는 프로젝트 컨테이너다.
- 실제 Git 저장소는 `project/<name>/<repo-name>/` 아래에 둔다.
- 프로젝트 자체 문서는 컨테이너 루트인 `project/<name>/docs/`에 둔다.
- 구현 계획은 `project/<name>/plan/`에 저장한다.
- 트러블슈팅 기록은 `project/<name>/troubleshooting/`에 저장한다.
- 루트 워크스페이스 Git은 `project/*/...` 아래 내용을 추적하지 않는다.
- `plan/`과 `troubleshooting/` 문서는 `YYYY-MM-DD_HHMM_<slug>.md` 형식을 기본으로 사용한다.
- 같은 주제의 후속 수정은 새 파일보다 `_v2`, `_v3` 버전을 우선한다.
- 프로젝트는 특정 프레임워크에 종속되지 않는다. 여러 프레임워크를 함께 써도 `project/<name>/` 하나로 관리한다.

## GitHub Rules

- 이슈는 `.github/ISSUE_TEMPLATE/`의 템플릿을 사용한다.
- 빈 이슈는 허용하지 않는다.
- PR은 `.github/PULL_REQUEST_TEMPLATE.md` 구조를 따른다.
- PR 본문 필수 섹션 검증은 `.github/workflows/validate-pr-template.yml`에서 강제한다.
