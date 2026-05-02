# Workflow Catalog

## Purpose

Use this file as the runtime registry for `job` and `pipeline`.

## Rules

- Keep each entry short.
- Keep only runtime fields such as `Trigger`, `Preconditions`, `Steps`, `Loop`, `Output`.
- Do not add long rationale here.
- If runtime order conflicts with another doc, this file wins.

## Registered Jobs

### `requirement-shaping`

- 목적: 모호한 요구사항을 실행 가능한 기준으로 상세화한다.
- 자동 트리거:
  - 새 기능 요청이 들어왔을 때
  - 요구사항이 추상적일 때
  - 구현 전에 완료 기준이 불명확할 때
- 포함 step:
  - `clarify-goal`
  - `define-scope`
  - `define-done-criteria`
  - `record-plan-context`
- 출력물:
  - 요구사항 정리 메모
  - 계획 문서 또는 요구사항 기준

### `context-discovery`

- 목적: 구현 전에 필요한 문서, 코드, 참고 자료를 탐색한다.
- 자동 트리거:
  - 기존 시스템을 수정할 때
  - 연관 문서가 많을 때
  - 설계 전에 근거 수집이 필요할 때
- 포함 step:
  - `read-common-docs`
  - `read-stack-docs`
  - `read-project-docs`
  - `inspect-related-code`
- 출력물:
  - 관련 문서 목록
  - 참고 근거 목록

### `design-sync`

- 목적: 설계 문서를 작성하고 검토와 수정 루프를 반복해 안정화한다.
- 자동 트리거:
  - 구현 전에 설계가 필요한 변경일 때
  - 아키텍처, API, 도메인, 데이터 모델 변경이 포함될 때
- 포함 step:
  - `draft-design-doc`
  - `review-design-doc`
  - `revise-design-doc`
  - `re-review-design-doc`
- 반복 조건:
  - 검토 결과가 불충분하거나 구현 가능성이 낮을 때
- 인덱스 규칙:
  - 새 설계 문서를 만들거나 문서 폴더를 추가했다면 같은 흐름에서 `index-sync`를 수행한다.
- 출력물:
  - 설계 문서 또는 갱신된 스펙 문서

### `work-bootstrap`

- 목적: 구현 작업 전 브랜치, 이슈, 실제 프로젝트 저장소 문서 구조를 준비한다.
- 자동 트리거:
  - 실제 구현 착수 직전
  - 프로젝트 registry 항목이나 브랜치가 아직 정리되지 않았을 때
- 포함 step:
  - `resolve-project-path`
  - `read-project-registry`
  - `validate-project-git-context`
  - `validate-doc-source`
  - `create-issue`
  - `create-branch`
  - `ensure-project-doc-structure`
- 중단 조건:
  - 실제 프로젝트 원격에 `main` 또는 GitFlow의 `develop`이 없음
  - 원격 HEAD가 registry의 `default_branch`와 다름
  - 현재 브랜치가 작업 의도와 다른 기존 브랜치임
  - 프로젝트 문서 원천이 repo인지 Wiki인지 확인되지 않음
- 출력물:
  - 작업 브랜치
  - 이슈 또는 작업 단위
  - 준비된 실제 프로젝트 저장소 문서 구조

### `implementation-cycle`

- 목적: 설계 기준으로 구현하고, 필요 시 트러블슈팅을 끼워 넣으며 전진한다.
- 자동 트리거:
  - 설계가 준비된 뒤 구현에 착수할 때
- 포함 step:
  - `implement-slice`
  - `resolve-blocker`
  - `continue-implementation`
- 출력물:
  - 구현 변경분

### `test-authoring`

- 목적: 변경 범위에 필요한 테스트를 작성하거나 갱신한다.
- 자동 트리거:
  - 새 기능 또는 버그 수정 후
  - 검증 기준을 코드로 남겨야 할 때
- 포함 step:
  - `write-unit-tests`
  - `write-integration-tests`
  - `write-e2e-tests`
- 출력물:
  - 테스트 코드

### `quality-cycle`

