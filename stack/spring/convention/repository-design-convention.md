# Spring Repository Design Convention

## 목적

Spring Data JPA Repository를 단순 CRUD 통로가 아니라 **도메인 조회 계약**으로 작성한다.
Repository는 영속성 기술을 숨기되, 쿼리 의도와 반환 계약은 호출자가 오해하지 않도록 명확해야 한다.

## 적용 범위

- `JpaRepository` 기반 repository interface
- 파생 쿼리 메서드, `@Query`, `@EntityGraph`, `@Modifying`
- projection, pagination, existence/count query
- repository custom 구현 도입 기준

## 필수 규칙

1. Repository는 기본적으로 interface로 작성하고 `JpaRepository<Entity, Long>`을 상속한다.
2. Repository 이름은 `{Entity}Repository`로 작성한다.
3. 단건 조회는 nullable entity를 직접 반환하지 않고 `Optional<Entity>`를 사용한다.
4. 다건 조회는 `List`, `Page`, `Slice` 중 의도를 드러내는 타입을 사용한다.
5. 조회 조건이 2개 이하이고 조인이 없으면 파생 쿼리를 우선 사용한다.
6. 메서드명이 길어지거나 조인/정렬/집계/projection이 필요하면 `@Query`를 사용한다.
7. N+1 방지가 필요한 단순 연관 조회는 `@EntityGraph`를 우선 검토한다.
8. 쓰기 쿼리는 반드시 `@Modifying`과 트랜잭션 경계를 명확히 둔다.
9. Service는 `findById(...).orElseThrow(...)`로 부재 정책을 결정하고, Repository는 도메인 예외를 던지지 않는다.
10. 복잡한 동적 검색은 Repository interface에 억지로 넣지 않고 custom repository 또는 별도 query service로 분리한다.

## 패키지 배치

프로젝트가 도메인 중심 패키지를 쓰는 경우:

```text
content/
  domain/
    entity/
    repository/
```

프로젝트가 adapter 구조를 쓰는 경우:

```text
content/
  domain/
    repository/
  infra/
    persistence/
```

초기 MVP에서 Spring Data JPA interface만 쓰는 경우, 도메인별 `domain.repository`에 둔다.
Querydsl, JDBC, 외부 검색엔진 같은 구현 세부사항이 들어오면 `infra.persistence` 또는 `infra.search`로 분리한다.

## 메서드 반환 타입 규칙

| 상황 | 반환 타입 |
| --- | --- |
| PK/unique key 단건 조회 | `Optional<Entity>` |
| 반드시 존재해야 하는 값 | Repository가 아니라 Service에서 `orElseThrow` |
| 제한 없는 목록 | `List<Entity>` |
| 전체 개수와 페이지가 필요 | `Page<Entity>` |
| 다음 페이지 여부만 필요 | `Slice<Entity>` |
| 존재 여부 | `boolean` |
| 개수 | `long` |
| 조회 전용 화면 모델 | projection record/interface |

## 파생 쿼리 규칙

파생 쿼리는 짧고 명확할 때만 사용한다.

허용 예시:

```java
Optional<Member> findByEmail(String email);

boolean existsByEmail(String email);

List<Post> findTop20ByStatusOrderByPublishedAtDesc(PostStatus status);
```

피해야 하는 예시:

```java
List<Post> findByStatusAndCompanySlugAndJobCategoriesNameAndTopicTagsNameOrderByPublishedAtDesc(...);
```

위와 같이 조건이 길어지면 `@Query`, Specification, custom repository, search service 중 하나로 분리한다.

## `@Query` 사용 기준

다음 중 하나라도 해당하면 `@Query`를 사용한다.

- 조인이 필요하다.
- projection으로 바로 조회한다.
- 필터 조건이 많아 파생 메서드명이 읽기 어렵다.
- 정렬/집계/서브쿼리 의도가 메서드명만으로 드러나지 않는다.
- soft delete, visibility 같은 공통 조회 조건을 명시해야 한다.

