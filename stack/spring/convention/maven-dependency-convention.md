# Spring Maven Dependency Convention

## Purpose

Spring Boot Maven 프로젝트에서 의존성 버전과 출처를 일관되게 관리한다.

## Rules

- Spring Boot 프로젝트는 `spring-boot-starter-parent` 또는 Spring Boot BOM으로 dependency management를 먼저 구성한다.
- Spring Boot가 관리하는 starter와 라이브러리에는 개별 `<version>`을 명시하지 않는다.
- 개별 `<version>`은 Spring Boot BOM이 관리하지 않는 의존성에만 명시한다.
- 개별 버전을 명시할 때는 PR 또는 작업 문서에 이유와 출처를 남긴다.
- 의존성 출처는 기본적으로 Maven Central을 사용한다.
- 사내 저장소, GitHub Packages, JitPack 같은 추가 repository는 필요성과 보안 검토 근거를 남긴 뒤 추가한다.
- 테스트 전용 의존성은 `<scope>test</scope>`를 명시한다.
- 런타임 드라이버는 필요한 경우 `<scope>runtime</scope>` 또는 `runtimeOnly`에 해당하는 Maven scope로 분리한다.
- 같은 기능의 starter를 중복 추가하지 않는다.
- starter가 제공하는 transitive dependency를 직접 추가하지 않는다.
- 보안 취약점 대응을 위한 버전 override는 임시 조치로 보고, 제거 조건을 함께 기록한다.

## Recommended Maven Shape

```xml
<parent>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-parent</artifactId>
	<version>3.5.9</version>
	<relativePath/>
</parent>

<properties>
	<java.version>21</java.version>
</properties>

<dependencies>
	<dependency>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-web</artifactId>
	</dependency>
	<dependency>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-test</artifactId>
		<scope>test</scope>
	</dependency>
</dependencies>
```

## Version Override Template

개별 버전 명시가 필요하면 작업 문서에 다음을 남긴다.

```md
Dependency override:
- dependency: `groupId:artifactId`
- version: `x.y.z`
- reason: Spring Boot BOM 미관리 / CVE 대응 / provider 요구사항
- source: Maven Central 또는 공식 문서 링크
- removal condition: Spring Boot BOM 반영 후 제거
```

## Checklist

- Spring Boot 관리 의존성에 불필요한 `<version>`이 없는가?
- 추가 repository가 꼭 필요한가?
- test/runtime scope가 분리되어 있는가?
- 버전 override 이유와 제거 조건을 기록했는가?
- 공식 문서 또는 Maven Central 기준으로 의존성을 확인했는가?
