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

## Authoritative Source

- 정확한 `job` 구성과 실행 순서는 `common/spec/workflow-catalog.md`의 `delivery-pipeline` 등록 항목만 따른다.
- 이 문서는 장시간 실행 규칙, 중단 조건, 루프 정책, 산출물 원칙만 정의한다.
- 여기서 별도의 `job`을 추가하거나 순서를 다시 정의하지 않는다.
- 커밋, 푸시, PR 생성은 별도 `delivery job`이 아니라 `pr-delivery`에 포함된다.

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

## Runtime Semantics

- 초반 구간에서는 요구사항 정리, 문맥 탐색, 계획 저장이 먼저 이뤄져야 한다.
- 설계와 구현은 분리된 채로 오래 남아 있으면 안 되며, 구현 전에 설계 안정화 루프를 먼저 돈다.
- 구현 이후에는 테스트 작성, 품질 검증, 요구사항-설계-구현 교차 검증이 이어져야 한다.
- 트러블슈팅은 조건부 sidecar로 실행하고, 해결 후 원래 파이프라인으로 복귀한다.
- 문서 동기화와 backlog 기록은 전달 직전에 몰아서 빼먹지 말고, 실제 변경 근거가 생긴 시점에 갱신한다.
- 최종 전달 단계는 `pr-delivery`가 맡으며, 그 안에서 커밋, 푸시, PR 초안/생성이 함께 처리된다.
- 피드백이 들어오면 `feedback-response` 이후 필요한 검증과 문서 동기화를 다시 수행한다.

## Documentation Outputs

파이프라인 진행 중 필요하면 아래 문서를 같이 남긴다.

- `<project-root>/plan/`
- `<project-root>/troubleshooting/`
- `<project-root>/docs/api/`
- `<project-root>/docs/architecture/`
- `<project-root>/docs/domain-tech-spec/`
- `<project-root>/docs/erd/`
- `<project-root>/docs/infrastructure/`
- `<project-root>/docs/local-setup/`
- `<project-root>/docs/security/`
- `<project-root>/docs/stack-selection/`
- `<project-root>/docs/references/`

## Exit Criteria

아래 조건이 만족되면 `delivery pipeline`을 완료로 본다.

- 요구사항과 구현이 충돌하지 않는다.
- 설계/구현/문서가 동기화되어 있다.
- 필요한 테스트와 검증이 끝났다.
- 재발 방지 가치가 있는 문제는 트러블슈팅 문서로 남겼다.
- 남은 작업은 backlog 또는 후속 문서로 남겼다.
- 커밋, 푸시, PR 또는 요청된 최종 산출물까지 완료했다.
