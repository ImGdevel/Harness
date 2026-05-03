# Spring Service Test Snippet

## Use

- service orchestration
- Mockito unit test

## Snippet

```java
@ExtendWith(MockitoExtension.class)
class PostServiceTest {

    @Mock
    private PostRepository postRepository;

    @InjectMocks
    private PostService postService;

    @Test
    void create_post_saves_entity() {
        given(postRepository.save(any(Post.class)))
                .willAnswer(invocation -> invocation.getArgument(0));

        PostCreateCommand command = new PostCreateCommand("hello");

        PostCreateResult result = postService.create(command);

        then(postRepository).should().save(any(Post.class));
        assertThat(result.title()).isEqualTo("hello");
    }
}
```

## Rules

- Mock repository and external collaborator.
- Assert orchestration result and meaningful interaction only.
- Keep JPA and HTTP detail out of service tests.

## References

- [service-test-convention.md](../test/service-test-convention.md)
