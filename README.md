# Project Workspace

이 저장소는 Codex와 Claude가 함께 사용하는 `하네스`다.
목적은 실제 프로젝트를 이 저장소 안에 넣는 것이 아니라, 여러 프로젝트에 공통으로 적용할 `규칙`, `스택 지식`, `워크플로우`, `프로젝트 레지스트리`를 운영하는 것이다.

즉 이 README는 폴더 소개 문서라기보다, `이 하네스를 어떻게 쓰는지`를 설명하는 문서다.

## What This Harness Does

이 하네스는 아래 일을 한다.

- 공통 문서 규칙과 Git 규칙을 제공한다.
- Spring, WebFlux, FastAPI, React, Next.js 같은 스택 지식을 축적한다.
- 반복 작업을 `step`, `job`, `pipeline`으로 정리한다.
- 실제 프로젝트 이름을 실제 저장소 경로에 연결한다.
- 에이전트가 어느 저장소에서 작업해야 하는지 빠르게 판단하게 만든다.

이 하네스가 하지 않는 일도 분명하다.

- 실제 프로젝트 코드를 저장하지 않는다.
- 실제 프로젝트 Git 저장소를 대신 관리하지 않는다.
- 프로젝트 문서, plan, troubleshooting을 하네스 안에 저장하지 않는다.

## Core Rule

가장 중요한 원칙은 하나다.

- 하네스는 `운영체제`
- 실제 프로젝트 저장소는 `프로세스`

따라서 실제 프로젝트는 하네스 밖의 별도 Git 저장소여야 한다.
하네스는 그 프로젝트를 `찾고`, `이해하고`, `작업 흐름을 적용하는 기준`만 제공한다.

## How To Start Using It

기본 사용 순서는 아래와 같다.

1. 실제 프로젝트를 하네스 밖의 별도 경로에 clone한다.
2. 그 프로젝트를 하네스의 `project/registry.yaml`에 등록한다.
3. 에이전트에게 프로젝트 이름으로 작업을 요청한다.
4. 에이전트는 registry에서 실제 저장소 경로를 찾는다.
5. 공통 규칙과 스택 문서를 참고한 뒤, 실제 구현은 그 프로젝트 저장소에서 수행한다.

예를 들어 사용자가 `Miyou에 결제 기능 만들어줘`라고 말하면:

1. 하네스가 `project/registry.yaml`에서 `miyou`를 찾는다.
2. `repo_path`가 `C:\Users\imdls\workspace\MIYOU_ai-voice-chat`인지 확인한다.
3. 필요하면 `common/`과 `stack/` 문서를 읽는다.
4. 실제 코드 수정, 테스트, docs/plan, docs/troubleshooting, Git 작업은 `MIYOU_ai-voice-chat` 저장소에서 진행한다.

## Registering A Project

프로젝트 등록의 단일 진실 원천은 아래 파일이다.

- [project/registry.yaml](</C:/Users/imdls/workspace/Project Workspace/project/registry.yaml>)

사람이 빠르게 보는 요약은 아래 문서다.

- [project/index.md](</C:/Users/imdls/workspace/Project Workspace/project/index.md>)

새 프로젝트를 등록할 때는 아래 스크립트를 사용한다.

```powershell
.\scripts\register-project.ps1 `
  -ProjectId miyou `
  -DisplayName MIYOU `
  -RepoPath C:\Users\imdls\workspace\MIYOU_ai-voice-chat
```

이 스크립트는 `project/registry.yaml`과 `project/index.md`를 같은 변경에서 함께 갱신한다.

등록이 끝나면 에이전트는 프로젝트 이름이나 alias를 보고 실제 저장소 위치를 해석할 수 있어야 한다.

## Where Work Actually Happens

실제 프로젝트 문서와 산출물은 모두 실제 프로젝트 저장소 안에 둔다.

기본 경로는 아래와 같다.

```text
<project-root>/
  docs/
    plan/
    troubleshooting/
  .git/
