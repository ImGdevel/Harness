# Spring Table Definition Writing Guide

Tasteam 백엔드 위키의 테이블 정의서 작성 가이드를 Spring 공통 하네스용으로 일반화한 문서다.
목적은 테이블 정의서를 처음 읽는 사람도 설계 의도와 데이터 수명주기를 이해할 수 있게 만드는 것이다.

## What A Table Definition Should Explain

DDL만으로는 설계 의도와 책임 범위를 설명할 수 없다.
테이블 정의서는 최소한 아래 질문에 답해야 한다.

- 이 테이블은 어떤 문제를 해결하기 위해 존재하는가
- 비슷한 다른 테이블과 역할이 어떻게 다른가
- 왜 이런 컬럼 구조를 선택했는가
- 데이터가 누적되는가, 최신 값으로 갱신되는가

## Required Metadata

모든 테이블 정의서는 아래 항목을 포함한다.

### Table Name

- 실제 DB 테이블명과 동일해야 한다.
- `snake_case`를 사용한다.

### Description

- 1~2줄로 “무슨 데이터인가”를 설명한다.
- 구현 방식 설명은 여기서 늘어놓지 않는다.

### Responsibility

- 이 테이블이 무엇을 담당하는지와 무엇을 담당하지 않는지를 적는다.

### Lifecycle

- 언제 생성되고 언제까지 유효한지 적는다.
- 누적형인지, 갱신형인지, 보관 정책이 있는지 적는다.

### Deletion Policy

- 삭제 시점과 삭제 방식을 적는다.
- hard delete인지 soft delete인지 분명히 한다.

### Main Query Patterns

- 실제 서비스 조회 패턴을 기준으로 적는다.
- “주로 무엇으로 찾는가”를 문장으로 설명한다.

### Constraints

- 컬럼 표만으로 표현되지 않는 논리 제약을 적는다.
- 복합 unique, 비즈니스 검증, 애플리케이션 레벨 강제 규칙이 여기에 들어간다.

### Indexes

- 주요 조회 패턴을 근거로 필요한 최소한의 인덱스를 적는다.

### Design Rationale And Future Change

- 논쟁이 있었던 설계
- 트레이드오프
- 향후 변경 가능성이 있는 결정

이 항목을 남겨야 이후 변경 시 의사결정을 복구할 수 있다.

## Column Table Rule

권장 컬럼 표 항목:

| Item | Rule |
| --- | --- |
| Column | `snake_case` |
| Type | 실제 DB 타입 기준 |
| Nullable | 반드시 명시 |
| Key | `PK`, `FK`, `-` |
| Unique | `Y`, `N` |
| Default | `DEFAULT`, `IDENTITY`, `-` |
| Note | 비즈니스 제약과 의미 위주로 작성 |

## Writing Principle

- 모든 컬럼은 왜 존재하는지 설명 가능해야 한다.
- NULL 허용 여부, 기본값, 길이 제한 모두 의도가 있어야 한다.
- SQL을 모르는 사람도 이해할 수 있는 설명을 포함한다.

## Review Checklist

- 처음 보는 사람이 문서만 읽고 테이블 목적을 이해할 수 있는가
- 생성/변경/삭제 라이프사이클이 설명되어 있는가
- 주요 조회 패턴과 인덱스가 연결되어 있는가
- 컬럼별 비즈니스 의미가 빠져 있지 않은가
- 향후 확장성 또는 설계 트레이드오프가 남아 있는가
