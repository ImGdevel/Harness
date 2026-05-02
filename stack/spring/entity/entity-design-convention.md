# Spring Entity Design Convention

## 목적

JPA Entity를 데이터 컨테이너가 아닌 도메인 상태 관리 객체로 설계한다.
엔티티는 **유효성 검사 + 상태 전이 + 영속성 매핑**을 동시에 만족해야 한다.

## 적용 범위

- JPA Entity, Embeddable, 복합키 객체, 감사/버전 정책
- 엔티티 생성, 상태 변경, 가드, 관계 구성 규칙
- 공통 스프링 프로젝트에서 재사용 가능한 최소 규약

## 필수 규칙

1. 엔티티는 의미 없는 setter를 노출하지 않는다.
2. 생성은 static factory 또는 제어된 Builder 진입점에서만 수행한다.
3. 상태 변경은 `changeXxx`, `approve`, `publish` 같은 명확한 도메인 메서드로만 수행한다.
4. 생성/변경은 내부 가드에서 즉시 검증한다.
5. 테이블/컬럼명은 `snake_case`를 사용한다.
6. enum은 기본 `@Enumerated(EnumType.STRING)`을 사용한다.
7. 프로젝트 내 ID 전략은 하나로 통일한다.
8. 감사 필드(`createdAt`, `updatedAt`, version 등)는 프로젝트 규약으로 통일한다.
9. 불가능한 상태는 가드로 막아 도메인 수준에서 일관성을 보장한다.
10. 다른 계층이 잘못된 상태를 고친다는 가정은 하지 않는다.

## 권장 엔티티 골격

```java
@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PROTECTED)
@Builder(access = AccessLevel.PROTECTED)
@Table(name = "member")
public class Member {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "email", unique = true, nullable = false, length = 200)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private MemberStatus status;

    public static Member create(String email, String statusValue) {
        validateCreate(email, statusValue);
        return Member.builder()
                .email(email)
                .status(MemberStatus.valueOf(statusValue))
                .build();
    }

    public void deactivate() {
        this.status = MemberStatus.INACTIVE;
    }

    private static void validateCreate(String email, String statusValue) {
        Assert.hasText(email, "email required");
        Assert.hasText(statusValue, "status required");
    }
}
```

## 메서드 네이밍 규칙

- 생성: `create`, `register`, `collect`, `propose`, `request`, `open`  
- 값 변경: `changeXxx`, `updateXxx`, `renameXxx`  
- 상태 전이: `activate`, `deactivate`, `approve`, `reject`, `publish`, `hide`, `withdraw`, `delete`, `restore`  
- 판정: `isXxx`, `canXxx`, `hasXxx`  
- 도메인 동작: `loginSuccess`, `refresh`, `renew` 등 도메인 용어 위주

## 검증/가드 정책

### 원칙

- 도메인 불변식은 엔티티 내부에 둔다.
- 변경 요청은 항상 유효성 검사 후 반영한다.
- 가드 실패 시 **명시적 예외**를 던져 호출자가 즉시 오류를 인지하게 한다.

### 예외 처리 정책

- 단순 입력 형식/빈 문자열/길이 검증: `IllegalArgumentException` 또는 `Assert` 사용 가능
- 비즈니스 규칙(이미 삭제됨, 중복 상태 전이 등)은 프로젝트의 공통 `BusinessException`/도메인 예외 사용을 권장
- `Assert`는 빠른 실패를 위한 수단으로 허용되며, 정책 위반을 의미 있는 예외 타입으로 바꾸는 것을 권장

```java
private static void validateCreate(String title, int limit) {
    Assert.hasText(title, "title required");
    if (title.length() > limit) {
        throw new IllegalArgumentException("title too long");
    }
}

public void changeTitle(String title) {
    validateTitle(title);
    this.title = title;
}

private static void validateTitle(String title) {
    Assert.hasText(title, "title required");
    if (title.length() > 200) {
        throw new IllegalArgumentException("title length must be <= 200");
    }
}
```

