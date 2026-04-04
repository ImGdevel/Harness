# Spring WebMvc Test Snippet

## Use

- `@WebMvcTest`
- request validation
- response contract

## Snippet

```java
@WebMvcTest(PostController.class)
class PostControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private PostService postService;

    @Test
    void create_post_returns_201() throws Exception {
        given(postService.create(any()))
                .willReturn(new PostCreateResponse(1L, "hello"));

        mockMvc.perform(post("/api/v1/posts")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"title":"hello"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").value(1L))
                .andExpect(jsonPath("$.data.title").value("hello"));
    }
}
```

## Rules

- Mock service collaborator.
- Assert HTTP status and JSON contract.
- Do not re-test service logic here.

## References

- [controller-webmvc-test-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/test/controller-webmvc-test-convention.md>)
