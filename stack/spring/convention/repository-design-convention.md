# Spring Repository Design Convention

## 목적

Spring Data JPA Repository를 단순 CRUD 통로가 아니라 **도메인 조회 계약**으로 작성한다.
Repository는 영속성 기술을 숨기되, 쿼리 의도, 반환 타입, pagination/count 비용, 정렬 허용 범위를 호출자가 오해하지 않도록 명확하게 드러내야 한다.

## 참고 구현

하네스 문서를 작성할 때는 다음 레퍼런스 저장소의 실제 구현과 문서를 함께 확인한다.

- `C:\Users\imdls\workspace\KakaobootTechCamp\3-devon-woo-community`
- `docs/QUERYDSL_USAGE.md`
- `docs/QUERYDSL_ADVANCED_USAGE.md`
- `docs/PAGINATION_CONVENTION.md`
- `domain/common/repository/QueryDslSupport.java`
- `domain/common/repository/QueryDslOrderUtil.java`
- `domain/post/repository/PostRepository.java`
- `domain/post/repository/PostQueryRepository.java`
- `domain/post/repository/impl/PostRepositoryImpl.java`

## 적용 범위

- `JpaRepository` 기반 repository interface
- Spring Data 파생 쿼리 메서드
- JPQL `@Query`
- native query
- QueryDSL custom repository
- projection DTO
- pagination, sorting, count query
- `@EntityGraph`, fetch join, `@Modifying`
- repository test

## 기본 선택 순서

아래 순서로 가장 단순한 구현을 선택한다.

1. 기본 CRUD: `JpaRepository` 기본 메서드
2. 단순 단건/중복/짧은 조건: Spring Data 파생 쿼리
3. 고정 조인/고정 projection/고정 bulk update: JPQL `@Query`
4. 동적 필터/동적 정렬/복잡한 OR/AND/페이징 count 최적화: QueryDSL
5. DB 전용 기능, optimizer hint, CTE, window function, full-text/vector/json/array 연산: native query
6. 검색엔진/외부 저장소 전환 가능성이 큰 검색: repository가 아니라 별도 search adapter

## 패키지 배치

도메인 중심 구조:

```text
post/
  entity/
  dto/
  repository/
    PostRepository.java
    PostQueryRepository.java
    impl/
      PostRepositoryImpl.java
```

프로젝트가 `domain` 패키지를 한 단계 더 두는 경우:

```text
content/
  domain/
    entity/
  repository/
    ArchivedPostRepository.java
    ArchivedPostQueryRepository.java
    impl/
      ArchivedPostRepositoryImpl.java
```

초기 MVP에서 Spring Data JPA interface만 쓰는 경우에는 도메인별 `repository` 아래에 둔다.
QueryDSL 구현 세부사항이 추가되면 같은 `repository` 경계 안의 `impl` 하위 패키지로 분리한다.
JDBC, Elasticsearch, 외부 API 같은 저장소 구현이 섞이면 `infra.persistence` 또는 `infra.search`로 분리한다.

## 이름 규칙

| 대상 | 이름 |
| --- | --- |
| 기본 repository | `{Entity}Repository` |
| QueryDSL/custom query 계약 | `{Entity}QueryRepository` |
| QueryDSL/custom query 구현 | `{Entity}RepositoryImpl` |
| 조회 projection | `{Entity}{UseCase}QueryDto` |
| 검색 조건 객체 | `{Entity}SearchCondition`, `{Entity}QueryCondition` |
| 공통 QueryDSL 지원 | `QueryDslSupport`, `QueryDslOrderUtil` |

기본 형태:

```java
public interface PostRepository extends JpaRepository<Post, Long>, PostQueryRepository {
}
```

```java
public interface PostQueryRepository {
    Page<PostSummaryQueryDto> findAllActiveWithMemberAsDto(Pageable pageable);
}
```

```java
@Repository
@RequiredArgsConstructor
public class PostRepositoryImpl implements PostQueryRepository {
    private final JPAQueryFactory queryFactory;
}
```

규칙:

