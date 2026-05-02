# Project Git Governance

## Purpose

실제 프로젝트 저장소에서 브랜치, 원격 기준 브랜치, 문서 원천을 작업 전에 검증하는 기준이다.

## Applies To

- 하네스 `project/registry.yaml`에 등록된 실제 프로젝트 저장소
- 구현, 커밋, 푸시, PR, 장기 문서 변경이 포함된 작업
- 하네스 저장소 자체에는 적용하지 않는다. 하네스 저장소는 `workspace-git-governance.md`를 따른다.

## Registry Contract

프로젝트 항목은 기본 필드에 더해 아래 필드를 둘 수 있다.

- `branch_strategy`: 기본 `gitflow`
- `default_branch`: GitHub default branch. GitFlow 프로젝트 기본 `develop`
- `production_branch`: production branch. GitFlow 프로젝트 기본 `main`
- `integration_branch`: integration branch. GitFlow 기본 `develop`
- `docs_source`: `repo` 또는 `wiki`. 기본 `repo`
- `wiki_path`: `docs_source: wiki`일 때 로컬 Wiki 저장소 경로

`docs_source: wiki` 프로젝트는 실제 repo 안 `docs/` 대신 Wiki를 문서 원천으로 사용한다. 이 경우 작업 전 Wiki의 `Home.md`와 문서 정책 페이지를 먼저 확인한다.

GitFlow 프로젝트에서 GitHub default branch는 `develop`을 권장한다. `main`은 production 기준으로 유지하되 일반 기능 PR의 기본 base는 `develop`이어야 한다.

## Branch Rules

- 실제 프로젝트 GitFlow 브랜치는 `feat/*`, `refactor/*`, `hotfix/*`만 사용한다.
- `feat/*`, `refactor/*`는 최신 `develop`에서 시작한다.
- `hotfix/*`는 최신 `main`에서 시작한다.
- `main`, `develop`, `master`에서 직접 구현하거나 커밋하지 않는다.
- 하나의 작업 브랜치는 하나의 의도만 가진다.
- 작업 의도가 바뀌면 기존 브랜치를 계속 쓰지 말고 새 브랜치를 만든다.
- 다른 feature 브랜치를 기반으로 새 feature 브랜치를 쌓지 않는다. 예외가 필요하면 stacked branch임을 명시하고 PR 순서를 문서화한다.

## Required Preflight

구현, 커밋, 푸시, PR 전에 아래 검증이 통과해야 한다.

```powershell
.\scripts\validate-project-git-context.ps1 -ProjectId techlog-hub -FailOnIssue
```

검증 항목:

- registry의 `repo_path`가 실제 Git 저장소인지 확인
- `origin/<default_branch>` 존재 확인
- GitFlow 프로젝트는 `origin/<production_branch>`와 `origin/<integration_branch>` 존재 확인
- 원격 HEAD가 `default_branch`와 일치하는지 확인
- 현재 브랜치가 `feat/*`, `refactor/*`, `hotfix/*` 형식인지 확인
- 현재 브랜치가 기대 base branch를 포함하는지 확인
- 현재 브랜치가 아직 integration branch에 포함되지 않은 다른 feature 브랜치 위에 쌓였는지 확인
- Wiki 문서 원천 프로젝트는 `wiki_path`와 `Home.md` 존재 확인

## Stop Conditions

아래 중 하나라도 확인되면 다음 단계로 진행하지 않는다.

- 원격 `main` 또는 GitFlow의 `develop`이 없다.
- 원격 HEAD가 registry의 `default_branch`와 다르다.
- 현재 브랜치가 보호 브랜치다.
- 현재 브랜치 이름이 규칙과 다르다.
- 현재 브랜치가 기대 base branch를 포함하지 않는다.
- 현재 브랜치가 통합되지 않은 다른 feature 브랜치 위에 쌓였다.
- registry의 문서 원천과 실제 문서 위치가 충돌한다.

## Related Docs

- [git-branch-gitflow.md](</C:/Users/imdls/workspace/Project Workspace/common/convention/git-branch-gitflow.md>)
- [git-commit-conventions.md](</C:/Users/imdls/workspace/Project Workspace/common/convention/git-commit-conventions.md>)
- [workspace-git-governance.md](</C:/Users/imdls/workspace/Project Workspace/common/convention/workspace-git-governance.md>)