- 목적: 검증과 리팩터링을 반복해 안정 상태로 만든다.
- 자동 트리거:
  - 구현 직후
  - PR 전 품질 정리 단계
- 포함 step:
  - `compile`
  - `run-targeted-tests`
  - `refactor`
  - `re-run-targeted-tests`
- 반복 조건:
  - 리팩터링 이후 검증 실패
  - 구현 품질이 아직 정리되지 않았을 때
- 출력물:
  - 안정화된 구현 상태

### `index-sync`

- 목적: 문서를 추가, 이동, 구조 변경한 뒤 가장 가까운 `index.md`와 필요한 부모 인덱스를 같은 상태로 맞춘다.
- 자동 트리거:
  - 새 문서를 만들었을 때
  - 문서를 다른 폴더로 이동했을 때
  - 새 문서 폴더를 만들었을 때
  - 문서 구조 정리 후 탐색 경로가 바뀌었을 때
- 선행 조건:
  - 대상 문서 범위가 명확해야 한다.
  - 수정된 문서 경로와 소유 범위를 알고 있어야 한다.
- 포함 step:
  - `detect-nearest-index`
  - `update-nearest-index`
  - `update-parent-index-if-needed`
  - `verify-index-entry`
  - `run-documentation-governance-audit`
- 출력물:
  - 갱신된 `index.md`
  - 정렬된 부모 인덱스

### `requirements-implementation-sync`

- 목적: 요구사항, 설계, 구현이 일치하는지 교차 검증한다.
- 자동 트리거:
  - 큰 변경의 구현이 끝난 뒤
  - PR 전 최종 점검 단계
- 포함 step:
  - `compare-requirements`
  - `compare-design`
  - `resolve-drift`
- 출력물:
  - 일치 상태 또는 드리프트 수정

### `plan-sync`

- 목적: 프로젝트 작업 전에 계획 문서를 만들거나, 범위 변경 시 기존 계획을 갱신한다.
- 자동 트리거:
  - 기능 구현을 시작할 때
  - 프로젝트 범위가 커졌을 때
  - 사용자가 계획을 명시적으로 요청했을 때
- 선행 조건:
  - 대상 프로젝트가 registry에서 식별되어야 한다.
  - 실제 프로젝트 저장소의 registry `plan_path` 디렉터리가 준비되어야 한다.
- 포함 step:
  - `select-project`
  - `resolve-project-path`
  - `create-plan-directory`
  - `draft-plan`
  - `save-plan`
- 출력물:
  - 기본 경로 기준 `<project-root>/docs/plan/YYYY-MM-DD_HHMM_<slug>.md`

### `troubleshooting-record`

- 목적: 재사용 가치가 있는 디버깅 결과를 프로젝트 문서로 남긴다.
- 자동 트리거:
  - 버그 원인을 파악했을 때
  - 장애 대응이 끝났을 때
  - 반복 방지 가치가 있는 수정이 끝났을 때
- 선행 조건:
  - 대상 프로젝트가 registry에서 식별되어야 한다.
  - 실제 프로젝트 저장소의 registry `troubleshooting_path` 디렉터리가 준비되어야 한다.
- 포함 step:
  - `collect-symptoms`
  - `summarize-root-cause`
  - `record-fix`
  - `save-troubleshooting`
- 출력물:
  - 기본 경로 기준 `<project-root>/docs/troubleshooting/YYYY-MM-DD_HHMM_<slug>.md`

### `full-test`

- 목적: 프로젝트 전체 스택에 대한 통합 검증을 수행한다.
- 자동 트리거:
  - 사용자가 `전체 테스트`, `전체 검증`, `머지 전 검증`을 요청할 때
  - 큰 리팩터링이나 다중 스택 변경 후 PR 준비 단계일 때
- 선행 조건:
  - 실제 프로젝트 저장소와 스택 구성이 식별되어야 한다.
  - 사용할 테스트/빌드/린트 명령을 알고 있어야 한다.
- 포함 step 예시:
  - `compile-backend`
  - `test-unit-backend`
  - `test-integration-backend`
  - `lint-frontend`
  - `test-unit-frontend`
  - `test-playwright`