- QueryDSL 계약 이름은 `*QueryRepository`를 우선한다.
- 구현체는 Spring Data repository 조립 기준에 맞춰 `{Entity}RepositoryImpl`로 둔다.
- 구현체가 늘어나고 fragment 단위 조립이 필요하면 `{FragmentInterfaceName}Impl` 전환을 ADR로 남긴다.
- `Custom`이라는 이름은 레거시나 외부 프레임워크 확장 의미가 아니라면 쓰지 않는다.

## Repository 메서드 작성 규칙

### 반환 타입

| 상황 | 반환 타입 |
| --- | --- |
| PK/unique key 단건 조회 | `Optional<Entity>` |
| 반드시 존재해야 하는 값 | Repository가 아니라 Service에서 `orElseThrow` |
| 제한 없는 목록 | `List<Entity>` |
| 전체 개수와 페이지가 필요 | `Page<T>` |
| 다음 페이지 여부만 필요 | `Slice<T>` |
| cursor/keyset 목록 | `Slice<T>` 또는 별도 cursor response |
| 존재 여부 | `boolean` |
| 개수 | `long` |
| 조회 전용 화면 모델 | `*QueryDto` record/class |
| bulk update/delete | 영향받은 row 수 `int` 또는 `long` |

### 메서드 prefix

| 의도 | prefix |
| --- | --- |
| 단건 조회 | `findBy`, `findWith...By` |
| 목록 조회 | `findAll...`, `findBy...` |
| projection 목록 | `find...AsDto`, `search...AsDto` |
| 검색 | `search`, `searchBy...` |
| 존재 여부 | `existsBy` |
| 개수 | `countBy` |
| bulk update | `update...`, `increment...`, `decrement...` |
| bulk delete | `delete...InBulk`, `deleteBy...` |

### 파라미터 규칙

- entity 자체가 필요한 저장은 service에서 entity를 구성한 뒤 `save`한다.
- 조회 조건은 primitive field, ID, slug, condition object를 사용한다.
- 연관 엔티티의 ID/slug를 파생 쿼리로 탐색할 때는 `_` 구분자를 사용한다.

```java
Optional<CompanySubscription> findBySubscriber_IdAndCompany_Slug(Long subscriberId, String companySlug);
```

- web request DTO를 repository 파라미터로 넘기지 않는다.
- query condition은 repository/application 경계에서 쓰는 내부 타입으로 둔다.

## 파생 쿼리 규칙

파생 쿼리는 짧고 명확할 때만 사용한다.

허용:

```java
Optional<Member> findByEmail(String email);

boolean existsByEmail(String email);

List<Post> findTop20ByStatusOrderByPublishedAtDesc(PostStatus status);
```

주의:

```java
Page<Post> findDistinctByTopicTags_SlugAndVisibilityStateOrderByPublishedAtDesc(
        String tagSlug,
        VisibilityState visibilityState,
        Pageable pageable
);
```

위 정도는 MVP에서 허용 가능하지만, 조건이 더 늘거나 OR/AND 그룹이 생기면 QueryDSL로 전환한다.

금지:

```java
List<Post> findByStatusAndCompanySlugAndJobCategoriesNameAndTopicTagsNameOrderByPublishedAtDesc(...);
```

전환 기준:

- 조건이 3개 이상 조합된다.
- method name이 한 줄에서 읽히지 않는다.
- OR 그룹이 들어간다.
- 동적 조건이 필요하다.
- projection과 count 최적화가 필요하다.

## JPQL `@Query` 컨벤션

### 사용 기준

다음 중 하나라도 해당하면 JPQL `@Query`를 사용한다.

- 고정 fetch join이 필요하다.
- 고정 projection으로 조회한다.
- 파생 쿼리명이 지나치게 길다.
- bulk update/delete가 필요하다.
- soft delete, visibility, tenant 같은 공통 조건을 쿼리에 명시해야 한다.

### 작성 규칙

- JPQL keyword는 대문자 또는 소문자 중 프로젝트에서 하나로 고정한다. 하네스 기본은 대문자 keyword다.
- alias는 짧고 일관되게 둔다. `Post p`, `Member m`.
- 파라미터는 위치 기반(`?1`)보다 `@Param` 이름 기반을 사용한다.
- text block을 사용해 줄바꿈과 indent를 유지한다.
- 단건 entity 조회와 projection 조회를 한 메서드에 섞지 않는다.
- pageable을 받는 JPQL에서 count가 무거우면 `countQuery`를 별도로 작성한다.

