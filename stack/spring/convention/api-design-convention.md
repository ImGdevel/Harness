# Spring API Design Convention

Tasteam 백엔드 위키의 API 설계 규약을 Spring 공통 하네스용으로 일반화한 문서다.
목적은 API 설계와 구현에서 요청/응답/에러/페이징 규칙을 고정해 인터페이스 일관성을 유지하는 것이다.

## Common Base

- Base URL은 프로젝트 단위로 고정한다.
- Content-Type은 기본적으로 `application/json; charset=utf-8`을 사용한다.
- 인증 API는 `Authorization: Bearer {accessToken}` 같은 표준 헤더 방식을 따른다.
- 시간 표현은 ISO-8601로 통일한다.
- 서비스 표준 타임존이 있으면 문서에 명시한다.

## HTTP Method Rule

| Method | Rule |
| --- | --- |
| `GET` | 서버 상태를 변경하지 않는다 |
| `POST` | 새 리소스 생성 또는 작업 생성에 사용한다 |
| `PUT` | 리소스 전체 상태 교체에 사용한다 |
| `PATCH` | 전달된 필드만 수정한다 |
| `DELETE` | 리소스를 제거한다. soft delete는 도메인 규칙으로 허용할 수 있다 |

## Success Response Rule

### Single Object

```json
{
  "data": {}
}
```

### Created Resource

```json
{
  "data": {
    "id": 123
  }
}
```

### No Content

- 삭제, 상태 전이, 토큰 폐기처럼 본문이 필요 없으면 `204 No Content`를 사용한다.

## Error Response Rule

기본 포맷:

```json
{
  "code": "MEMBER_NOT_FOUND",
  "message": "회원 정보를 찾을 수 없습니다.",
  "errors": {
    "memberId": 123
  }
}
```

Validation 에러 예시:

```json
{
  "code": "INVALID_REQUEST",
  "message": "요청 값이 올바르지 않습니다.",
  "errors": [
    { "field": "email", "reason": "INVALID_FORMAT" },
    { "field": "size", "reason": "OUT_OF_RANGE" }
  ]
}
```

분리 원칙:

- HTTP status는 프로토콜/리소스 상태를 나타낸다.
- `error.code`는 도메인 의미를 나타낸다.

## Pagination / Sorting / Filtering

### Pagination

- 목록 조회는 기본적으로 pagination을 사용한다.
- Page 기반과 Cursor 기반은 API 하나에서 혼용하지 않는다.

Page 예시:

```text
GET /api/v1/admin/users?page=1&size=20
```

Cursor 예시:

```text
GET /api/v1/reviews?cursor=opaque&size=10
```

### List Response

Cursor 기반:

```json
{
  "items": [],
  "pagination": {
    "nextCursor": "opaque",
    "size": 10,
    "hasNext": true
  }
}
```

Page 기반:

```json
{
  "items": [],
  "pagination": {
    "page": 1,
    "size": 10,
    "totalPages": 5,
    "totalElements": 87
  }
}
```

### Sorting

- 외부 파라미터는 가능한 단순하게 유지한다.
- 기본 정렬 기준은 API 문서에 반드시 명시한다.
- Cursor 기반이면 내부 정렬 안정성까지 고려해 tie-breaker 컬럼을 함께 설계한다.

### Filtering

- Query parameter는 의미가 드러나는 이름을 사용한다.
- 숫자 코드나 JSON 문자열을 파라미터로 우겨 넣지 않는다.

권장 예:

- `status=ACTIVE`
- `createdFrom=2026-01-01`
- `createdTo=2026-01-31`
- `isDeleted=false`

### Search Split Rule

- 단순 조건 조합: `GET /resources`
- 복잡한 조합/DSL: `POST /resources/search`

## PUT / PATCH Rule

- `PUT`: 전체 교체. 누락 필드를 초기화로 해석할 수 있다.
- `PATCH`: 부분 수정. 전달된 필드만 반영한다.
- 프로젝트가 JSON Merge Patch를 채택하면 `null` 의미도 함께 문서화한다.

## Security Rule

- 외부 API와 내부 운영 API의 경로를 분리한다.
- 인증 방식, 토큰 저장 전략, 리프레시 정책은 별도 보안 문서와 함께 관리한다.

## Review Checklist

- 메서드 의미와 URI가 충돌하지 않는가
- 성공/에러 응답 포맷이 프로젝트 표준과 일치하는가
- Validation 에러와 비즈니스 에러가 뒤섞이지 않는가
- Page/Cursor 전략이 한 API에서 혼용되지 않는가
- `PUT`를 부분 수정 용도로 잘못 쓰지 않았는가