- Spring + React 예시:
  - Spring 컴파일
  - Spring 단위 테스트
  - Spring 통합 테스트
  - React ESLint
  - React 단위 테스트
  - Playwright E2E
- 출력물:
  - 실행 명령 목록
  - pass/fail 요약
  - 실패 지점

### `pr-delivery`

- 목적: 현재 변경을 PR 가능한 상태까지 끌고 간다.
- 자동 트리거:
  - `커밋하고 푸시해`
  - `PR 올려`
  - `브랜치 푸시하고 PR 본문까지 준비해`
- 선행 조건:
  - 작업 대상 저장소가 명확해야 한다.
  - 올바른 브랜치 전략이 적용되어야 한다.
  - 하네스 저장소면 base branch를 `main`으로 본다.
  - 실제 프로젝트 저장소면 해당 저장소 문서 기준 브랜치를 따른다.
  - 필요한 검증이 통과하거나, 왜 건너뛰는지 설명 가능해야 한다.
- 포함 step:
  - `validate-repo-context`
  - `validate-project-git-context`
  - `validate-branch`
  - `run-required-checks`
  - `commit`
  - `push`
  - `draft-pr`
  - `open-pr`
- 중단 조건:
  - 원격 기준 브랜치가 없거나 원격 HEAD가 잘못됨
  - 현재 브랜치가 보호 브랜치이거나 이름 규칙을 위반함
  - 현재 브랜치가 기대 base branch에서 시작하지 않음
  - 현재 브랜치가 통합되지 않은 다른 feature 브랜치 위에 쌓임
  - staged 변경이 둘 이상의 의도를 포함함
- 출력물:
  - 커밋
  - 원격 브랜치
  - PR 본문 또는 PR URL

### `implementation-doc-sync`

- 목적: 구현 결과와 프로젝트 문서를 같은 상태로 맞춘다.
- 자동 트리거:
  - 구현 완료 직후
  - API, ERD, architecture, domain-tech-spec 변화가 생겼을 때
- 포함 step:
  - `update-api-docs`
  - `update-erd-docs`
  - `update-architecture-docs`
  - `update-domain-tech-spec`
  - `update-local-setup-or-security-docs`
- 인덱스 규칙:
  - 새 문서를 만들거나 이동했다면 같은 흐름에서 `index-sync`를 이어서 수행한다.
- 출력물:
  - 동기화된 프로젝트 문서

### `backlog-capture`

- 목적: 이번 흐름에서 다 하지 못한 후속 작업을 문서로 남긴다.
- 자동 트리거:
  - 구현 완료 시점
  - PR 전 남은 작업이 확인됐을 때
- 포함 step:
  - `capture-follow-up-items`
  - `record-known-limits`
  - `record-next-actions`
- 출력물:
  - 후속 작업 메모 또는 backlog 문서

### `feedback-response`

- 목적: PR 피드백을 반영하고 필요한 재검증과 문서 동기화를 반복한다.
- 자동 트리거:
  - PR 리뷰 피드백이 들어왔을 때
- 포함 step:
  - `analyze-feedback`
  - `apply-change`
  - `re-validate`
  - `re-sync-docs`
- 반복 조건:
  - 미해결 피드백이 남아 있을 때
- 출력물:
  - 반영된 수정과 갱신된 검증 상태

## Registered Pipelines

### `implementation-delivery`

- 목적: 구현 시작부터 PR 준비까지 이어지는 기본 전달 파이프라인이다.
- 자동 트리거:
  - `이 기능 작업해서 PR까지`
  - `구현하고 검증해서 올려`
  - `끝까지 처리해`
- 포함 job:
  - `plan-sync`
  - 구현 작업
  - `full-test` 또는 변경 범위 검증
  - `pr-delivery`
- 중단 조건:
  - 계획 저장 실패
  - 테스트 실패
  - 브랜치/저장소 전략 충돌

### `delivery-pipeline`

- 목적: 요구사항 상세화부터 설계, 구현, 검증, 문서화, PR, 피드백 반영까지 이어지는 대단위 전달 파이프라인이다.
- 단일 진실 원천:
  - 정확한 `job` 구성과 순서는 이 등록 항목이 기준이다.
  - 지원 문서는 의도와 실행 규칙만 설명하며, 이 순서를 재정의하지 않는다.
