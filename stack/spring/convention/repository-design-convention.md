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

## 영속성 컨텍스트 컨벤션

### 기본 원칙

- Entity 조회/변경은 transaction 안에서 끝낸다.
- `open-in-view=false`를 기본값으로 둔다.
- Controller, serializer, view layer에서 lazy association을 처음 접근하지 않는다.
- 응답 DTO 변환은 필요한 연관을 이미 fetch한 뒤 service/application 계층에서 수행한다.
- 변경 감지는 dirty checking에 맡기되, 변경 의도가 드러나는 entity method를 호출한다.
- batch/worker에서 대량 처리할 때는 persistence context가 커지지 않도록 chunk 단위로 `flush`/`clear`를 고려한다.

### Managed, Detached, Lazy Proxy

| 상태 | 의미 | 컨벤션 |
| --- | --- | --- |
| managed | persistence context가 추적 중 | transaction 안에서만 lazy 접근과 변경을 수행 |
| detached | transaction 종료 또는 clear로 분리됨 | lazy association 접근 금지, DTO 변환 후 반환 |
| proxy | `getReferenceById`/lazy association으로 생성 가능 | 필드 접근 시 조회가 발생할 수 있음을 전제로 사용 |

`LazyInitializationException`은 대부분 repository 문제가 아니라 **필요한 데이터를 transaction 안에서 확정하지 않은 설계 문제**로 본다.

### `findById` vs `getReferenceById`

| 상황 | 선택 |
| --- | --- |
| 사용자 입력 ID가 실제 존재하는지 검증해야 함 | `findById(...).orElseThrow(...)` |
| 권한/상태 검증에 entity 필드가 필요 | `findById` 또는 전용 조회 쿼리 |
| FK 연결만 필요하고 대상 존재가 사전에 보장됨 | `getReferenceById` |
| 대상이 없을 가능성이 있고 명확한 404/400이 필요 | `getReferenceById` 금지 |
| bulk delete/update 대상 검증 없이 proxy만 필요 | 제한적으로 `getReferenceById` |

`getReferenceById`는 DB를 즉시 조회하지 않는 proxy를 반환할 수 있다.
존재하지 않는 ID를 참조하면 proxy 필드 접근 시 `EntityNotFoundException`이 발생하거나, flush 시 FK 제약 위반으로 드러날 수 있다.
따라서 외부 요청 값으로 association을 만들 때는 다음 중 하나를 선택한다.

```java
Member member = memberRepository.findById(memberId)
        .orElseThrow(() -> new BusinessException(MemberErrorCode.NOT_FOUND));
Post post = Post.create(member, title, content);
```

```java
// seed, migration, 내부 batch처럼 memberId 존재가 이미 보장된 경우에만 허용
Member memberRef = memberRepository.getReferenceById(memberId);
Post post = Post.create(memberRef, title, content);
```

### 존재하지 않는 엔티티 참조 방지

- 외부 입력 ID는 service/policy 계층에서 먼저 존재 여부를 확인한다.
- 존재 확인과 권한 확인을 분리하지 않는다. 예: `findByIdAndOwnerId`.
- `existsById` 후 `getReferenceById` 조합은 동시성 삭제 사이에 깨질 수 있다. 가능하면 필요한 조건을 만족하는 entity를 한 번에 조회한다.
- association set 교체 시 전달된 ID 개수와 실제 조회된 entity 개수를 비교한다.

```java
List<Tag> tags = tagRepository.findByIdIn(tagIds);
if (tags.size() != tagIds.size()) {
    throw new BusinessException(TagErrorCode.NOT_FOUND);
}
post.replaceTags(tags);
```

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

## Spring Data JPA 기본 메서드 주의점

Spring Data JPA의 기본 구현은 `SimpleJpaRepository`다.
기본 메서드는 편하지만 내부 동작을 모르고 쓰면 성능과 transaction 문제가 생긴다.

| 메서드 | 내부 동작 요약 | 컨벤션 |
| --- | --- | --- |
| `findAll()` | 전체 entity를 조회해 managed 상태로 persistence context에 올림 | 운영 API에서 금지, 작은 코드 테이블만 허용 |
| `findAll(Pageable)` | content query와 count query를 실행할 수 있음 | 목록 API 기본 선택, count 비용 검토 |
| `findAllById(ids)` | 단일 PK는 `IN` 쿼리, 복합키는 `findById` 반복 가능 | 대량 ID 조회는 단일 PK 여부와 개수 제한 확인 |
| `save(entity)` | 신규는 `persist`, 기존은 `merge` | detached entity merge 남용 금지 |
| `saveAll(entities)` | 내부에서 각 entity에 대해 `save` 반복 | 대량 insert/update는 batch 설정과 chunk flush/clear 필요 |
| `deleteAll()` | `findAll()` 후 개별 delete 가능 | 운영 대량 삭제 금지 |
| `deleteAllInBatch()` | bulk delete query | lifecycle callback/영속성 컨텍스트 불일치 주의 |
| `getReferenceById(id)` | proxy 반환 가능, 즉시 select 보장 없음 | 존재 보장된 FK 연결에만 제한 사용 |

Best practice:

- API 목록에는 `findAll()`을 쓰지 않는다.
- 작은 마스터 데이터라도 `findByActiveTrueOrderBy...`처럼 조건과 정렬을 드러낸다.
- 대량 처리에는 `Page`보다 `Slice` 또는 chunk ID scan을 우선 검토한다.
- `saveAll`은 JDBC batch 설정, flush/clear 전략 없이 무제한 호출하지 않는다.
- bulk update/delete 후 같은 transaction에서 기존 managed entity를 재사용하지 않는다.

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

