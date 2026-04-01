# Workspace Git Governance

이 문서는 하네스 저장소 자체에 적용하는 Git 브랜치와 PR 기준을 정의한다.

## Purpose

- 하네스 저장소와 실제 프로젝트 저장소의 Git 전략을 구분한다.
- 문서, 스크립트, 스킬, GitHub workflow가 실제 저장소 상태와 어긋나지 않게 한다.
- 하네스 저장소에 실제로 없는 `develop` 브랜치를 암묵 기본값처럼 취급하지 않게 한다.

## Scope

이 문서는 아래 저장소에만 직접 적용한다.

- 이 하네스 루트 저장소 `C:\Users\imdls\workspace\Project Workspace`

실제 프로젝트 저장소의 기본 브랜치 전략은 이 문서가 아니라 `git-branch-gitflow.md` 또는 해당 프로젝트 문서가 정한다.

## Long-Lived Branch

- 하네스 저장소의 장기 유지 브랜치는 `main` 하나를 기준으로 한다.
- 하네스 저장소 작업은 `main`에서 분기한 짧은 작업 브랜치에서 진행한다.
- 하네스 저장소에서 `develop` 브랜치는 기본 전제로 두지 않는다.

## Work Branch Rule

기본 작업 브랜치 형식:

```text
feat/<short-name>
refactor/<short-name>
hotfix/<short-name>
```

규칙:

- `feat/*`, `refactor/*`, `hotfix/*`는 모두 `main`에서 분기한다.
- 직접 `main`에서 기능 작업을 누적하지 않는다.
- 긴 수명의 통합 브랜치를 추가로 만들지 않는다.
- 하나의 작업 브랜치에는 하나의 의도만 담는다.

## Pull Request Rule

- 하네스 저장소 PR의 기본 base branch는 `main`이다.
- 하네스 저장소 workflow는 `main` 기준 PR과 `main` 대상 push를 기본 감시 대상으로 둔다.
- 하네스 저장소에서 `develop`을 병합 대상이나 필수 중간 브랜치로 요구하지 않는다.

## Relation To Project Repositories

- 실제 프로젝트 저장소는 registry가 가리키는 별도 Git 맥락이다.
- 실제 프로젝트 저장소는 필요하면 `main` + `develop` 기반 GitFlow를 사용할 수 있다.
- 실제 프로젝트 저장소에 프로젝트 전용 Git 규칙 문서가 있으면 그 문서를 우선한다.

즉, 하네스 저장소와 실제 프로젝트 저장소는 같은 브랜치 전략을 강제로 공유하지 않는다.

## Do Not

- 하네스 저장소에 실제 프로젝트 저장소용 GitFlow 규칙을 그대로 적용하지 않는다.
- 하네스 저장소 workflow trigger에 존재하지 않는 장기 브랜치를 기본값처럼 남겨 두지 않는다.
- PR base branch를 저장소 맥락 확인 없이 추정하지 않는다.
