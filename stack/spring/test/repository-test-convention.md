# Spring Repository Test Convention

Tasteam 백엔드 위키의 Repository 테스트 문서를 Spring 공통 하네스용으로 일반화한 문서다.
대상은 JPA 중심의 Repository 테스트이며, 핵심은 매핑·쿼리·트랜잭션 검증에 집중하는 것이다.

## Role

Repository 테스트는 아래를 우선 검증한다.

- 조건, 정렬, 페이징, 조인
- 연관관계 저장/조회
- 제약조건 예외
- N+1 위험이 큰 조회 규칙
- `@Modifying` 쿼리의 부작용

## Preferred Test Environment

- `@DataJpaTest` 기반 슬라이스 테스트를 우선한다.
- QueryDSL, auditing 등 실제 프로젝트에서 필요한 최소 설정만 import한다.
- 테스트 DB는 프로젝트 정책에 맞게 H2 또는 Testcontainers를 쓴다.

핵심은 서비스/컨트롤러/보안 빈을 띄우지 않고 JPA 계층에 집중하는 것이다.

## High Value Cases

### Custom Query

- WHERE 조건이 기대대로 적용되는가
- 정렬과 페이징이 맞는가
- 조인 때문에 누락/중복이 생기지 않는가

### Relation Mapping

- cascade가 맞게 동작하는가
- orphan removal이 필요한 대로 동작하는가
- 양방향 연관관계가 깨지지 않는가

### Constraint Failure

- unique / not null / check 제약 위반 시 예외가 발생하는가

### Counter / State Update Query

- 영향 row 수와 실제 재조회 값이 맞는가
- 경계값에서 0 이하로 내려가지 않는가

## What Repository Tests Do Not Cover

- 서비스 정책 로직
- 컨트롤러 요청/응답 포맷
- 보안 설정과 필터 체인
- 전체 애플리케이션 통합 흐름

## Writing Pattern

### Save And Find

- 새 필드나 새 연관관계가 추가되면 저장/조회 스모크 테스트를 하나 둔다.
- 기본 save/find가 깨지지 않는지 빨리 감지하는 용도다.

### Query Method Test

- 메서드 하나당 대표 시나리오 1~2개로 유지한다.
- 구현 방식보다 도메인 규칙을 검증한다.

예:

- 본인 댓글만 조회되는가
- soft deleted row가 제외되는가

### Delete / Cascade Test

- 부모 삭제 시 자식이 어떻게 되는지
- 삭제되면 안 되는 엔티티가 남는지

## Fixture Rule

- 저장 전 엔티티는 fixture로 생성해도 된다.
- 결과 검증은 DB에서 재조회한 실제 값으로 한다.
- Repository 테스트에서는 stub/fake repository를 쓰지 않는다.

## Review Checklist

- 이 테스트가 쿼리 결과와 매핑 규칙을 검증하는가
- 서비스/컨트롤러 책임이 섞이지 않았는가
- 경계 케이스가 최소 한 번은 검증되는가
- 구현 방식이 아니라 도메인 결과를 검증하는가
