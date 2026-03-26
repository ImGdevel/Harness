# Spring Layer And Naming Convention

Tasteam 백엔드 위키의 DTO, 레이어, 네이밍 규칙을 Spring 공통 하네스용으로 일반화한 문서다.
역할과 경계가 이름에 드러나도록 만들어 코드 탐색 비용을 낮추는 데 목적이 있다.

## DTO Rule

### Request DTO

- 의미: HTTP 입력을 서비스가 이해할 수 있는 형태로 전달한다.
- 네이밍: `{Domain}{UseCase}Request`
- 예:
  - `PostCreateRequest`
  - `MemberUpdateRequest`
  - `PageSortRequest`

### Response DTO

- 의미: 컨트롤러 최종 응답 계약을 담는다.
- 네이밍: `{Domain}{UseCase}Response`
- 예:
  - `PostSummaryResponse`
  - `MemberProfileResponse`

### Query Condition / Query DTO

- `*Condition`: 조회 조건 입력
- `*QueryDto`: 조회 결과 projection

예:

- `PostSearchCondition`
- `MemberSearchCondition`
- `PostSummaryQueryDto`
- `MemberProfileQueryDto`

## Package Placement

권장 예시:

```text
application.<context>.dto.request
application.<context>.dto.response
domain.<context>.dto
domain.<context>.repository
domain.<context>.repository.impl
```

## Conversion Method Naming

- `toXxx()`: 현재 객체를 다른 타입으로 변환
- `fromXxx(...)`: 특정 입력 타입에서 응답/조회 모델 생성
- `of(...)`: 대표 생성 규칙이 있는 정적 팩토리
- `empty()`: 비어 있는 조건 또는 기본 객체 생성

예:

- `PageSortRequest.toPageable()`
- `PostSummaryResponse.fromDto(...)`
- `PostSearchCondition.of(...)`
- `PostSearchCondition.empty()`

## Validator And Policy

형식 검증과 비즈니스 규칙 검증은 분리한다.

- `Validator`: 형식, 필수값, 범위, 존재성 검증
- `Policy`: 소유권, 상태 전이, 한도, 금지 규칙 검증

권장 패키지:

```text
application.<context>.validator
domain.<context>.policy
```

권장 네이밍:

- `*Validator`
- `*Policy`
- `validate(...)`
- `validateCanXxx(...)`
- `shouldXxx(...)`

권장 호출 순서:

1. Validator로 입력 검증
2. Policy로 도메인 규칙 검증
3. Entity는 불변식 유지

## Security And Infra Naming

- 기존 Spring Security 타입을 확장하거나 구현할 때만 `Custom` 접두어를 사용한다.
- 신규 컴포넌트는 역할 중심 이름을 사용한다.

예:

- `CustomAuthenticationEntryPoint`
- `CustomAccessDeniedHandler`
- `FilterChainExceptionFilter`
- `LoginSuccessHandler`

## Pagination Contract Rule

- 페이지 요청 DTO와 응답 DTO를 공통 모델로 표준화한다.
- 컨트롤러에서 웹 요청 DTO를 `Pageable` 같은 내부 타입으로 변환하고, 서비스는 웹 레이어 DTO에 의존하지 않는다.
- 페이지 응답 키는 프로젝트 단위로 고정하고 재사용한다.

예:

- 요청: `PageSortRequest`
- 응답: `PageResponse<T>`

## Review Checklist

- 클래스명만 보고 역할과 레이어가 드러나는가
- `Condition`과 `QueryDto`가 뒤바뀌지 않았는가
- Validator가 비즈니스 정책을 품고 있지 않은가
- Policy가 Request DTO 같은 웹 타입에 직접 의존하지 않는가
- Controller가 변환 책임을 넘겨서 Service가 웹 타입을 알게 만들지 않았는가
