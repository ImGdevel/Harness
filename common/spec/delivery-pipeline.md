# Delivery Pipeline

이 문서는 요구사항부터 설계, 구현, 검증, 문서화, PR, 피드백 반영까지 이어지는 대단위 end-to-end `delivery pipeline`을 정의한다.

## Goal

- 중단위 `job`들을 하나의 장시간 작업 흐름으로 묶는다.
- 사용자가 세부 프롬프트를 반복 입력하지 않아도 작업 완료 상태까지 연속 실행한다.
- 설계 문서, 구현, 검증 결과, 후속 할 일을 끊기지 않게 하나의 흐름으로 관리한다.

## Standard Name

이 워크스페이스에서 대단위 작업의 표준 명칭은 `delivery pipeline`이다.

- `step`: 소단위 실행
- `job`: 중단위 작업
- `pipeline`: 대단위 통합 작업 흐름

## Long-Running Rule

- `delivery pipeline`은 1시간 이상 걸려도 된다.
- 한 번 시작하면 다음 `job`으로 자동 전진한다.
- 사용자가 다음 프롬프트를 다시 쓰지 않아도 된다.
- 아래 중단 조건이 없으면 멈추지 않는다.

## Stop Conditions

아래 경우에만 파이프라인을 중단하거나 확인한다.

- 저장소 경계가 불명확할 때
- 프로젝트 이름, 저장소 이름, 요구사항 자체가 불명확할 때
- 명시적 승인 게이트가 필요한데 승인 주체가 외부일 때
- 파괴적 명령이 필요할 때
- 테스트나 검증이 실패해서 다음 단계 진행 근거가 없을 때
- 요구사항과 설계가 심하게 충돌해 방향 결정을 사용자에게 받아야 할 때

## Core Principles

### Single Source Of Truth

- 요구사항 문서, 설계 문서, 구현 내용은 서로 드리프트를 허용하지 않는다.
- 구현이 바뀌면 설계/스펙 문서도 같은 흐름에서 갱신한다.
- 설계 문서가 바뀌면 구현과 검증 기준도 같이 조정한다.

### Loop Until Stable

- 설계 검토가 실패하면 설계 수정 후 다시 검토한다.
- 검증이 실패하면 수정 또는 리팩터링 후 다시 검증한다.
- PR 피드백이 들어오면 수정 후 다시 검증하고 문서 동기화까지 반복한다.

### Troubleshooting As Sidecar

- 작업 중 장애, 버그, 막힘이 생기면 현재 `job`을 일시 중단한다.
- 문제 해결 후 원래 흐름으로 복귀한다.
- 재발 방지 가치가 있으면 `troubleshooting-record`를 반드시 수행한다.

### Small Intent Delivery

- 구현은 하나의 큰 덩어리로 끝내지 않는다.
- 의미 있는 단위마다 검증하고, 설명 가능한 단위마다 커밋한다.
- 최종 PR 전에도 중간 커밋은 허용한다.

## Pipeline Sequence

표준 `delivery pipeline`은 아래 순서를 기본으로 한다.

1. `requirement-shaping`
2. `context-discovery`
3. `design-sync`
4. `work-bootstrap`
5. `implementation-cycle`
6. `test-authoring`
7. `quality-cycle`
8. `requirements-implementation-sync`
9. `full-test`
10. `troubleshooting-record` if needed
11. `implementation-doc-sync`
12. `backlog-capture`
13. `commit-delivery`
14. `pr-delivery`
15. `feedback-response`

## Job Definition

### `requirement-shaping`

- 요구사항을 상세화한다.
- 완료 기준, 비범위, 승인 기준을 정리한다.
- 필요 시 관련 계획 문서 초안을 만든다.

### `context-discovery`

- 기존 문서, 스택 문서, 프로젝트 문서, 연관 코드, 참고 자료를 탐색한다.
- 필요한 문서가 없으면 이후 단계에서 새로 만든다.

### `design-sync`

- 설계 문서 또는 기술 스펙 문서를 작성한다.
- 설계 검토를 수행한다.
- 검토 결과가 부적합이면 수정 후 재검토한다.
- 외부 승인 게이트가 없다면 내부 검토로 계속 진행한다.

### `work-bootstrap`

- 필요한 이슈를 만든다.
- 올바른 브랜치를 만든다.
- 필요한 프로젝트 컨테이너 문서 구조를 만든다.

### `implementation-cycle`

- 설계 기준으로 구현한다.
- 큰 작업은 하위 단위로 나눠 순차 구현한다.
- 중간에 트러블슈팅이 발생하면 sidecar 흐름으로 처리한다.

### `test-authoring`

- 변경 범위에 필요한 테스트를 작성하거나 갱신한다.
- 단위 테스트, 통합 테스트, 프론트엔드 테스트, E2E 중 필요한 것을 포함한다.

### `quality-cycle`

- 컴파일, 정적 검사, 테스트, 수동 검증, 리팩터링을 반복한다.
- 리팩터링 후에는 같은 검증을 다시 수행한다.

### `requirements-implementation-sync`

- 요구사항 문서, 설계 문서, 구현 결과가 일치하는지 점검한다.
- 설계와 구현이 어긋나면 둘 중 하나를 즉시 갱신한다.

### `implementation-doc-sync`

- 구현 결과를 프로젝트 `docs/`에 반영한다.
- API, ERD, architecture, domain-tech-spec, local-setup, security 같은 관련 문서를 갱신한다.

### `backlog-capture`

- 이번 작업에서 남겨진 후속 작업, TODO, 제약, 운영 메모를 남긴다.
- 같은 PR에서 하지 않을 항목도 문서로 남겨 추적 가능하게 한다.

### `commit-delivery`

- 설명 가능한 단위로 커밋을 나눈다.
- 각 커밋은 하나의 의도만 담는다.
- 검증 결과를 설명할 수 없는 커밋은 막는다.

### `feedback-response`

- PR 피드백이나 리뷰 코멘트를 반영한다.
- 반영 후 필요한 검증과 문서 동기화를 다시 수행한다.
- 모든 피드백이 정리되면 파이프라인을 종료한다.

## Documentation Outputs

파이프라인 진행 중 필요하면 아래 문서를 같이 남긴다.

- `project/<name>/plan/`
- `project/<name>/troubleshooting/`
- `project/<name>/docs/api/`
- `project/<name>/docs/architecture/`
- `project/<name>/docs/domain-tech-spec/`
- `project/<name>/docs/erd/`
- `project/<name>/docs/infrastructure/`
- `project/<name>/docs/local-setup/`
- `project/<name>/docs/security/`
- `project/<name>/docs/stack-selection/`
- `project/<name>/docs/references/`

## Exit Criteria

아래 조건이 만족되면 `delivery pipeline`을 완료로 본다.

- 요구사항과 구현이 충돌하지 않는다.
- 설계/구현/문서가 동기화되어 있다.
- 필요한 테스트와 검증이 끝났다.
- 재발 방지 가치가 있는 문제는 트러블슈팅 문서로 남겼다.
- 남은 작업은 backlog 또는 후속 문서로 남겼다.
- 커밋, 푸시, PR 또는 요청된 최종 산출물까지 완료했다.