```java
@Query("""
        SELECT p
        FROM Post p
        JOIN FETCH p.member
        WHERE p.id = :postId
        """)
Optional<Post> findByIdWithMember(@Param("postId") Long postId);
```

projection:

```java
@Query("""
        SELECT new com.example.post.repository.PostSummaryQueryDto(
            p.id,
            p.title,
            m.nickname,
            p.createdAt
        )
        FROM Post p
        JOIN p.member m
        WHERE p.deleted = false
        ORDER BY p.createdAt DESC
        """)
Page<PostSummaryQueryDto> findAllActiveAsDto(Pageable pageable);
```

bulk update:

```java
@Modifying(clearAutomatically = true, flushAutomatically = true)
@Query("""
        UPDATE Post p
        SET p.likeCount = p.likeCount + 1
        WHERE p.id = :postId
        """)
int incrementLikeCount(@Param("postId") Long postId);
```

## Native Query 컨벤션

native query는 지양하지만 금지하지 않는다. 다음 경우에는 native query를 사용한다.

- DB 전용 함수나 연산자를 사용해야 한다.
- PostgreSQL full-text search, trigram, JSONB, array, window function, CTE, recursive CTE가 필요하다.
- optimizer hint, lock hint, index hint 등 vendor-specific 기능이 필요하다.
- JPQL/QueryDSL JPA로 표현하면 쿼리 성능이나 가독성이 크게 나빠진다.
- bulk 통계/리포트성 조회가 DB 기능에 강하게 묶여 있다.

규칙:

- native query 사용 이유를 메서드 Javadoc 또는 ADR에 남긴다.
- pagination native query는 반드시 `countQuery`를 별도로 둔다.
- DB table/column 이름은 물리 스키마명 그대로 `snake_case`로 작성한다.
- entity 반환보다 projection 반환을 우선한다.
- DB 이식성이 깨지는 지점을 문서화한다.

```java
@Query(
        value = """
                SELECT p.id, p.title, ts_rank(p.search_vector, query) AS rank
                FROM archived_post p, plainto_tsquery(:keyword) query
                WHERE p.search_vector @@ query
                ORDER BY rank DESC, p.published_at DESC
                """,
        countQuery = """
                SELECT COUNT(*)
                FROM archived_post p, plainto_tsquery(:keyword) query
                WHERE p.search_vector @@ query
                """,
        nativeQuery = true
)
Page<PostSearchQueryDto> searchByFullText(@Param("keyword") String keyword, Pageable pageable);
```

## QueryDSL 컨벤션

### 도입 기준

다음 경우 QueryDSL을 사용한다.

- 동적 필터가 있다.
- 검색 조건을 null-safe하게 조립해야 한다.
- 정렬 필드를 whitelist로 제한해야 한다.
- content query와 count query를 분리해 최적화해야 한다.
- projection DTO로 필요한 컬럼만 조회해야 한다.
- fetch join, group by, aggregate, exists subquery를 타입 안전하게 작성해야 한다.

### 의존성과 설정

Gradle 의존성은 Spring Boot BOM/Gradle convention을 우선한다.
QueryDSL 버전은 프로젝트에서 한 곳에만 명시하고, `jakarta` classifier를 사용한다.

```gradle
implementation 'com.querydsl:querydsl-jpa:<version>:jakarta'
annotationProcessor 'com.querydsl:querydsl-apt:<version>:jakarta'
annotationProcessor 'jakarta.annotation:jakarta.annotation-api'
annotationProcessor 'jakarta.persistence:jakarta.persistence-api'
```

`JPAQueryFactory`는 bean으로 등록하거나 repository impl에 생성자 주입한다.
하네스 기본은 bean 등록 + 생성자 주입이다.

### 구현 구조

```java
public interface PostRepository extends JpaRepository<Post, Long>, PostQueryRepository {
}
```

```java
public interface PostQueryRepository {

    Page<PostSummaryQueryDto> findAllActiveWithMemberAsDto(Pageable pageable);

    Page<Post> searchByTitleOrContent(String keyword, Pageable pageable);
}
```

