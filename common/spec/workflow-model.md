# Workflow Model

이 문서는 이 워크스페이스에서 사용하는 워크플로우 계층과 자동 실행 규칙을 정의한다.

## Goal

- 반복되는 작업 흐름을 작은 단위부터 큰 단위까지 일관되게 정의한다.
- 사용자가 모든 세부 단계를 직접 나열하지 않아도 적절한 작업 흐름을 자동 선택할 수 있게 한다.
- 스킬, 스크립트, 문서 규칙을 같은 모델 위에서 연결한다.

## Standard Terms

이 워크스페이스의 표준 계층은 아래와 같다.

### Step

가장 작은 실행 단위다.

예시:

- `branch-create`
- `compile-backend`
- `test-unit-backend`
- `test-integration-backend`
- `lint-frontend`
- `test-playwright`
- `commit`
- `push`
- `open-pr`
- `save-plan`
- `save-troubleshooting`

## Job

하나의 목적을 가진 중단위 작업 단위다.
여러 `step`을 순서대로 묶는다.

예시:

- `full-test`
- `pr-delivery`
- `plan-sync`
- `troubleshooting-record`

## Pipeline

여러 `job`을 묶는 통합 단위 워크플로우다.
프로젝트 진행 단계 전체를 이어서 수행할 때 사용한다.

예시:

- `implementation-delivery`
- `incident-response`
- `project-bootstrap`

`pipeline`은 장시간 실행과 반복 루프를 포함할 수 있다.
설계 검토, 검증 실패, 피드백 반영처럼 같은 `job`을 여러 번 되돌아가며 수행해도 된다.

## Selection Rule

- 요청이 원자적이면 `step`만 수행한다.
- 하나의 결과를 만들기 위해 여러 단계가 필요하면 `job`을 수행한다.
- 여러 `job`을 연속으로 묶어야 목표가 완성되면 `pipeline`을 수행한다.
- 가능한 한 가장 작은 단위로 시작하되, 사용자의 의도가 분명하면 필요한 상위 단위를 자동 선택한다.

## Automatic Trigger Rule

워크플로우는 사용자가 모든 세부 단계를 직접 지시하지 않아도 자동으로 선택될 수 있다.

예시:

- `전체 테스트 돌려` -> `full-test` job
- `커밋하고 PR 올려` -> `pr-delivery` job
- `이 기능 끝내고 PR까지` -> `implementation-delivery` pipeline
- `이 장애 원인 정리하고 수정해서 올려` -> `incident-response` pipeline

단, 아래 경우에는 자동 진행을 멈추고 확인하거나 실패로 반환한다.

- 저장소 경계가 불명확할 때
- 파괴적 명령이 필요할 때
- 필수 선행 조건이 없을 때
- 검증 단계가 실패했을 때

## Workflow Definition Rule

모든 `job`과 `pipeline`은 최소한 아래를 가져야 한다.

- 이름
- 목적
- 자동 트리거 조건
- 선행 조건
- 포함 단계 또는 하위 작업
- 중단 조건
- 출력물

반복 루프가 핵심인 `pipeline`은 아래도 같이 정의한다.

- 반복 조건
- 재진입 지점
- 승인 게이트

## Skill Relationship

- `step`는 개별 명령이나 기존 스킬이 직접 수행할 수 있다.
- `job`은 여러 `step` 또는 여러 스킬을 조합한다.
- `pipeline`은 여러 `job`을 조합한다.
- 스킬은 워크플로우를 설명하고 선택하는 진입점이 될 수 있다.
