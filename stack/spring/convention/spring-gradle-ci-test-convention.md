# Spring Gradle CI Test Convention

## Purpose

Spring Boot + Gradle 프로젝트에서 unit test와 integration test의 실행 경계를 명확히 나눈다.
로컬 push 전에는 빠른 unit test만 수행하고, PR CI에서는 integration test를 병렬 job으로 수행한다.

## Test Tag Rule

JUnit 5 tag를 사용한다.

| Tag | Meaning | Examples | Default Stage |
| --- | --- | --- | --- |
| `unit` | Spring context 없이 JVM 안에서 끝나는 테스트 | DTO, util, enum, policy, mapper pure test | pre-push, PR unit job |
| `integration` | Spring context, DB, MVC slice, repository, migration이 필요한 테스트 | `@SpringBootTest`, `@DataJpaTest`, `@WebMvcTest`, Testcontainers | PR integration job |

Tag는 문자열 literal을 반복하지 말고 가능하면 test source의 `TestTags` 상수로 관리한다.
새 `*Tests.java` 파일은 반드시 `@Tag(UNIT)` 또는 `@Tag(INTEGRATION)`을 선언한다.
프로젝트 repository policy에서 untagged test class를 실패 처리하는 것을 권장한다.

```java
package com.example.testsupport;

public final class TestTags {

    public static final String UNIT = "unit";
    public static final String INTEGRATION = "integration";

    private TestTags() {
    }
}
```

```java
import static com.example.testsupport.TestTags.UNIT;

import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

@Tag(UNIT)
class StringNormalizerTests {

    @Test
    void trimsBlankToNull() {
    }
}
```

## Gradle Task Rule

`test`는 빠른 기본 검증으로 유지하고, `integrationTest`를 별도 task로 둔다.

```gradle
tasks.named('test', Test) {
    useJUnitPlatform {
        excludeTags 'integration'
    }
}

tasks.register('unitTest', Test) {
    group = 'verification'
    description = 'Runs unit tests only.'
    testClassesDirs = sourceSets.test.output.classesDirs
    classpath = sourceSets.test.runtimeClasspath
    useJUnitPlatform {
        includeTags 'unit'
    }
}

tasks.register('integrationTest', Test) {
    group = 'verification'
    description = 'Runs integration tests only.'
    testClassesDirs = sourceSets.test.output.classesDirs
    classpath = sourceSets.test.runtimeClasspath
    useJUnitPlatform {
        includeTags 'integration'
    }
    shouldRunAfter tasks.named('test')
}

tasks.named('check') {
    dependsOn tasks.named('integrationTest')
}
```

Project policy:

- `pre-push`: `./gradlew :apps:api:unitTest`
- PR `unit-test` job: `./gradlew :apps:api:unitTest --build-cache`
- PR `integration-test` job: `./gradlew :apps:api:integrationTest --build-cache`
- full local verification: `./gradlew :apps:api:check --build-cache`

CI에서 `--configuration-cache`를 쓰려면 아래 검증을 먼저 통과시킨다.

```bash
./gradlew :apps:api:unitTest :apps:api:integrationTest --build-cache --configuration-cache
```

## CI Cache Rule

- GitHub Actions에서는 Gradle User Home cache를 켠다.
- Gradle command에는 `--build-cache`를 붙인다.
- `--configuration-cache`는 프로젝트에서 `unitTest`와 `integrationTest`가 모두 통과한 뒤 사용한다.
- `build/`와 `.gradle/`은 Git에 커밋하지 않는다.
- Linux runner에서 `./gradlew`를 실행하려면 wrapper 파일의 executable bit를 Git에 기록한다.

```bash
git update-index --chmod=+x gradlew
```

## Classification Checklist

- Spring annotation이 있는 테스트는 기본적으로 `integration`인가?
- H2/Flyway/JPA/MockMvc/Testcontainers를 쓰면 `integration`인가?
- pure Java record/DTO/util/parser/normalizer 테스트는 `unit`인가?
- 모든 `*Tests.java`가 JUnit `@Tag`를 명시하는가?
- PR workflow에서 unit과 integration이 별도 job으로 병렬 실행되는가?
- `check`가 integration test까지 포함하는가?
- `gradlew` 실행 권한이 Linux runner에서 유효한가?
