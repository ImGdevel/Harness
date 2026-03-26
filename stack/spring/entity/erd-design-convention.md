# Spring ERD Design Convention

Tasteam 백엔드 위키의 ERD 설계 규약을 Spring 공통 하네스용으로 일반화한 문서다.
목적은 ERD와 물리 스키마 설계에서 팀이 따를 구조적 기준을 명확히 하는 것이다.

## Design Philosophy

- ERD는 비즈니스 개념을 구조로 표현하는 도구다.
- 테이블은 단순 저장소가 아니라 도메인 개체다.
- 관계는 기술적 편의보다 업무 의미를 우선한다.

## Basic Principle

- 테이블은 하나의 책임만 가진다.
- 관계는 최소화하되 의미가 분명해야 한다.
- ERD는 도메인 단위로 구획한다.
- 예외 설계는 허용하되 반드시 문서로 남긴다.

## Table Naming

- 테이블명은 기본적으로 `snake_case`를 사용한다.
- 단수형/복수형은 프로젝트 단위로 고정하고 혼용하지 않는다.
- 의미 없는 접두사/접미사(`tbl_`, `data_`, `info_`)는 피한다.

권장 예:

- 기본 엔티티: `member`, `group`, `restaurant`
- 조인 테이블: `group_member`, `chat_room_member`
- 이벤트/요청 테이블: `group_join_request`, `notification_event`

## Column Naming

| Type | Rule | Example |
| --- | --- | --- |
| PK | `id` | `id` |
| FK | `{target}_id` | `member_id` |
| Time | `{action}_at` | `created_at`, `joined_at` |
| Status | `status` | `status` |
| Type | `{concept}_type` | `message_type` |

축약어는 장기적으로 해석 비용을 높이므로 가능한 한 피한다.

## Key Strategy

- 기본 PK 타입은 `BIGINT` 단일 PK를 우선 검토한다.
- 생성 전략은 프로젝트 DB 정책에 맞게 고정한다.
- 관계 테이블은 복합 PK 또는 복합 UNIQUE를 우선 검토한다.

단일 PK + UNIQUE를 허용할 수 있는 경우:

- 관계 자체가 독립 생명주기를 가진다
- 추가 메타 컬럼이 많이 붙는다
- ORM 구현 복잡도 대비 운영 이점이 더 크다

## FK And Referential Integrity

- FK 컬럼명은 `{target}_id`를 사용한다.
- 참조 대상 PK와 타입을 맞춘다.

물리 FK 사용 여부는 프로젝트 성격에 따라 정한다.

- 강한 정합성 우선 프로젝트면 물리 FK를 적극 사용한다.
- 배치/마이그레이션 유연성을 우선하면 애플리케이션 무결성 + 인덱스 + 문서 규칙으로 대체할 수 있다.

중요한 것은 정책을 문서로 고정하는 것이다.

## Naming Collision Rule

- 프레임워크 핵심 개념과 충돌하는 이름은 피한다.
- 예를 들어 Spring Security의 `User`와 혼동이 크면 더 구체적인 도메인 용어를 사용한다.

## Review Checklist

- 테이블 책임이 하나로 설명되는가
- 관계가 업무 의미를 가지는가
- 테이블/컬럼명이 일관된 네이밍 규칙을 따르는가
- PK/FK 전략이 프로젝트 정책과 충돌하지 않는가
- FK 사용 여부와 무결성 책임 위치가 문서화되어 있는가
