# Spring Entity Design Convention

Tasteam 백엔드 위키의 엔티티 설계 규칙을 Spring 공통 하네스용으로 일반화한 문서다.
목적은 JPA 엔티티가 의미 있는 상태 전이와 불변식을 직접 표현하도록 만드는 것이다.

## Core Rule

- Setter로 상태를 열어 두지 않는다.
- 생성과 상태 변경은 의미 있는 메서드로만 수행한다.
- 검증은 생성 시점과 변경 시점에 즉시 수행한다.

## Creation Rule

- 외부에서 무분별하게 `new` 또는 unrestricted builder를 쓰지 않는다.
- 정적 팩토리 메서드(`create`, `of`)를 기본 진입점으로 둔다.
- 빌더를 쓰더라도 접근 범위를 제한한다.

예:

```java
@Entity
@Getter
@Builder(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PROTECTED)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Table(name = "post")
public class Post extends BaseTimeEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "title", nullable = false, length = 100)
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private PostStatus status;

    public static Post create(String title) {
        validateCreate(title);
        return Post.builder()
                .title(title)
                .status(PostStatus.ACTIVE)
                .build();
    }

    public void changeTitle(String newTitle) {
        validateTitle(newTitle);
        this.title = newTitle;
    }

    private static void validateCreate(String title) { }
    private static void validateTitle(String title) { }
}
```

## Field And Mapping Rule

- 테이블/컬럼명은 `snake_case`를 사용한다.
- Enum은 `EnumType.STRING`을 기본으로 한다.
- 시간 타입은 프로젝트 표준을 정해 일관되게 사용한다.
- 공통 생성/수정 시간은 공통 베이스 엔티티로 관리하는 편을 우선 검토한다.

ID 전략은 DB와 프로젝트 정책에 맞게 고정한다.

- PostgreSQL 중심이면 `SEQUENCE`를 우선 검토한다.
- MySQL 중심이면 `IDENTITY`를 우선 검토한다.
- 중요한 것은 프로젝트 안에서 전략을 섞지 않고 문서화하는 것이다.

## Method Naming

권장 패턴:

- 생성: `create(...)`
- 변경: `changeXxx(...)`
- 상태 전이: `activate()`, `deactivate()`, `withdraw()`
- 질의: `isActive()`, `isDeleted()`

## Code Order

권장 코드 순서:

1. 필드 선언
2. 정적 팩토리
3. 공개 비즈니스 메서드
4. private 검증/헬퍼 메서드

## Guard Rule

- 길이, null, blank, 범위 조건은 메서드 안에서 즉시 검증한다.
- 잘못된 상태를 만든 뒤 다른 레이어에서 복구하는 흐름을 허용하지 않는다.
- 카운터/상태 값은 음수나 불가능한 상태로 내려가지 않게 guard를 둔다.

## Review Checklist

- 의미 없는 setter가 남아 있지 않은가
- 생성과 변경 규칙이 정적 팩토리/비즈니스 메서드에 모여 있는가
- Enum과 시간 타입 사용이 프로젝트 표준과 일치하는가
- 상태 전이 이름만 보고 의도가 드러나는가
- 엔티티가 단순 DB row wrapper가 아니라 도메인 상태를 표현하는가
