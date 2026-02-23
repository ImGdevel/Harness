# Projects Index

이 디렉터리는 실제 프로젝트 저장소의 목록을 관리한다.

## Rule

- 프로젝트 컨테이너는 `project/<project-name>/` 아래에 둔다.
- 실제 Git 저장소는 `project/<project-name>/<repo-name>/` 아래에 둔다.
- 각 컨테이너는 최소한 `docs/`, `plan/`, `troubleshooting/`, `<repo-name>/` 구조를 가진다.
- `docs/`는 최소한 `api/`, `architecture/`, `convention/`, `domain-tech-spec/`, `erd/`, `infrastructure/`, `local-setup/`, `references/`, `security/`, `stack-selection/`을 가진다.
- 실제 저장소는 `<repo-name>/src/`, `<repo-name>/.git` 같은 구조를 가진다.
- 계획 문서는 컨테이너 루트의 `plan/`에, 트러블슈팅 기록은 컨테이너 루트의 `troubleshooting/`에 둔다.
- 파일명과 버전 규칙은 `common/convention/project-artifact-conventions.md`를 따른다.
- `docs/` 표준 구조는 `common/convention/project-doc-structure.md`를 따른다.
- 프로젝트는 특정 프레임워크 폴더에 종속되지 않는다.
- `plan/`과 `troubleshooting/`는 필수 디렉터리다.
- 컨테이너를 새로 만들 때 이 디렉터리들이 없으면 먼저 만든다.

## Minimum Tree

```text
project/<project-name>/
  docs/
    index.md
    api/
      index.md
    architecture/
      index.md
    convention/
      index.md
    domain-tech-spec/
      index.md
    erd/
      index.md
    infrastructure/
      index.md
    local-setup/
      index.md
    references/
      index.md
    security/
      index.md
    stack-selection/
      index.md
  plan/
  troubleshooting/
  <repo-name>/
    .git/
    src/
```

## Tracking

- 루트 워크스페이스 Git은 `project/*/...` 아래 내용을 추적하지 않는다.
- 이 인덱스 파일에는 프로젝트 이름, 실제 저장소 이름, 사용 프레임워크, 목적, 상태를 기록한다.
- 실제 컨테이너 디렉터리가 아직 안 보인다면, 아직 `project/<project-name>/`를 만들지 않은 상태일 가능성이 높다.
