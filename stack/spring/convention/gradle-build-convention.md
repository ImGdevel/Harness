# Spring Gradle Build Convention

## Purpose

Spring Boot 프로젝트를 생성할 때 빌드 도구, wrapper 위치, dependency management 기준을 일관되게 고정한다.

## Mandatory Default

- Spring Boot 프로젝트의 기본 빌드 도구는 Gradle이다.
- Gradle wrapper는 repository root에 둔다.
- 멀티 앱 repository에서는 root `settings.gradle`에서 Spring Boot 앱을 include한다.
- Spring Boot 앱별 dependency는 각 앱의 `build.gradle`에 둔다.
- Maven은 기본 선택지가 아니다. 프로젝트에서 Maven을 쓰려면 사용자가 명시적으로 요청하고, 프로젝트 문서에 예외 사유를 남겨야 한다.

## Required Shape

```text
repo-root/
  settings.gradle
  build.gradle
  gradlew
  gradlew.bat
  gradle/wrapper/
  apps/api/build.gradle
```

Root `build.gradle`:

```gradle
plugins {
    id 'org.springframework.boot' version '3.5.9' apply false
    id 'io.spring.dependency-management' version '1.1.7' apply false
}
```

Application `build.gradle`:

```gradle
plugins {
    id 'java'
    id 'org.springframework.boot'
    id 'io.spring.dependency-management'
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
}

tasks.named('test') {
    useJUnitPlatform()
}
```

## Dependency Rules

- Spring Boot가 관리하는 starter와 라이브러리에는 개별 version을 명시하지 않는다.
- 개별 version은 Spring Boot BOM이 관리하지 않는 의존성, 보안 취약점 임시 override, provider 공식 요구사항에만 명시한다.
- 의존성 출처는 기본적으로 `mavenCentral()`만 사용한다.
- 추가 repository는 필요성과 보안 검토 근거를 프로젝트 문서에 남긴 뒤 추가한다.
- 테스트 전용 의존성은 `testImplementation` 또는 `testRuntimeOnly`를 사용한다.
- 런타임 드라이버는 `runtimeOnly`를 사용한다.
- starter가 제공하는 transitive dependency를 직접 중복 추가하지 않는다.

## Maven Exception Template

Maven을 선택해야 하는 예외가 있으면 프로젝트 문서에 다음을 남긴다.

```md
Build tool exception:
- selected tool: Maven
- reason:
- requested by:
- affected project:
- revisit condition:
```

## Review Checklist

- root Gradle wrapper가 있는가?
- Spring Boot 앱이 `settings.gradle`에 포함되어 있는가?
- 앱별 `build.gradle`에 Java toolchain 21이 명시되어 있는가?
- Spring Boot 관리 의존성에 불필요한 version이 없는가?
- `pom.xml`, `mvnw`, `.mvn/`이 새로 추가되지 않았는가?
- 테스트 명령이 `./gradlew :<project>:test` 형태로 문서화되어 있는가?
