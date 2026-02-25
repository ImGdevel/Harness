# Git Branch Management With GitFlow

이 문서는 실제 프로젝트 Git 저장소에 기본 적용하는 브랜치 생성 및 관리 규칙을 정의한다.

## Base Branches

- `main`: 배포 기준이 되는 안정 브랜치
- `develop`: 다음 릴리스를 통합하는 기본 개발 브랜치

## Branch Types

- `feature/<name>`: 새 기능 작업
- `release/<version>`: 릴리스 준비
- `hotfix/<name>`: 운영 긴급 수정
- `support/<name>`: 장기 유지보수 브랜치가 필요할 때만 사용

## Start Points

- `feature/*`는 `develop`에서 분기한다.
- `release/*`는 `develop`에서 분기한다.
- `hotfix/*`는 `main`에서 분기한다.

## Merge Targets

- `feature/*`는 완료 후 `develop`으로 병합한다.
- `release/*`는 완료 후 `main`과 `develop`에 반영한다.
- `hotfix/*`는 완료 후 `main`과 `develop`에 반영한다.

## Naming Rule

기본 형식:

```text
feature/<short-name>
release/<version>
hotfix/<short-name>
```

예시:

```text
feature/login-refresh
feature/workspace-git-skill
release/1.2.0
hotfix/token-null-check
```

- 브랜치 이름에 이슈 번호를 기본 포함하지 않는다.
- 브랜치 이름은 작업 내용을 설명하는 짧은 영문 slug를 우선한다.

## Branch Operation Rule

- 새 작업 전 현재 브랜치 역할이 맞는지 확인한다.
- 브랜치 목적과 맞지 않으면 올바른 기준 브랜치에서 새로 분기한다.
- 오래된 feature 브랜치에 다른 작업을 계속 덧붙이지 않는다.
- release와 hotfix는 범위를 최소화한다.

## Local Workflow

1. 기준 브랜치를 최신 상태로 맞춘다.
2. 목적에 맞는 브랜치를 생성한다.
3. 변경을 작은 커밋으로 나눈다.
4. 필요한 검증을 수행한다.
5. 대상 브랜치로 병합 준비를 한다.

## Workspace Rule

- 사용자가 명시하지 않았다면 이 규칙의 기본 대상은 registry가 가리키는 실제 프로젝트 저장소다.
- 실제 프로젝트 저장소는 가능하면 같은 전략을 따르되, 프로젝트 고유 규칙이 있으면 그 규칙을 우선한다.
- 하네스 저장소 브랜치와 실제 프로젝트 저장소 브랜치를 혼동하지 않는다.

## Do Not

- 직접 `main`에서 기능 개발을 시작하지 않는다.
- 직접 `main`에 기능 커밋을 누적하지 않는다.
- `feature/*`를 릴리스 브랜치처럼 오래 유지하지 않는다.
- hotfix에 기능 추가를 섞지 않는다.
- 이슈 번호만으로 브랜치 이름을 구성하지 않는다.
