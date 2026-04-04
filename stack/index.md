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

## Coverage Snapshot

- `spring/`
  convention, spec, test, entity 영역에 실질 문서가 들어가 있는 가장 성숙한 스택이다.
- `fastapi/`
  convention 기준 문서부터 채우기 시작한 상태다.
- `react/`
  convention 기준 문서부터 채우기 시작한 상태다.
- `spring-webflux/`
  reactive controller/service 기준 문서부터 채우기 시작한 상태다.

## Rule

- 프레임워크 공통 탐색의 시작점은 이 인덱스다.
- 세부 규칙은 각 하위 프레임워크 루트에서 관리한다.
- 실제 프로젝트 레지스트리는 루트 `project/`에서 관리하고, 실제 저장소는 하네스 밖 경로에 둔다.
