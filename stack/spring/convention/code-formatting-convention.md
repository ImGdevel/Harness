# Spring Code Formatting Convention

Tasteam 백엔드 위키의 코드 스타일 문서를 Spring 공통 하네스용으로 일반화한 문서다.
목적은 코드 포맷과 기본 스타일 규칙을 팀 단위로 고정해, 리뷰 비용과 불필요한 diff를 줄이는 데 있다.

## Formatter Rule

- Java 코드는 formatter를 프로젝트 단위로 하나만 사용한다.
- 팀이 formatter를 정했으면 IDE 기본 포맷터를 섞어 쓰지 않는다.
- 저장 시 자동 포맷과 CI 포맷 검사는 동일한 규칙을 써야 한다.

권장 예시:

- Gradle: `spotlessCheck`, `spotlessApply`
- formatter 파일: Eclipse formatter XML 또는 팀 표준 formatter 설정 파일

## Import Order

권장 import 순서:

1. `static`
2. `java`
3. `javax` 또는 `jakarta`
4. `org`
5. `net`
6. `com`
7. 그 외

IDE 설정도 빌드 검사와 같은 순서를 사용해야 한다.

## IDE Alignment

- formatter 플러그인을 쓰는 경우, 팀 formatter 파일을 IDE에 연결한다.
- import 정렬 규칙도 IDE에 동일하게 반영한다.
- 저장 시 자동 정렬이 CI 결과와 달라지지 않게 맞춘다.

## Commit Gate

- 커밋 전 formatter 검사를 통과해야 한다.
- formatter 위반은 로직 변경과 분리해서 먼저 정리하거나, 같은 의도의 변경 안에서만 함께 반영한다.
- 포맷 변경만 있는 대규모 수정은 기능 변경 커밋과 섞지 않는다.

## Review Checklist

- formatter 설정이 빌드 설정과 일치하는가
- import 순서가 팀 규칙과 일치하는가
- 불필요한 공백/개행 변경이 로직 변경과 섞이지 않았는가
- 포맷 수정이 대규모 리팩터링처럼 보이도록 diff를 오염시키지 않는가
