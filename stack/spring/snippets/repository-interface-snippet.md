# Repository Interface Snippet

## Use

- Spring Data JPA repository interface 작성
- 단건/다건/존재 여부 조회 계약 작성
- JPQL `@Query`, projection, `@EntityGraph`, `@Modifying` 사용 예시

## Snippet

```java
public interface PostRepository extends JpaRepository<Post, Long>, PostQueryRepository {

    Optional<Post> findBySlug(String slug);

    boolean existsBySlug(String slug);

    List<Post> findTop20ByStatusOrderByPublishedAtDesc(PostStatus status);

    @EntityGraph(attributePaths = {"company", "sourceBlog"})
    Optional<Post> findWithCompanyAndSourceBlogById(Long id);

    @Query("""
            SELECT p
            FROM Post p
            JOIN FETCH p.member
            WHERE p.id = :postId
            """)
    Optional<Post> findByIdWithMember(@Param("postId") Long postId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            UPDATE Post p
            SET p.status = :status
            WHERE p.id = :postId
            """)
    int updateStatus(@Param("postId") Long postId, @Param("status") PostStatus status);
}
```

## JPQL Projection Snippet

```java
@Query(
        value = """
                SELECT new com.example.post.repository.PostSummaryQueryDto(
                    p.id,
                    p.slug,
                    p.title,
                    c.name,
                    p.publishedAt
                )
                FROM Post p
                JOIN p.company c
                WHERE p.status = :status
                  AND (:companySlug IS NULL OR c.slug = :companySlug)
                """,
        countQuery = """
                SELECT COUNT(p)
                FROM Post p
                JOIN p.company c
                WHERE p.status = :status
                  AND (:companySlug IS NULL OR c.slug = :companySlug)
                """
)
Page<PostSummaryQueryDto> searchPublishedPosts(
        @Param("status") PostStatus status,
        @Param("companySlug") String companySlug,
        Pageable pageable
);
```

```java
public record PostSummaryQueryDto(
        Long id,
        String slug,
        String title,
        String companyName,
        LocalDateTime publishedAt
) {
}
```

## Native Query Snippet

```java
@Query(
        value = """
                SELECT p.id, p.title
                FROM archived_post p
                WHERE p.search_vector @@ plainto_tsquery(:keyword)
                ORDER BY p.published_at DESC, p.id DESC
                """,
        countQuery = """
                SELECT COUNT(*)
                FROM archived_post p
                WHERE p.search_vector @@ plainto_tsquery(:keyword)
                """,
        nativeQuery = true
)
Page<PostSearchQueryDto> searchByFullText(@Param("keyword") String keyword, Pageable pageable);
```

## Reference Lookup Snippet

```java
public Post createPost(Long memberId, String title, String content) {
    Member member = memberRepository.findById(memberId)
            .orElseThrow(() -> new BusinessException(MemberErrorCode.NOT_FOUND));

    Post post = Post.create(member, title, content);
    return postRepository.save(post);
}
```

```java
public Post createPostFromTrustedBatch(Long memberId, String title, String content) {
    Member memberRef = memberRepository.getReferenceById(memberId);
    Post post = Post.create(memberRef, title, content);
    return postRepository.save(post);
}
```

## Rules

- 기본 repository는 `JpaRepository<Entity, Long>`을 상속한다.
- QueryDSL/custom query 계약이 필요하면 `*QueryRepository`를 함께 상속한다.
- 단건 조회는 `Optional<T>`를 반환한다.
- 부재 시 예외 변환은 Service에서 처리한다.
- 외부 요청 ID는 `getReferenceById`보다 `findById`로 존재/권한을 확인한다.
- `getReferenceById`는 대상 존재가 보장된 내부 처리와 FK 연결 최적화에만 제한적으로 사용한다.
- 운영 목록 API에서 무제한 `findAll()`은 사용하지 않는다.
- JPQL `@Query` 파라미터는 `@Param` 이름 기반으로 작성한다.
- pagination JPQL/native query에서 count가 무거우면 `countQuery`를 별도로 작성한다.
- projection은 `*QueryDto`, `*Projection`처럼 조회 목적을 드러낸다.
- `@Modifying`은 영향받은 row 수를 반환하게 작성한다.

## References

- [repository-design-convention.md](../convention/repository-design-convention.md)
