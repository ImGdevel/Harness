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
- `nextjs/`
  Next.js 기반 문서와 스니핏을 관리한다.
- `unity/`
  Unity 기반 게임 프로젝트의 사전기획, 스택 선택, 초기 의사결정 문서를 관리한다.
- `image-generation/`
  이미지 생성 중심 워크스페이스의 브리프, 레퍼런스, 워크플로우, 산출물 관리 기준을 둔다.

## Coverage Snapshot

- `spring/`
  convention, spec, test, entity 영역에 실질 문서가 들어가 있는 가장 성숙한 스택이다.
- `fastapi/`
  convention 기준 문서부터 채우기 시작한 상태다.
- `react/`
  convention 기준 문서부터 채우기 시작한 상태다.
- `nextjs/`
  App Router와 렌더링 경계 규칙부터 채우기 시작한 상태다.
- `spring-webflux/`
  reactive controller/service 기준 문서부터 채우기 시작한 상태다.
- `unity/`
  프로젝트 생성 전에 확정해야 할 Unity 사전기획 기준 문서부터 채우기 시작한 상태다.
- `image-generation/`
  이미지 생성 작업을 재현 가능하게 관리하기 위한 기본 인덱스부터 채운 상태다.

## Rule

- 프레임워크 공통 탐색의 시작점은 이 인덱스다.
- 세부 규칙은 각 하위 프레임워크 루트에서 관리한다.
- 실제 프로젝트 레지스트리는 루트 `project/`에서 관리하고, 실제 저장소는 하네스 밖 경로에 둔다.