- 자동 트리거:
  - `요구사항부터 끝까지 처리해`
  - `설계부터 구현, 테스트, PR, 피드백까지 이어서 해`
  - `프롬프트 다시 안 쓸 테니 끝까지 진행해`
- 포함 job:
  - `requirement-shaping`
  - `context-discovery`
  - `plan-sync`
  - `design-sync`
  - `work-bootstrap`
  - `implementation-cycle`
  - `test-authoring`
  - `quality-cycle`
  - `requirements-implementation-sync`
  - `full-test`
  - `troubleshooting-record` if needed
  - `implementation-doc-sync`
  - `index-sync` if needed
  - `backlog-capture`
  - `pr-delivery`
  - `feedback-response`
- 전달 규칙:
  - 커밋, 푸시, PR 생성은 별도 `job`으로 분리하지 않고 `pr-delivery`에 포함한다.
  - 계획 저장은 초반 `plan-sync`에서 처리한다.
- 반복 조건:
  - 설계 재검토 필요
  - 검증 실패
  - 피드백 반영 필요
  - 트러블슈팅 발생
- 중단 조건:
  - 요구사항 불명확
  - 외부 승인 대기
  - 해결 불가한 검증 실패
  - 저장소 또는 브랜치 전략 충돌
- 출력물:
  - 계획 문서
  - 설계/구현 동기화 상태
  - 테스트 및 검증 결과
  - 트러블슈팅 문서
  - 구현 문서
  - 커밋/PR/피드백 반영 결과

### `incident-response`

- 목적: 장애나 버그 대응을 원인 분석부터 문서화와 PR 준비까지 묶는다.
- 자동 트리거:
  - `이 버그 원인 분석해서 고치고 정리해`
  - `장애 대응 끝까지 해`
- 포함 job:
  - 재현 및 원인 분석
  - 수정 작업
  - `full-test` 또는 영향 범위 검증
  - `troubleshooting-record`
  - `pr-delivery`
- 중단 조건:
  - 재현 불가
  - 수정 검증 실패
  - 원인 불명 상태

### `project-bootstrap`

- 목적: 외부 프로젝트를 하네스 registry에 등록하고, 필요하면 해당 저장소의 기본 문서 구조를 정렬한다.
- 자동 트리거:
  - `새 프로젝트 등록해`
  - `프로젝트 레지스트리에 추가해`
  - `프로젝트 문서 구조부터 세팅해`
- 포함 job:
  - registry entry 생성 또는 갱신
  - `project/index.md` summary row 동기화
  - registry/index 정합성 감사
  - 실제 프로젝트 경로 검증
  - `scripts/bootstrap-project-docs.ps1` 실행
  - 실제 프로젝트 저장소의 `docs/`, `docs/plan/`, `docs/troubleshooting/` 정렬
  - 필요한 초기 인덱스 문서 작성
- 검증 규칙:
  - `scripts/register-project.ps1`로 registry를 갱신했다면 같은 흐름에서 `scripts/audit-project-registry.ps1`를 통과해야 한다.
  - 프로젝트 문서 골격을 정렬했다면 실제 프로젝트 저장소에 `docs/index.md`, `docs/plan/index.md`, `docs/troubleshooting/index.md`가 생겨야 한다.
- 중단 조건:
  - 프로젝트 이름 또는 실제 저장소 경로가 없음
  - 경로 충돌

## Selection Guidance

- PR까지 가는 흐름이 필요하면 `pr-delivery` 또는 `implementation-delivery`
- 전체 검증이 목적이면 `full-test`
- 문서를 추가하거나 이동한 뒤 인덱스만 정리해야 하면 `index-sync`
- 디버깅 결과를 남겨야 하면 `troubleshooting-record` 또는 `incident-response`
- 새 프로젝트 시작이면 `project-bootstrap`
- 요구사항부터 피드백 반영까지 한 번에 이어야 하면 `delivery-pipeline`