```java
@Repository
@RequiredArgsConstructor
public class PostRepositoryImpl implements PostQueryRepository {

    private final JPAQueryFactory queryFactory;

    private static final Set<String> ALLOWED_SORT_FIELDS = Set.of(
            "id",
            "title",
            "likeCount",
            "createdAt"
    );
}
```

### 동적 조건

- 조건 메서드는 `BooleanExpression`을 반환한다.
- 조건값이 없으면 `null`을 반환하고 `where(...)`에서 제외되게 한다.
- 여러 조건을 반복 조립해야 하면 `nullSafeBuilder` 또는 `BooleanBuilder`를 사용한다.
- 빈 문자열은 `null`로 정규화한다.

```java
private BooleanExpression titleContains(String keyword) {
    String normalizedKeyword = emptyToNull(keyword);
    return normalizedKeyword == null ? null : post.title.containsIgnoreCase(normalizedKeyword);
}
```

### Projection

- 목록 API는 entity fetch보다 projection을 우선 검토한다.
- DTO 이름은 `*QueryDto`로 둔다.
- constructor projection을 기본으로 사용한다.
- `Tuple`은 repository 내부 집계 결과 처리에만 사용하고 외부로 반환하지 않는다.

```java
List<PostSummaryQueryDto> content = queryFactory
        .select(Projections.constructor(PostSummaryQueryDto.class,
                post.id,
                post.title,
                member.nickname,
                post.createdAt
        ))
        .from(post)
        .join(post.member, member)
        .where(post.deleted.isFalse())
        .orderBy(orders)
        .offset(pageable.getOffset())
        .limit(pageable.getPageSize())
        .fetch();
```

### 정렬

- 동적 정렬은 whitelist 방식으로만 허용한다.
- 허용되지 않은 정렬 필드는 무시하거나 validation 예외로 처리한다. 프로젝트 정책을 하나로 정한다.
- API sort field와 entity field가 다르면 mapping table을 둔다.
- 기본 정렬을 반드시 둔다.
- page 기반 목록의 기본 정렬은 안정적인 tie-breaker를 포함한다. 예: `publishedAt desc`, `id desc`.

```java
private static final Set<String> ALLOWED_SORT_FIELDS = Set.of("createdAt", "likeCount", "id");
```

### Pagination과 count

`Page<T>`가 필요하면 content query와 count query를 분리한다.

분리하는 이유:

- content query는 fetch join, projection, order by, limit/offset이 필요하다.
- count query는 전체 건수만 필요하므로 fetch join, order by, 불필요한 select column이 없어야 한다.
- count query에 불필요한 join이 있으면 대용량 테이블에서 가장 먼저 병목이 된다.
- `PageableExecutionUtils.getPage`를 사용하면 마지막 페이지 등 일부 상황에서 count query 실행을 생략할 수 있다.

```java
List<PostSummaryQueryDto> content = queryFactory
        .select(...)
        .from(post)
        .join(post.member, member)
        .where(condition)
        .orderBy(orders)
        .offset(pageable.getOffset())
        .limit(pageable.getPageSize())
        .fetch();

JPAQuery<Long> countQuery = queryFactory
        .select(post.count())
        .from(post)
        .where(condition);

return PageableExecutionUtils.getPage(content, pageable, countQuery::fetchOne);
```

count query 작성 규칙:

- count에 필요 없는 fetch join은 제거한다.
- count에 필요 없는 regular join도 제거하되, where 조건에 필요한 join은 유지한다.
- `distinct`가 필요한 다대다/일대다 join에서는 `countDistinct`를 검토한다.
- 정확한 total이 필요 없으면 `Slice<T>`로 바꿔 count 자체를 제거한다.

## Paging, Sorting 공통 정책

### 요청 변환

- HTTP 요청 DTO는 controller에서 `Pageable`로 변환한다.
- Service는 web request DTO가 아니라 `Pageable`을 받는다.
- Repository는 `Pageable` 또는 cursor 조건만 받는다.

```java
PageSortRequest request = new PageSortRequest(page, size, sort);
Page<PostSummaryQueryDto> result = postRepository.findAllActiveWithMemberAsDto(request.toPageable());
```

