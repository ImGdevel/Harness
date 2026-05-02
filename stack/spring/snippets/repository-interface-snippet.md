# Repository Interface Snippet

## Use

- Spring Data JPA repository interface 작성
- 단건/다건/존재 여부 조회 계약 작성
- `@Query`, projection, `@EntityGraph`, `@Modifying` 사용 예시

## Snippet

```java
public interface PostRepository extends JpaRepository<Post, Long> {

    Optional<Post> findBySlug(String slug);

    boolean existsBySlug(String slug);

    List<Post> findTop20ByStatusOrderByPublishedAtDesc(PostStatus status);

    @EntityGraph(attributePaths = {"company", "sourceBlog"})
    Optional<Post> findWithCompanyAndSourceBlogById(Long id);

    @Query("""
            select new com.example.post.domain.repository.PostQueryDto(
                p.id,
                p.slug,
                p.title,
                c.name,
                p.publishedAt
            )
            from Post p
            join p.company c
            where p.status = :status
              and (:companySlug is null or c.slug = :companySlug)
            order by p.publishedAt desc
            """)
    Page<PostQueryDto> searchPublishedPosts(
            @Param("status") PostStatus status,
            @Param("companySlug") String companySlug,
            Pageable pageable
    );

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("update Post p set p.status = :status where p.id = :postId")
    int updateStatus(@Param("postId") Long postId, @Param("status") PostStatus status);
}
```

```java
public record PostQueryDto(
        Long id,
        String slug,
        String title,
        String companyName,
        LocalDateTime publishedAt
) {
}
```

## Custom Repository Snippet

```java
public interface PostRepositoryCustom {

    Slice<PostQueryDto> search(PostSearchCondition condition, Pageable pageable);
}
```

```java
@RequiredArgsConstructor
public class PostRepositoryImpl implements PostRepositoryCustom {

    private final EntityManager entityManager;

    @Override
    public Slice<PostQueryDto> search(PostSearchCondition condition, Pageable pageable) {
        // 동적 검색 구현은 프로젝트가 선택한 query 기술(Querydsl, Criteria, JPQL builder)에 맞춘다.
        throw new UnsupportedOperationException("project-specific query implementation required");
    }
}
```

## Rules

- 단건 조회는 `Optional<T>`를 반환한다.
- 부재 시 예외 변환은 Service에서 처리한다.
- `@Query` 파라미터는 `@Param` 이름 기반으로 작성한다.
- projection은 `*QueryDto`, `*Projection`처럼 조회 목적을 드러낸다.
- `@Modifying`은 영향받은 row 수를 반환하게 작성한다.

## References

- [repository-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/convention/repository-design-convention.md>)
