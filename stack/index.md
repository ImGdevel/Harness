# Stack Index

모든 프레임워크 스택을 함께 관리하는 상위 인덱스다.

## Frameworks

- `spring/`
  전통적인 Spring 기반 문서와 스니핏을 관리한다.
- `spring-webflux/`
  Spring WebFlux 기반 문서와 스니핏을 관리한다.
- `fastapi/`
  FastAPI 기반 문서와 스니핏을 관리한다.
- `react/`
  React 기반 문서와 스니핏을 관리한다.

## Rule

- 프레임워크 공통 탐색의 시작점은 이 인덱스다.
- 세부 규칙은 각 하위 프레임워크 루트에서 관리한다.
- 실제 프로젝트는 프레임워크 폴더 아래가 아니라 루트 `project/`에서 관리한다.