## N+1 방지 전략

N+1은 lazy loading 자체의 문제가 아니라 **조회 목적에 맞는 fetch 전략을 고르지 않은 문제**다.
목록, 상세, batch 작업별로 아래 선택표를 따른다.

| 상황 | 우선 전략 | 이유 |
| --- | --- | --- |
| 목록에서 root + `ManyToOne` 몇 개 필드 필요 | projection DTO | 필요한 컬럼만 조회하고 persistence context 부담 감소 |
| 목록에서 root entity와 `ManyToOne` entity가 필요 | fetch join 또는 `@EntityGraph` | row 증폭 없이 N+1 제거 가능 |
| 단건 상세에서 root + 단일 collection 필요 | fetch join 또는 `@EntityGraph` | pagination이 아니고 row 수가 제한됨 |
| page 목록에서 `OneToMany` collection 필요 | 2-step 조회 + in-memory join | collection fetch join pagination 문제 방지 |
| page 목록에서 댓글 수/태그 수 등 count 필요 | group by aggregate query + in-memory join | collection 로딩 없이 필요한 값만 결합 |
| 여러 root의 lazy association을 반복 접근 | batch size | fetch join이 부적합한 반복 lazy access 완화 |
| 깊은 페이지 최신 목록 | cursor/keyset + projection | offset 비용과 count 비용 회피 |

### Projection 사용 기준

Projection은 화면/응답에 필요한 필드가 명확한 목록 조회에 우선 사용한다.

사용한다:

- 목록 card, search result, admin table처럼 필드가 제한적이다.
- `ManyToOne`의 일부 필드만 필요하다.
- entity 변경이 필요 없는 read-only query다.
- persistence context에 많은 entity를 올리는 것이 부담이다.

피한다:

- 조회 후 entity domain method를 호출해 상태 변경해야 한다.
- association graph 전체가 필요하고 transaction 안에서 domain behavior를 수행해야 한다.
- projection constructor가 화면 변경마다 과도하게 흔들린다.

### In-memory join 사용 기준

In-memory join은 DB에서 root page를 먼저 확정한 뒤, root id 목록으로 보조 데이터를 별도 조회하고 `Map`으로 합치는 방식이다.

사용한다:

- page 목록에서 root와 `OneToMany`/`ManyToMany` 데이터를 함께 보여줘야 한다.
- collection fetch join을 쓰면 row가 증폭되어 pagination이 깨질 수 있다.
- projection join으로 root row가 중복되거나 count가 왜곡될 수 있다.
- 댓글 수, 태그 목록, 좋아요 여부처럼 root별 보조 데이터가 필요하다.

패턴:

```java
Page<PostSummaryQueryDto> page = postRepository.search(condition, pageable);
List<Long> postIds = page.getContent().stream()
        .map(PostSummaryQueryDto::id)
        .toList();

Map<Long, Long> commentCountMap = commentRepository.countByPostIds(postIds);
Map<Long, List<TagQueryDto>> tagMap = tagRepository.findTagsByPostIds(postIds);

return PageResponse.of(
        page.getContent().stream()
                .map(post -> PostListResponse.of(post, commentCountMap, tagMap))
                .toList(),
        page
);
```

주의:

- page size 안의 ID에 대해서만 보조 조회한다.
- `Map<RootId, Value>` 형태로 결합한다.
- 정렬은 root query에서 끝낸다. 보조 조회 결과로 root 순서를 다시 만들지 않는다.
- postIds가 비어 있으면 보조 query를 실행하지 않는다.

### Batch Size 사용 기준

Hibernate batch fetching은 lazy association을 여러 건 접근할 때 `IN` 쿼리로 묶어 N+1을 줄인다.

사용한다:

- 여러 entity의 `ManyToOne` 또는 collection을 transaction 안에서 반복 접근한다.
- fetch join을 쓰기 어렵거나 query가 지나치게 커진다.
- 상세/내부 처리에서 association 접근 패턴이 일정하다.

사용하지 않는다:

- 목록 응답에 필요한 필드가 projection으로 해결된다.
- root page + collection 데이터를 명확히 2-step으로 조회할 수 있다.
- 무제한 collection을 batch size로 숨기려 한다.

권장:

- 전역 기본값은 보수적으로 둔다. 예: `hibernate.default_batch_fetch_size=50` 또는 `100`.
- 특정 association에만 필요하면 `@BatchSize(size = 50)`을 사용한다.
- DB `IN` 절 길이, page size, association cardinality를 보고 조정한다.
- batch size는 N+1을 줄이는 보조 수단이지 쿼리 설계를 대체하지 않는다.

```java
@BatchSize(size = 50)
@OneToMany(mappedBy = "post")
private List<Comment> comments = new ArrayList<>();
```

### Fetch Join 금지/허용 기준

허용:

- 단건 상세 조회.
- page가 아닌 bounded 목록.
- `ManyToOne`, `OneToOne` 같이 row 증폭이 없는 연관.

금지:

- page query에서 `OneToMany`/`ManyToMany` collection fetch join.
- 두 개 이상의 collection fetch join.
- count query에 fetch join 포함.

이유:

- collection fetch join은 root row를 collection row 수만큼 증폭한다.
- pagination이 DB row 기준으로 적용되어 root page가 깨지거나 Hibernate가 메모리 페이징을 할 수 있다.
- 여러 collection fetch join은 Cartesian product와 `MultipleBagFetchException` 위험이 있다.

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
