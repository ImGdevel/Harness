# QueryDSL Repository Snippet

## Use

- 동적 조건, 동적 정렬, projection, count 분리가 필요한 repository 구현
- Spring Data JPA repository에 QueryDSL custom query 계약 연결
- page 목록에서 content query와 count query를 분리

## Repository Contract

```java
public interface PostRepository extends JpaRepository<Post, Long>, PostQueryRepository {
}
```

```java
public interface PostQueryRepository {

    Page<PostSummaryQueryDto> findAllActiveWithMemberAsDto(Pageable pageable);

    Page<PostSummaryQueryDto> search(PostSearchCondition condition, Pageable pageable);
}
```

## Repository Implementation

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

    @Override
    public Page<PostSummaryQueryDto> search(PostSearchCondition condition, Pageable pageable) {
        OrderSpecifier<?>[] orders = QueryDslOrderUtil.getOrderSpecifiersWithDefault(
                pageable,
                post,
                ALLOWED_SORT_FIELDS,
                post.createdAt.desc()
        );

        BooleanExpression whereCondition = nullSafeBuilder(
                keywordContains(condition.keyword()),
                companyIdEq(condition.companyId()),
                publishedOnly()
        );

        List<PostSummaryQueryDto> content = queryFactory
                .select(Projections.constructor(PostSummaryQueryDto.class,
                        post.id,
                        post.title,
                        member.nickname,
                        post.createdAt
                ))
                .from(post)
                .join(post.member, member)
                .where(whereCondition)
                .orderBy(orders)
                .offset(pageable.getOffset())
                .limit(pageable.getPageSize())
                .fetch();

        JPAQuery<Long> countQuery = queryFactory
                .select(post.count())
                .from(post)
                .where(whereCondition);

        return PageableExecutionUtils.getPage(content, pageable, countQuery::fetchOne);
    }

    private BooleanExpression keywordContains(String keyword) {
        String normalizedKeyword = emptyToNull(keyword);
        return normalizedKeyword == null
                ? null
                : post.title.containsIgnoreCase(normalizedKeyword)
                        .or(post.content.containsIgnoreCase(normalizedKeyword));
    }

    private BooleanExpression companyIdEq(Long companyId) {
        return companyId == null ? null : post.company.id.eq(companyId);
    }

    private BooleanExpression publishedOnly() {
        return post.visibilityState.eq(VisibilityState.PUBLISHED);
    }

    private BooleanExpression nullSafeBuilder(BooleanExpression... expressions) {
        BooleanExpression result = null;
        for (BooleanExpression expression : expressions) {
            if (expression != null) {
                result = result == null ? expression : result.and(expression);
            }
        }
        return result;
    }

    private String emptyToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
```

## Sort Utility Shape

```java
public final class QueryDslOrderUtil {

    private QueryDslOrderUtil() {
    }

    public static OrderSpecifier<?>[] getOrderSpecifiersWithDefault(
            Pageable pageable,
            EntityPathBase<?> qClass,
            Set<String> allowedFields,
            OrderSpecifier<?> defaultOrder
    ) {
        OrderSpecifier<?>[] orders = getOrderSpecifiers(pageable, qClass, allowedFields);
        return orders.length == 0 ? new OrderSpecifier<?>[]{defaultOrder} : orders;
    }
}
```

## Rules

- QueryDSL 계약은 `*QueryRepository`, 구현은 `{Entity}RepositoryImpl`을 사용한다.
- `Page<T>`는 content query와 count query를 분리한다.
- count query에는 fetch join, order by, 불필요한 regular join을 제거한다.
- 동적 정렬은 whitelist 방식으로만 허용한다.
- 목록 API는 entity보다 `*QueryDto` projection을 우선 검토한다.
- collection fetch join과 pagination을 함께 사용하지 않는다.

## References

- [repository-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/repository-design-convention.md>)
