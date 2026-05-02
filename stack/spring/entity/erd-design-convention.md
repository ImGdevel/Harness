# Spring ERD Design Convention

## 목적

ERD를 통해 테이블 경계와 관계 방향을 먼저 정하고, 물리 스키마를 예측 가능한 형태로 고정한다.

## 기본 규칙

- 각 테이블은 하나의 책임만 갖는다.
- 관계는 도메인 의미가 분명한 경우만 만든다.
- 도메인 경계별로 ERD를 분리해 추적 가능성을 높인다.
- 테이블/컬럼 명명은 `snake_case`.
- 프로젝트 단위로 단수/복수명 규칙을 통일한다.
- PK는 기본적으로 `id`.
- FK는 `{target}_id`.
- 시간 컬럼은 `{action}_at`.
- 상태는 `status` 또는 `{concept}_type`.
- 프로젝트당 하나의 PK 전략 유지.
- FK 타입은 대상 PK 타입과 일치.
- `ENUM` 문자열 저장 시 해당 코드 길이를 고려한 크기 선언.

## 관계 모델링 규칙

### 기본 관계 패턴

- `N:1` 은 다대일에서 외래키를 가진 쪽이 연산 주체를 가진다.
- 다대다는 기본적으로 금지하고 **join entity**로 분해한다.
- 단방향 설계를 기본으로 하고 양방향은 운영상 필요성이 명확할 때만 사용한다.
- 다수의 조회 경로가 필요한 경우, 양방향 대신 쿼리(조인)에서 필요로 하는 경로를 추가한다.

### 조인/연결 테이블 판단

`post_like`와 같이 `(A_id, B_id)`가 고유성의 본질인 경우:

- 쓰기 빈도가 높고 조회 중심이 간단하면 `@EmbeddedId` + `@MapsId`를 고려
- 다른 테이블에서 해당 조인 테이블을 FK로 참조해야 하면 단일 PK + unique 제약으로 전환

연결 테이블의 기본 컬럼:

- `x_id` + `y_id` (둘 다 NOT NULL, 각 FK)
- `created_at` (선택: `updated_at` 필요 여부는 운영 정책)
- 필요 시 `is_deleted`(soft delete) 또는 상태 컬럼

## 무결성 정책

- FK 제약/삭제 규칙은 프로젝트별로 한 번 정하고 문서화한다.
- soft delete 기본값이면 조회 정책(기본 `where is_deleted = false`)을 repository/쿼리 정책으로 일치.
- hard delete면 배치 삭제 순서, FK 종속 순서를 문서화.

## 감사/삭제 정책

- 운영 테이블은 기본 감사 컬럼을 두거나, BaseEntity 상속 정책으로 통일한다.
- soft delete 사용 시 복구 정책(restore 가능 여부)도 ERD 단계에서 기록한다.

## 네이밍 확장 규칙

- 인덱스명: `idx_<table>_<column_list>`
- 유니크명: `uk_<table>_<column_list>`
- FK명: `fk_<from>_<to>`
- 조인테이블 명: `<left_table>_<right_table>` 또는 정책에 맞는 고정 규칙

## Checklist

- 각 테이블이 단일 책임을 갖는가?
- 관계 의미가 비즈니스로 정당한가?
- PK/FK 타입이 일관적인가?
- 이름 규칙과 delete 정책이 문서화되어 있는가?
- 조인테이블의 PK/UK 선택이 의도와 일치하는가?
- 조회/삭제 정책이 일관성 있게 반영되는가?

## References

- [entity-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/entity/entity-design-convention.md>)