### 규칙 정합성

- `IllegalArgumentException`이 과도하게 누적되어 도메인 오류 추적이 어려운 경우, 해당 프로젝트에서 예외 계층(예: `BusinessException`)을 정의해 점진 교체한다.
- 레퍼런스 예제는 `Assert`/`IllegalArgumentException` 사용이 잦으나, 공통 규약에서는 “예외 통일”을 프로젝트 표준으로 명시한다.

## Enum 처리 규칙

- `EnumType.STRING`을 기본으로 한다.
- `EnumType.ORDINAL` 금지.
- 상태 코드처럼 자주 변할 수 있거나 노출 범위가 넓은 enum은 length 제한과 변경 이력 문서화.
- 의미가 자주 변하는 상태값은 코드표/ADR로 별도 기록한다.

## ID/PK 규칙

- 프로젝트 단위로 ID 전략을 고정한다.
- 기본 전략은 `GenerationType.IDENTITY` (초기 MVP 기준), 필요한 경우 성능/일괄성 요구 시 프로젝트 단위로 `SEQUENCE`로 교체 결정.
- PK는 항상 `id`로 통일한다.

## 관계(Mapping) 규칙

- `@ManyToOne`은 기본적으로 `FetchType.LAZY`.
- `@OneToMany`는 기본적으로 단방향으로 시작하고, 양방향은 이유가 있을 때만 도입한다.
- 컬렉션은 엔티티 내부에서 생성 메서드로만 변경한다.
- `@ManyToMany`는 기본적으로 금지하고, 필요 시 조인 엔티티(`Join Entity`)를 사용한다.
- 쓰기/삭제가 많은 관계 테이블은 복합키(`@EmbeddedId` + `@MapsId`) 적용을 후보로 둔다.
- 관계 컬렉션에서 `@Builder.Default`로 초기화하고 `new ArrayList<>()` 또는 `new LinkedHashSet<>()`으로 생성을 명시한다.
- 양방향 관계는 무한 참조를 피하기 위해 `toString`, `equals`, `hashCode`에서 연관관계를 제외한다.

### 연관관계 예시

```java
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "member_id", nullable = false)
private Member member;

@OneToMany(mappedBy = "post", cascade = CascadeType.PERSIST)
@Builder.Default
private List<Comment> comments = new ArrayList<>();

public void addComment(Comment comment) {
    comments.add(comment);
}

public void removeComment(Comment comment) {
    comments.remove(comment);
}
```

## 감사/버전 규칙

- 공통 감사가 필요하면 `BaseEntity` 계열을 상속한다.
- 동시성 제어나 중복 갱신 방지가 필요하면 `@Version` 정책을 도입한다.

## 테스트 체크리스트

- 순수 엔티티 테스트에서 JPA 컨텍스트 없이 가드/상태 전이 검증 가능해야 한다.
- ID/생성자, 상태 전이, `Enum` 제약, 컬렉션 변경, 예외 분기를 포함한다.
- `@Entity` 매핑 특성은 리포지토리 통합 테스트에서 보강한다.

## Checklist

- 의미 있는 setter가 있는가?
- 생성은 통제되는가?
- 상태 전이가 명시적인 비즈니스 메서드로 제한되는가?
- 가드 정책이 일관적인가?
- Enum 문자열 매핑, ID 전략, 감사 정책이 프로젝트 규약과 일치하는가?
- 관계 변경이 캡슐화되어 있는가?

## References

- [erd-design-convention.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/entity/erd-design-convention.md>)
- [table-definition-writing-guide.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/entity/table-definition-writing-guide.md>)
- [business-exception-and-error-code-snippet.md](</C:/Users/imdls/workspace/Project Workspace/stack/spring/snippets/business-exception-and-error-code-snippet.md>)
