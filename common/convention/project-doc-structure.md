# Project Doc Structure

이 문서는 프로젝트 컨테이너 `docs/` 아래에 유지할 표준 문서 구조를 정의한다.

## Goal

- 프로젝트 문서를 빠르게 찾을 수 있게 한다.
- 설계, 데이터, 인프라, 보안, 로컬 환경 정보를 한 곳에 정리한다.
- 프로젝트마다 문서 위치가 달라지는 문제를 줄인다.

## Required Baseline Tree

프로젝트 컨테이너의 `docs/`는 최소한 아래 구조를 가진다.

```text
project/<project-name>/docs/
  index.md
  api/
    index.md
  architecture/
    index.md
  convention/
    index.md
  domain-tech-spec/
    index.md
  erd/
    index.md
  infrastructure/
    index.md
  local-setup/
    index.md
  references/
    index.md
  security/
    index.md
  stack-selection/
    index.md
```

## Section Purpose

- `api/`
  HTTP, gRPC, event, webhook, external contract 문서를 둔다.
- `architecture/`
  시스템 구조, 계층, 모듈 경계, 런타임 흐름 문서를 둔다.
- `convention/`
  프로젝트 고유 코드 규칙, 브랜치 운영 예외, 네이밍 규칙 같은 프로젝트 전용 규칙 문서를 둔다.
- `domain-tech-spec/`
  도메인별 기술 스펙, 핵심 유스케이스, 상태 전이, 정책 문서를 둔다.
- `erd/`
  엔티티 관계, 테이블 구조, 데이터 모델, 저장소 관점 문서를 둔다.
- `infrastructure/`
  배포 구조, 네트워크, 클라우드 리소스, 운영 인프라 문서를 둔다.
- `local-setup/`
  로컬 개발 환경 구성, 필수 도구, 실행 순서, 환경 변수 규칙 문서를 둔다.
- `references/`
  외부 서비스, 도메인 참고자료, 링크 모음, 운영 참고 문서를 둔다.
- `security/`
  인증/인가, 비밀값 처리, 권한 모델, 보안 점검 기준 문서를 둔다.
- `stack-selection/`
  기술 스택 선정 근거, 대안 비교, 채택 이유, 제외 이유를 둔다.

## Index Rule

- `docs/index.md`는 전체 프로젝트 문서의 진입점이다.
- 각 하위 폴더도 `index.md`를 가져야 한다.
- 하위 `index.md`는 문서 목록과 한 줄 설명 중심으로 유지한다.

## Optional Extensions

프로젝트 특성에 따라 아래 폴더를 추가할 수 있다.

- `decisions/`: ADR, 중요한 설계 결정 기록
- `integration/`: 외부 시스템 연동 상세
- `operations/`: 운영 절차, 장애 대응, 배치/스케줄 문서

추가 폴더를 만들면 `docs/index.md`에도 같이 등록한다.

## Placement Rules

- 문서는 가장 가까운 의미의 폴더에 둔다.
- 같은 문서를 여러 폴더에 중복 저장하지 않는다.
- 프로젝트 공통 규칙은 `docs/convention/`, 유지보수 기록은 컨테이너 루트 `troubleshooting/`, 계획은 컨테이너 루트 `plan/`으로 분리한다.