```

의미는 이렇다.

- `<project-root>/docs/`
  프로젝트 전용 설계, API, ERD, 인프라, 보안, 로컬 셋업 문서
- `<project-root>/docs/plan/`
  구현 계획 문서
- `<project-root>/docs/troubleshooting/`
  재발 방지 가치가 있는 문제 해결 기록
- `<project-root>/.git/`
  실제 Git 작업 대상

하네스 안의 `project/`는 여기서 말하는 `<project-root>`가 아니다.
그건 registry 공간일 뿐이다.

## How Documents Are Organized

문서는 소유 범위에 따라 아래처럼 나눈다.

- `common/`
  모든 프로젝트에 공통인 규칙과 스펙
- `stack/`
  특정 프레임워크에 공통인 규칙, 스펙, 스니핏
- 실제 프로젝트 저장소의 `docs/`
  특정 프로젝트에만 속하는 문서

문서 폴더 규칙은 다음과 같다.

- 문서 폴더는 기본적으로 `index.md`를 가진다.
- 새 문서를 만들면 가장 가까운 `index.md`를 갱신한다.
- 새 문서 폴더를 만들면 부모 `index.md`도 같이 갱신한다.

자세한 기준은 아래 문서를 따른다.

- [common/convention/documentation-governance.md](</C:/Users/imdls/workspace/Project Workspace/common/convention/documentation-governance.md>)
- [common/convention/project-artifact-conventions.md](</C:/Users/imdls/workspace/Project Workspace/common/convention/project-artifact-conventions.md>)
- [common/convention/project-doc-structure.md](</C:/Users/imdls/workspace/Project Workspace/common/convention/project-doc-structure.md>)

## What `stack/` Means

`stack/`은 실제 프로젝트가 들어가는 곳이 아니다.
여기는 프레임워크 지식 베이스다.

현재 기준으로 아래 스택을 관리한다.

- `spring/`
- `spring-webflux/`
- `fastapi/`
- `react/`
- `nextjs/`

각 스택 루트에는 보통 아래가 있다.

- `convention/`
- `spec/`
- `test/`
- `snippets/`
- `index.md`

즉 `stack/spring/`은 Spring 프로젝트 폴더가 아니라, Spring을 쓰는 어떤 프로젝트에도 재사용할 수 있는 지식 저장소다.

## How Workflows Are Used

이 하네스는 작업을 세 계층으로 본다.

- `step`
  가장 작은 실행 단위
- `job`
  여러 step을 묶는 중단위 작업
- `pipeline`
  여러 job을 묶는 대단위 흐름

예시:

- `branch-create`, `commit`, `push`, `open-pr` -> `step`
- `full-test`, `pr-delivery`, `index-sync` -> `job`
- `implementation-delivery`, `incident-response`, `delivery-pipeline` -> `pipeline`

사용자가 모든 세부 단계를 하나씩 지시하지 않아도, 요청 의도가 명확하면 필요한 `job`이나 `pipeline`을 선택해서 진행하는 것이 목표다.

## Files You Will Touch Most Often

- [AGENTS.md](</C:/Users/imdls/workspace/Project Workspace/AGENTS.md>)
  Codex와 Claude 공통 작업 규칙
- [CLAUDE.MD](</C:/Users/imdls/workspace/Project Workspace/CLAUDE.MD>)
  Claude 전용 보조 규칙
- [project/registry.yaml](</C:/Users/imdls/workspace/Project Workspace/project/registry.yaml>)
  프로젝트 이름과 실제 저장소 경로 매핑
- [common/spec/workflow-model.md](</C:/Users/imdls/workspace/Project Workspace/common/spec/workflow-model.md>)
  `step`, `job`, `pipeline` 모델
- [common/spec/workflow-catalog.md](</C:/Users/imdls/workspace/Project Workspace/common/spec/workflow-catalog.md>)
  등록된 워크플로우 목록

## Scripts

- [scripts/register-project.ps1](</C:/Users/imdls/workspace/Project Workspace/scripts/register-project.ps1>)
  외부 프로젝트를 registry에 등록하거나 갱신한다.
- [scripts/bootstrap-project-docs.ps1](</C:/Users/imdls/workspace/Project Workspace/scripts/bootstrap-project-docs.ps1>)
  registry를 기준으로 실제 프로젝트 저장소의 `docs/`, `docs/plan/`, `docs/troubleshooting/` 기본 구조를 정렬한다.
- [scripts/audit-documentation-governance.ps1](</C:/Users/imdls/workspace/Project Workspace/scripts/audit-documentation-governance.ps1>)
  문서 인덱스와 배치 규칙 정합성을 점검한다.
- [scripts/audit-project-registry.ps1](</C:/Users/imdls/workspace/Project Workspace/scripts/audit-project-registry.ps1>)
  `project/registry.yaml`과 `project/index.md` 요약 정합성을 점검한다.

## Tools

- [tools/discord-codex-remote-control](</C:/Users/imdls/workspace/Project Workspace/tools/discord-codex-remote-control>)
  Discord slash command와 webhook으로 원격 작업 요청 큐와 주요 작업 완료 알림을 처리한다.

## GitHub Rules

- 이슈 템플릿은 `.github/ISSUE_TEMPLATE/`를 따른다.
- PR 템플릿은 `.github/PULL_REQUEST_TEMPLATE.md`를 따른다.
- PR 본문 필수 섹션 검증은 `.github/workflows/validate-pr-template.yml`에서 강제한다.

## Harness Git Strategy

이 하네스 저장소 자체는 `main`을 유일한 장기 브랜치로 사용한다.

- 하네스 저장소 작업 브랜치는 `main`에서 분기한다.
- 하네스 저장소 PR 기본 대상은 `main`이다.
- 하네스 저장소는 `develop`을 기본 전제로 두지 않는다.

반면 registry가 가리키는 실제 프로젝트 저장소는 별도 Git 맥락이다.
그 저장소들은 필요하면 `main` + `develop` 기반 GitFlow를 따를 수 있다.

기준 문서는 아래와 같다.

- [common/convention/workspace-git-governance.md](</C:/Users/imdls/workspace/Project Workspace/common/convention/workspace-git-governance.md>)
- [common/convention/git-branch-gitflow.md](</C:/Users/imdls/workspace/Project Workspace/common/convention/git-branch-gitflow.md>)
