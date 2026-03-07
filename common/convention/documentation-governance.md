# Documentation Governance

이 문서는 이 하네스에서 문서를 어디에 두고, 어떤 `index.md`를 갱신하며, 공통 규칙과 프레임워크 규칙과 프로젝트 규칙이 어떻게 겹치는지를 정의한다.

## Purpose

- 문서를 항상 가장 가까운 소유 범위에 둔다.
- 문서 폴더 구조와 실제 탐색 경로가 어긋나지 않게 한다.
- 대화에만 남고 저장되지 않는 계획, 트러블슈팅, 설계 메모를 줄인다.

## Applies To

이 규칙은 아래 범위의 문서에 적용한다.

- `common/`
- `stack/`
- 실제 프로젝트 저장소의 `docs/`, `plan/`, `troubleshooting/`

하네스 내부 `project/`는 레지스트리 메타데이터 공간이므로, 프로젝트 본문 문서 저장 위치로 사용하지 않는다.

## Scope Ownership Rule

문서는 가장 가까운 소유 범위에 둔다.

- 워크스페이스 전체에 적용되는 규칙, 스펙, 템플릿은 `common/`
- 특정 프레임워크에만 적용되는 규칙과 예제는 `stack/<framework>/`
- 특정 프로젝트에만 적용되는 설계, 운영, 도메인 문서는 실제 프로젝트 저장소의 `<project-root>/docs/`
- 특정 프로젝트의 실행 계획은 `<project-root>/plan/`
- 특정 프로젝트의 재발 방지 가치가 있는 문제 해결 기록은 `<project-root>/troubleshooting/`

프로젝트 이름이 주어지면 먼저 하네스의 `project/registry.yaml`에서 `repo_path`를 찾고, 그 실제 저장소 경로를 문서 기준 경로로 사용한다.

같은 내용을 여러 범위에 중복 저장하지 않는다.
공통 규칙이 프로젝트에 그대로 적용되면 링크나 참조로 해결하고, 복사본을 만들지 않는다.

## Override Order

규칙이 겹치면 아래 순서로 우선한다.

1. 프로젝트 문서 규칙
2. 프레임워크 문서 규칙
3. 공통 문서 규칙

단, 프로젝트 또는 프레임워크 문서가 공통 규칙을 덮어쓸 때는 그 문서에서 예외 사실을 명시해야 한다.

## Required Directory Rule

문서 디렉터리는 기본적으로 `index.md`를 가져야 한다.

- `common/`의 문서 하위 디렉터리
- `stack/<framework>/`의 문서 하위 디렉터리
- 실제 프로젝트 저장소의 `<project-root>/docs/`와 그 하위 문서 디렉터리

문서 폴더를 만들었는데 아직 본문 문서가 없다면, 빈 폴더로 두지 말고 `index.md`를 먼저 둔다.
이때 `index.md`에는 최소한 목적과 현재 등록 문서 없음 상태를 적는다.

문서 디렉터리에 `index.md`가 이미 있다면 placeholder 용도의 `.gitkeep`는 유지하지 않는다.

## Index Maintenance Rule

새 문서를 추가하거나 이동할 때는 가장 가까운 `index.md`를 같은 작업에서 갱신한다.

기본 규칙은 아래와 같다.

- `common/<area>/foo.md`를 추가하면 `common/<area>/index.md`를 갱신한다.
- `stack/<framework>/<area>/foo.md`를 추가하면 `stack/<framework>/<area>/index.md`를 갱신한다.
- `<project-root>/docs/<area>/foo.md`를 추가하면 `<project-root>/docs/<area>/index.md`를 갱신한다.

하위 폴더 자체를 새로 만들면 부모 인덱스도 같이 갱신한다.

예시:

- `<project-root>/docs/operations/`를 새로 만들면 `<project-root>/docs/index.md`도 갱신한다.
- `stack/<framework>/entity/` 같은 새 영역을 만들면 `stack/<framework>/index.md`도 갱신한다.

## Index Content Rule

`index.md`는 전체 본문을 대체하는 장문의 설명서가 아니다.

- 문서 목록과 한 줄 설명 중심으로 유지한다.
- 열어보지 않아도 문서가 무엇인지 판단 가능해야 한다.
- 등록 문서가 아직 없으면 그 상태를 명시한다.
- 탐색 경로가 중요한 경우 상위 또는 관련 인덱스를 짧게 링크한다.

## Project Artifact Rule

프로젝트 산출물은 문서 종류에 따라 위치를 분리한다.

- 구현 계획: `<project-root>/plan/`
- 트러블슈팅 기록: `<project-root>/troubleshooting/`
- 설계/정책/API/인프라/보안 문서: `<project-root>/docs/`

프로젝트 전용 문서를 하네스의 `common/`이나 `stack/`에 바로 두지 않는다.
반대로 여러 프로젝트에 재사용되는 규칙을 특정 프로젝트 `docs/`에만 묶어 두지도 않는다.

## Empty Skeleton Rule

폴더 골격을 미리 만들 수는 있다.
하지만 그 경우에도 문서 탐색은 끊기지 않아야 한다.

- 문서 폴더를 예약만 해 두려면 `index.md`를 생성한다.
- `index.md`에는 해당 폴더의 목적을 쓴다.
- 추가 문서가 없으면 `현재 등록된 문서 없음.` 같은 상태를 적는다.
- `index.md`가 있는 폴더에 `.gitkeep`를 함께 두지 않는다.

## Audit Tool

문서 구조 정렬 상태를 점검할 때는 아래 스크립트를 사용한다.

```powershell
.\scripts\audit-documentation-governance.ps1
```

이 스크립트는 최소한 아래를 검사한다.

- 문서 디렉터리의 `index.md` 존재 여부
- `index.md`가 있는 폴더의 `.gitkeep` 잔존 여부
- 부모 `index.md`의 하위 디렉터리 참조 여부
- nearest `index.md`의 Markdown 파일 등록 여부
- 기본값으로는 현재 Git tracked 상태를 기준으로 검사한다.

CI나 배치 검증에서 실패로 처리하려면 `-FailOnIssue`를 사용한다.

## Forbidden Patterns

- `index.md` 없는 문서 폴더를 남기는 것
- 같은 문서를 여러 범위에 복제하는 것
- 프로젝트 전용 문서를 하네스의 `common/`에 두는 것
- 공통 규칙을 프로젝트 문서에 복붙해 분기시키는 것
- 계획이나 트러블슈팅 결과를 대화에만 남기고 파일로 저장하지 않는 것

## Related Docs

- `project-artifact-conventions.md`
- `project-doc-structure.md`
- `../../project/index.md`
- `../templates/project-plan-template.md`
- `../templates/troubleshooting-template.md`
