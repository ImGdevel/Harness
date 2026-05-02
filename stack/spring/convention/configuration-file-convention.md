# Spring 설정 파일 생성 컨벤션

## Purpose

Spring Boot 프로젝트를 새로 만들 때 설정 파일 포맷을 명확히 결정하고, 실제 생성 파일과 프로젝트 문서가 같은 결정을 따르도록 한다.

## Rules

- Spring Boot 프로젝트의 기본 설정 파일 포맷은 `application.yml`이다.
- profile 설정 파일은 `application-<profile>.yml` 형식을 사용한다.
- `application.properties`와 `application-*.properties`는 기본 생성하지 않는다.
- 사용자가 properties를 명시적으로 요구하면 프로젝트 문서에 예외 사유를 남긴다.
- scaffold 도구가 properties 파일을 만들면 즉시 YAML로 변환하거나 제거한다.
- 같은 application config 위치에서 YAML과 properties를 혼용하지 않는다.
- 다른 포맷을 임시로 추가해야 하면 이유와 제거 조건을 프로젝트 문서에 기록한다.
- Spring Boot는 같은 위치에 YAML과 properties가 함께 있으면 properties를 우선하므로, 혼용은 충돌 위험으로 본다.

## Creation Snippet

YAML을 선택한 프로젝트는 다음 파일 구조로 생성한다.

```text
src/main/resources/application.yml
src/main/resources/application-local.yml
src/test/resources/application-test.yml
```

## Decision Template

```md
Spring 설정 파일 포맷:
- 선택 포맷: `application.yml`
- profile 파일: `application-<profile>.yml`
- 예외 여부: 없음
- 혼용 정책: 금지
```

properties 예외가 필요하면 다음을 추가한다.

```md
Spring config file exception:
- selected format: `application.properties`
- reason:
- requested by:
- removal or revisit condition:
```

## Review Checklist

- 프로젝트 문서에 설정 파일 포맷 결정이 있는가?
- 실제 생성 파일이 프로젝트 결정과 일치하는가?
- `src/main/resources`와 `src/test/resources`에 선택하지 않은 포맷의 `application.*` 파일이 남아 있지 않은가?
- profile 파일도 같은 포맷을 쓰는가?
- 설정 파일 포맷 변환 후 테스트가 통과했는가?
