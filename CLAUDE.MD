# CLAUDE Workspace Notes

이 파일은 Claude가 이 하네스 워크스페이스에서 따를 기본 작업 규칙을 정의한다.

## Working Flow

- 먼저 `common/index.md`를 확인한다.
- 복합 요청이면 `common/spec/workflow-model.md`와 `common/spec/workflow-catalog.md`의 job/pipeline 후보를 먼저 본다.
- 그다음 `stack/index.md`를 확인한다.
- 그다음 대상 프레임워크의 `index.md`를 확인한다.
- 실제 프로젝트 작업이면 `project/index.md`와 `project/registry.yaml`을 먼저 확인한다.
- registry에서 실제 저장소 경로를 찾았으면 그 저장소의 `docs/index.md`까지 확인한다.

## Documentation Rules

- 문서를 새로 만들면 해당 폴더의 `index.md`를 함께 갱신한다.
- 공통 규칙은 `common/`에 둔다.
- 프레임워크 전용 규칙은 각 프레임워크 루트에 둔다.
- 모든 프레임워크 스택은 `stack/` 아래에서 함께 관리한다.
- 짧은 재사용 코드 예제는 각 프레임워크의 `snippets/`에 둔다.
- 프로젝트 고유 규칙은 실제 프로젝트 저장소의 `docs/`에 둔다.
- 프로젝트 `docs/`는 최소한 `api/`, `architecture/`, `convention/`, `domain-tech-spec/`, `erd/`, `infrastructure/`, `local-setup/`, `references/`, `security/`, `stack-selection/` 구조를 유지한다.
- 프로젝트 계획은 기본적으로 실제 프로젝트 저장소의 `docs/plan/`에 저장한다.
- 프로젝트 트러블슈팅은 기본적으로 실제 프로젝트 저장소의 `docs/troubleshooting/`에 저장한다.
- 관련 문서를 다시 작성할 때는 새 날짜 파일보다 `_v2`, `_v3` 버전을 우선 검토한다.
- GitHub 이슈와 PR 본문은 `.github` 템플릿 구조를 우선한다.

## Project Handling

- 하네스 내부 `project/`는 registry와 요약 인덱스만 둔다.
- 실제 Git 저장소는 registry의 `repo_path`가 가리키는 외부 경로다.
- 루트 워크스페이스 Git에 실제 프로젝트 파일을 넣지 않는다.
- 실제 프로젝트를 수정할 때는 registry로 경로를 찾은 뒤 해당 저장소의 규칙을 우선한다.
- 계획이나 트러블슈팅이 장기 가치가 있으면 실제 프로젝트 저장소에 문서로 남긴다.
- `docs/plan/`과 `docs/troubleshooting/`는 실제 프로젝트 저장소 안의 필수 디렉터리로 본다.
- 디렉터리가 없으면 실제 프로젝트 저장소 안에 먼저 생성한 뒤 문서를 기록한다.

## Automation

- 반복되는 작업은 `scripts/`에 스크립트로 축적한다.
- 재사용 가능한 작업 지식은 `skills/`에 정리한다.
- 등록된 `job`이나 `pipeline`에 해당하는 요청은 세부 step을 다시 묻지 않고 자동으로 이어서 수행한다.
- `delivery-pipeline` 요청은 장시간 작업이 되더라도 완료나 실제 blocker까지 계속 진행한다.

## Git Basics

- 하네스 저장소 자체의 브랜치 기준은 `common/convention/workspace-git-governance.md`를 따른다.
- 하네스 저장소 작업 브랜치는 `main`에서 분기한다.
- 커밋은 하나의 의도만 담도록 유지한다.
- 파괴적인 Git 명령은 명시적 요청이 있을 때만 사용한다.
- PR 본문 필수 섹션 검증은 워크플로우에서 실패할 수 있으므로 템플릿을 유지한다.
