# Spring Flyway Convention

Tasteam 백엔드 위키의 Flyway 규약을 Spring 공통 하네스용으로 일반화한 문서다.
목적은 DB 변경을 예측 가능하고 재현 가능하게 만들어 마이그레이션 충돌과 운영 장애를 줄이는 것이다.

## Directory Rule

권장 구조:

```text
src/main/resources/db/migration/   # SQL migration
src/main/java/db/migration/        # Java migration
```

- SQL migration은 `db/migration` 아래에 둔다.
- Java migration은 `db.migration` 패키지에 둔다.

## File Naming

### Versioned SQL

- 형식: `VyyyyMMddHHmmss__short_description.sql`
- 예: `V20260307183000__add_member_profile_image.sql`

규칙:

- 타임스탬프는 팀 표준 타임존 기준 14자리 초 단위를 사용한다.
- 설명은 `lower_snake_case`를 사용한다.
- 한 파일에는 한 목적만 담는다.

### Repeatable SQL

- 형식: `R__short_description.sql`
- 예: `R__refresh_materialized_views.sql`

규칙:

- 여러 번 실행되어도 같은 결과가 나오는 방식으로 작성한다.

### Java Migration

- 클래스명도 SQL과 같은 패턴을 따른다.
- 예:
  - `V20260307183000__add_member_profile_image`
  - `R__sync_enum_check_constraints`

## Version Strategy

- 기본 전략은 타임스탬프 버전이다.
- 같은 시각에 여러 파일이 필요하면 초 단위를 조정하거나 suffix를 명시한다.
- 이미 배포된 버전 파일은 수정하지 않는다.

## SQL Writing Rule

- DDL과 DML은 가능하면 분리한다.
- 제약 이름은 명시적으로 작성한다.
- 지원되는 DB라면 `IF EXISTS`, `IF NOT EXISTS`를 적극 활용한다.
- 대용량 테이블 변경은 락 범위와 다운타임을 먼저 검토한다.

## Transaction Rule

- 기본은 트랜잭션 migration이다.
- 비트랜잭션 실행이 필요한 문장은 파일 상단에 명시한다.

예:

```sql
-- flyway:transactional=false
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_member_email ON member (email);
```

## Data Migration Rule

- 백필은 가능하면 별도 버전 파일로 분리한다.
- 대용량 업데이트는 배치/분할 처리 전략을 검토한다.
- 삭제성 작업은 사전 검증 쿼리와 복구 전략을 함께 설계한다.

## Java Migration Rule

Java migration은 아래 상황에서만 쓴다.

- SQL이 enum/설정값 기반으로 동적으로 생성되어야 하는 경우
- 런타임 계산 또는 코드 기반 분기가 필요한 경우

기본 구조 예시:

```java
package db.migration;

import java.sql.Statement;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

public class R__example extends BaseJavaMigration {
    @Override
    public void migrate(Context context) throws Exception {
        try (Statement stmt = context.getConnection().createStatement()) {
            stmt.execute("ALTER TABLE ...");
        }
    }
}
```

## Schema Change Strategy

권장 순서:

1. Backward compatible 변경 추가
2. Backfill
3. 코드 전환
4. 필요 시 제거를 별도 단계로 수행

컬럼 제거와 제약 강화는 한 번에 끝내지 않는다.

## Review Checklist

- 파일명과 버전이 컨벤션에 맞는가
- 변경이 단일 목적에 집중되어 있는가
- 대용량 테이블 락과 성능 이슈를 검토했는가
- 롤백 또는 대체 migration 전략이 있는가
- 적용 이후 코드 전환 순서가 문서화되어 있는가

## Forbidden Pattern

- 이미 적용된 versioned migration 수정
- 운영 DB 수동 SQL 실행을 기본 흐름으로 삼는 것
- 원인 분석 없이 `flyway repair`를 남용하는 것
