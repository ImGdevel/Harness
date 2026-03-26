# Spring Test Fixture Convention

Tasteam 백엔드 위키의 테스트 픽스처 문서를 Spring 공통 하네스용으로 일반화한 문서다.
목적은 테스트 픽스처 작성과 사용 규칙을 표준화해 중복과 불안정성을 줄이는 것이다.

## Common Rule

- 공용 픽스처는 `src/testFixtures/java` 같은 공유 가능한 테스트 소스셋에 둔다.
- 모듈 간 공유는 테스트 전용 의존성으로만 연결한다.
- 픽스처 클래스는 상태를 가지지 않는 `final` 유틸리티로 유지한다.

## Naming

- 클래스명: `대상 + Fixture`
- 기본 상수: `DEFAULT_`
- 변경 상수: `UPDATED_`

예:

- `PostFixture`
- `MemberFixture`
- `OrderRequestFixture`
- `PostQueryDtoFixture`

## Method Naming

- 엔티티: `create(...)`, `createWithId(...)`
- 상태가 있는 엔티티: `createCompleted()`, `createCanceled()`
- 요청 DTO: `createRequest()`, `updateRequest()`
- 실패 케이스: `createRequestWithoutXxx()`, `createRequestWithInvalidXxx()`

## Layer Rule

### Domain Test

- 테스트 대상 엔티티는 가능하면 실제 팩토리로 직접 생성한다.
- 협력 엔티티만 fixture를 쓴다.

### Repository Test

- 저장 전 엔티티는 fixture로 생성한다.
- 복잡한 초기 상태를 fixture 조합으로 표현하되, 본문에서는 핵심 차이만 보이게 한다.

### Service Test

- Given 단계에서 request/entity fixture를 적극 사용한다.
- Then 단계 응답 검증은 핵심 필드를 직접 assert한다.

### WebMvc Test

- Request DTO는 fixture를 사용한다.
- Response는 `jsonPath`로 계약을 직접 검증한다.

### Integration Test

- Given은 fixture + 실제 repository 저장
- Then은 실제 repository 조회나 핵심 응답 필드로 검증

## When To Add A Fixture

- 같은 객체를 두 번 이상 생성해야 할 때
- Given 절이 길어질 때
- 여러 테스트와 레이어에서 같은 기본 상태를 반복할 때

## What Fixtures Should Not Do

- 비즈니스 규칙을 대신 구현하지 않는다.
- 복잡한 정책 판단을 숨기지 않는다.
- 테스트 의도를 가리도록 지나치게 많은 오버로드를 만들지 않는다.

## Review Checklist

- fixture가 유효한 기본 상태를 제공하는가
- 비즈니스 로직을 숨겨 넣지 않았는가
- 테스트 본문이 fixture 때문에 더 읽기 어려워지지 않았는가
- 레이어별 사용 규칙을 어기지 않았는가
