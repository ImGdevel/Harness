# Project Workspace

이 저장소는 Codex와 Claude가 함께 사용하는 하네스 워크스페이스다.
공통 컨벤션, 스펙 문서, 프레임워크별 지식, 실제 프로젝트 저장소를 한 공간에서 관리한다.

## Goals

- 공통 규칙과 스펙을 빠르게 찾을 수 있어야 한다.
- 프레임워크별 문서를 독립적으로 축적할 수 있어야 한다.
- 실제 프로젝트는 하네스 밖의 별도 Git 저장소로 두고, 하네스는 그 위치만 관리해야 한다.

## Root Structure

```text
skills/                  # 재사용 가능한 스킬 문서
common/                  # 공통 컨벤션, 공통 스펙, 공통 템플릿
stack/                   # 모든 프레임워크 스택 묶음
stack/spring/            # Spring 문서 인덱스와 세부 문서
stack/spring-webflux/    # Spring WebFlux 문서 인덱스, 세부 문서, 스니핏
stack/fastapi/           # FastAPI 문서 인덱스와 세부 문서
stack/react/             # React 문서 인덱스와 세부 문서
project/                 # 외부 프로젝트 레지스트리와 경로 메타데이터
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
- 공통 워크플로우 모델과 카탈로그는 `common/spec/`에 둔다.

## Workflow Model

이 워크스페이스의 표준 워크플로우 계층은 아래와 같다.

- `step`: 가장 작은 실행 단위
- `job`: 여러 step을 묶는 중단위 작업
- `pipeline`: 여러 job을 묶는 통합 작업 흐름

예를 들면:

- `branch-create`, `commit`, `push`, `open-pr`는 `step`
- `full-test`, `pr-delivery`는 `job`
- `implementation-delivery`, `incident-response`, `delivery-pipeline`은 `pipeline`

요청 의도가 분명하면 사용자가 모든 세부 단계를 나열하지 않아도 적절한 `job` 또는 `pipeline`을 자동 선택해 실행한다.
대단위 작업의 표준 이름은 `delivery pipeline`이며, 요구사항부터 PR 피드백 반영까지 장시간 연속 실행이 가능하다.

## Project Rules

- 하네스 내부 `project/`는 실제 프로젝트 저장소가 아니라 레지스트리 영역이다.
- 단일 진실 원천은 `project/registry.yaml`이다.
- `project/index.md`는 사람이 빠르게 찾기 위한 요약 인덱스다.
- 실제 프로젝트 Git 저장소는 하네스 밖 sibling 경로에 둔다.
- 사용자가 프로젝트 이름을 말하면 먼저 `project/registry.yaml`에서 `repo_path`를 찾는다.
- 실제 프로젝트 전용 문서와 산출물은 모두 해당 저장소 루트에 둔다.
- 기본 경로는 `<project-root>/docs/`, `<project-root>/plan/`, `<project-root>/troubleshooting/`다.
- `docs/`는 최소한 `api/`, `architecture/`, `convention/`, `domain-tech-spec/`, `erd/`, `infrastructure/`, `local-setup/`, `references/`, `security/`, `stack-selection/` 구조를 가진다.
- `plan/`과 `troubleshooting/` 문서는 `YYYY-MM-DD_HHMM_<slug>.md` 형식을 기본으로 사용한다.
- 같은 주제의 후속 수정은 새 파일보다 `_v2`, `_v3` 버전을 우선한다.
- 하네스 저장소 안으로 실제 프로젝트를 clone하거나 이동하지 않는다.

예시:

```text
project/registry.yaml
  -> miyou
     repo_path: C:\Users\imdls\workspace\MIYOU_ai-voice-chat

C:\Users\imdls\workspace\MIYOU_ai-voice-chat\
  docs\
  plan\
  troubleshooting\
  .git\
```

새 외부 프로젝트를 레지스트리에 등록할 때는 다음 스크립트를 사용한다.

```powershell
.\scripts\register-project.ps1 -ProjectId <id> -DisplayName <name> -RepoPath <absolute-path>
```

## GitHub Rules

- 이슈는 `.github/ISSUE_TEMPLATE/`의 템플릿을 사용한다.
- 빈 이슈는 허용하지 않는다.
- PR은 `.github/PULL_REQUEST_TEMPLATE.md` 구조를 따른다.
- PR 본문 필수 섹션 검증은 `.github/workflows/validate-pr-template.yml`에서 강제한다.