규칙:

- JPQL을 기본으로 하고 native query는 DB 기능이 꼭 필요할 때만 사용한다.
- 파라미터는 위치 기반보다 `@Param` 이름 기반을 사용한다.
- `SELECT e` 형태의 entity 조회와 projection 조회를 혼합하지 않는다.
- projection record를 사용할 때는 생성자 표현식 또는 Spring Data projection 규칙을 명확히 따른다.

## Fetch 전략

- Entity mapping은 기본적으로 `LAZY`를 유지한다.
- 목록 API에서 모든 연관을 즉시 로딩하지 않는다.
- 단건 상세 조회에서 필요한 연관만 `@EntityGraph` 또는 fetch join으로 가져온다.
- pagination 대상 쿼리에는 collection fetch join을 기본적으로 금지한다.
- N+1 해결은 테스트나 쿼리 로그로 확인한다.

## 쓰기 쿼리 규칙

엔티티 상태 변경은 기본적으로 엔티티를 로드한 뒤 도메인 메서드를 호출한다.
대량 업데이트/삭제가 필요한 경우에만 `@Modifying`을 사용한다.

```java
@Modifying(clearAutomatically = true, flushAutomatically = true)
@Query("update Post p set p.status = :status where p.id = :postId")
int updateStatus(@Param("postId") Long postId, @Param("status") PostStatus status);
```

규칙:

- 반환 타입은 영향받은 row 수를 알 수 있도록 `int` 또는 `long`을 우선한다.
- `clearAutomatically`, `flushAutomatically` 필요 여부를 검토한다.
- 쓰기 쿼리 메서드는 호출 service에서 `@Transactional` 경계를 가진다.
- bulk update 이후 같은 transaction에서 stale entity를 재사용하지 않는다.

## Projection 규칙

- API 응답 전용 DTO를 repository가 직접 반환하지 않는다.
- repository projection은 조회 최적화 목적의 `*QueryDto`, `*Projection`, record를 사용한다.
- projection이 controller response로 직접 노출되면 안 된다.
- projection 필드는 화면/서비스 요구에 맞춰 최소화한다.

## Custom Repository 도입 기준

다음 경우에는 custom repository 또는 query service를 만든다.

- 동적 필터가 3개 이상 조합된다.
- OR/AND 그룹 조합이 복잡하다.
- 커서 페이지네이션, 검색 랭킹, 복합 정렬이 필요하다.
- Elasticsearch 등 다른 검색 저장소로 교체 가능해야 한다.

명명:

```text
PostRepository
PostRepositoryCustom
PostRepositoryImpl
```

Spring Data JPA custom 구현체 이름은 기본적으로 `{RepositoryInterfaceName}Impl`을 따른다.

## 테스트 기준

- 새 repository 메서드가 추가되면 최소 하나의 `@DataJpaTest`를 추가한다.
- 단순 `save/findById`만 있는 repository는 대표 smoke test로 묶는다.
- custom query, `@Query`, `@EntityGraph`, `@Modifying`, projection은 각각 repository test를 가진다.
- 테스트는 mock repository가 아니라 실제 DB 상태를 저장/조회해 검증한다.

## Checklist

- 단건 조회가 `Optional`인가?
- 파생 쿼리 메서드명이 과도하게 길지 않은가?
- 조인/복합 조건은 `@Query` 또는 custom repository로 분리했는가?
- pagination 쿼리에 collection fetch join이 들어가지 않았는가?
- `@Modifying` 쿼리의 transaction/stale entity 위험을 검토했는가?
- repository가 도메인 예외나 web DTO에 의존하지 않는가?
- repository test가 실제 DB 상태를 검증하는가?

## References

- [repository-test-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/test/repository-test-convention.md>)
- [layer-and-naming-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/layer-and-naming-convention.md>)
- [repository-interface-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/repository-interface-snippet.md>)
