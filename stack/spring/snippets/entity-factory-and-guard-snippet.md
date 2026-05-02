# Spring Entity Factory and Guard Snippet

## Use

- 엔티티 생성 진입점 통제
- 도메인 상태/값 변경
- 엔티티 내부에서의 가드 구현
- 관계를 바꾸는 도메인 메서드 예시

## Snippet

```java
@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PROTECTED)
@Builder(access = AccessLevel.PROTECTED)
@Table(name = "post")
public class Post extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @Column(name = "title", length = 200, nullable = false)
    private String title;

    @Column(name = "content", columnDefinition = "TEXT", nullable = false)
    private String content;

    @Column(name = "is_deleted", nullable = false)
    private boolean deleted;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private PostStatus status;

    @OneToMany(mappedBy = "post", cascade = CascadeType.PERSIST)
    @Builder.Default
    private List<Comment> comments = new ArrayList<>();

    public static Post create(Member member, String title, String content) {
        validateCreate(member, title, content);
        return Post.builder()
                .member(member)
                .title(title)
                .content(content)
                .deleted(false)
                .status(PostStatus.DRAFT)
                .build();
    }

    public void publish() {
        this.status = PostStatus.PUBLISHED;
    }

    public void delete() {
        this.deleted = true;
    }

    public void restore() {
        this.deleted = false;
    }

    public void changeTitle(String title) {
        validateTitle(title);
        this.title = title;
    }

    public void addComment(Comment comment) {
        comments.add(comment);
    }

    public void removeComment(Comment comment) {
        comments.remove(comment);
    }

    private static void validateCreate(Member member, String title, String content) {
        if (member == null) {
            throw new IllegalArgumentException("member required");
        }
        validateTitle(title);
        validateContent(content);
    }

    private static void validateTitle(String title) {
        Assert.hasText(title, "title required");
        if (title.length() > 200) {
            throw new IllegalArgumentException("title too long");
        }
    }

    private static void validateContent(String content) {
        Assert.hasText(content, "content required");
    }
}
```

### EmbeddedId/MapsId 예시

```java
@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PROTECTED)
@Builder(access = AccessLevel.PROTECTED)
@Table(name = "post_like")
public class PostLike {

    @EmbeddedId
    private PostLikeId id;

    @MapsId("postId")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id", nullable = false)
    private Post post;

    @MapsId("memberId")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    public static PostLike create(Post post, Member member) {
        validateCreate(post, member);
        return PostLike.builder()
                .id(PostLikeId.create(post.getId(), member.getId()))
                .post(post)
                .member(member)
                .build();
    }

    private static void validateCreate(Post post, Member member) {
        if (post == null || member == null) {
            throw new IllegalArgumentException("post/member required");
        }
    }
}
```

```java
@Embeddable
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PROTECTED)
@Builder(access = AccessLevel.PROTECTED)
public class PostLikeId implements Serializable {
    private Long postId;
    private Long memberId;

    @Override
    public boolean equals(Object o) { ... }

    @Override
    public int hashCode() { ... }
}
```

## Rules

- 생성은 static factory로만 노출하고 생성자는 직접 호출 불가로 제한한다.
- 상태 변경은 domain language 기반 메서드로만 허용한다.
- `EmbeddedId`는 join 엔티티 특성상 조회/삭제 경로가 짧아질 수 있다는 점을 문서에 남긴다.
- `Assert`/`IllegalArgumentException`은 단순 입력 가드에 사용하고, 프로젝트가 `BusinessException` 계층을 도입했다면 해당 예외로 교체한다.

## References

- [entity-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/entity/entity-design-convention.md>)