### Page vs Slice

| 상황 | 선택 |
| --- | --- |
| totalElements/totalPages가 화면에 필요 | `Page<T>` |
| 무한 스크롤/더보기 | `Slice<T>` |
| 대용량 최신 목록 | cursor/keyset 기반 `Slice<T>` |
| 관리자 표처럼 정확한 총 개수가 중요 | `Page<T>` |

### Offset pagination 주의

- `offset`이 커질수록 DB는 앞 페이지를 스캔하고 버려야 하므로 느려진다.
- 공개 최신 피드처럼 깊은 페이지 접근이 많으면 keyset/cursor pagination을 검토한다.
- offset pagination은 MVP와 관리자 소량 데이터에 우선 적용한다.

### 정렬 필드 검증

- sort field는 whitelist로 제한한다.
- 정렬 가능한 필드는 인덱스와 화면 요구가 있는 필드만 허용한다.
- TEXT, JSON, 대용량 컬럼, 민감 필드는 정렬 금지.
- 다중 정렬의 마지막에는 안정적인 tie-breaker를 둔다.

## Fetch 전략

- entity mapping은 기본 `LAZY`.
- 목록 API에서는 collection fetch join을 금지한다.
- 단건 상세에서 필요한 `ManyToOne`은 `@EntityGraph` 또는 fetch join을 사용한다.
- collection은 batch size, 별도 query, count query, projection으로 해결한다.
- pagination + collection fetch join은 메모리 페이징 위험이 있으므로 금지한다.

## `@Modifying` 쓰기 쿼리

엔티티 상태 변경은 기본적으로 entity load 후 도메인 메서드 호출을 우선한다.
대량 업데이트, 카운터 증가, 상태 일괄 변경처럼 DB 원자성이 더 중요한 경우 `@Modifying`을 사용한다.

규칙:

- service method에 `@Transactional`을 둔다.
- `clearAutomatically`, `flushAutomatically` 필요 여부를 명시한다.
- 반환 타입은 영향받은 row 수를 알 수 있도록 `int` 또는 `long`.
- bulk update/delete는 JPA lifecycle callback을 우회한다는 점을 문서화한다.
- 같은 transaction에서 이미 로드된 entity가 stale해질 수 있음을 고려한다.

## 테스트 기준

- 새 repository 메서드가 추가되면 최소 하나의 `@DataJpaTest`를 추가한다.
- 파생 쿼리는 context load뿐 아니라 실제 저장/조회 결과를 검증한다.
- JPQL `@Query`, `@EntityGraph`, `@Modifying`, projection은 각각 대표 테스트를 둔다.
- QueryDSL은 조건 null/blank, 정렬 whitelist, 기본 정렬, count query, projection 필드 매핑을 테스트한다.
- pagination은 첫 페이지, 마지막 페이지 또는 count 생략 가능 케이스를 검토한다.
- repository test는 fake/mock repository가 아니라 실제 DB 상태를 저장/조회해 검증한다.

## Checklist

- 단건 조회가 `Optional`인가?
- Service가 부재 예외 정책을 소유하는가?
- 파생 쿼리 메서드명이 과도하게 길지 않은가?
- 조인/복합 조건은 JPQL 또는 QueryDSL로 분리했는가?
- QueryDSL 동적 정렬에 whitelist가 있는가?
- page 목록에서 content query와 count query를 분리했는가?
- 정확한 total이 필요 없는 곳에 `Page<T>`를 쓰고 있지 않은가?
- pagination 쿼리에 collection fetch join이 들어가지 않았는가?
- native query 사용 이유가 DB 기능/성능으로 설명되는가?
- `@Modifying` 쿼리의 transaction/stale entity 위험을 검토했는가?
- repository가 web DTO나 controller response에 의존하지 않는가?
- repository test가 실제 DB 상태와 정렬/페이지 결과를 검증하는가?

## References

- [repository-test-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/test/repository-test-convention.md>)
- [layer-and-naming-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/layer-and-naming-convention.md>)
- [repository-interface-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/repository-interface-snippet.md>)
- [querydsl-repository-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/querydsl-repository-snippet.md>)
