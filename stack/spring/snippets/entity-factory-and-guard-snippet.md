# Spring Entity Factory and Guard Snippet

## Use

- `Entity` create
- state change
- local guard

## Snippet

```java
@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PROTECTED)
@Builder(access = AccessLevel.PROTECTED)
public class Post {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PostStatus status;

    public static Post create(String title) {
        validateTitle(title);
        return Post.builder()
                .title(title)
                .status(PostStatus.ACTIVE)
                .build();
    }

    public void changeTitle(String title) {
        validateTitle(title);
        this.title = title;
    }

    private static void validateTitle(String title) {
        if (title == null || title.isBlank()) {
            throw new IllegalArgumentException("title must not be blank");
        }
        if (title.length() > 100) {
            throw new IllegalArgumentException("title length must be <= 100");
        }
    }
}
```

## Rules

- Enter through `create(...)`.
- Keep guard inside `Entity`.
- Do not expose meaningless setter.

## References

- [entity-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/entity/entity-design-convention.md>)
