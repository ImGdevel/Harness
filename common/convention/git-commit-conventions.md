# Git Commit Conventions

이 문서는 실제 프로젝트 Git 저장소에 기본 적용하는 커밋 규칙을 정의한다.

## Core Rules

- 커밋은 하나의 의도만 담는다.
- 기능 변경, 리팩터링, 포맷 변경, 문서 수정은 가능하면 분리한다.
- 관련 없는 파일은 같은 커밋에 넣지 않는다.
- 커밋 전에 변경 범위를 다시 확인한다.
- 하네스 저장소 Git과 실제 프로젝트 Git 저장소를 혼동하지 않는다.
- 사용자가 명시하지 않았다면 이 규칙의 기본 대상은 registry가 가리키는 실제 프로젝트 저장소다.

## Commit Timing

- 최소한 변경 범위가 설명 가능한 시점에 커밋한다.
- 깨진 상태, 임시 디버깅 코드, 비밀값 포함 상태로 커밋하지 않는다.
- 테스트나 검증 명령이 있는 저장소라면 가능한 한 검증 후 커밋한다.

## Commit Message Format

기본 형식:

```text
type(scope): summary
```

예시:

```text
feat(auth): add token refresh flow
fix(api): handle empty search query
docs(payment): document settlement flow
```

## Recommended Types

- `feat`: 사용자 기능 추가
- `fix`: 버그 수정
- `refactor`: 동작 변화 없는 구조 개선
- `docs`: 문서 수정
- `test`: 테스트 추가 또는 수정
- `chore`: 설정, 정리, 운영 작업
- `build`: 빌드 설정, 의존성, 패키징 변경
- `ci`: CI/CD 설정 변경

## Scope Rule

- `scope`는 가능한 한 실제 변경 영역을 짧게 쓴다.
- 예시: `workspace`, `auth`, `api`, `payment`, `ui`, `docs`
- 적절한 scope가 없으면 생략 가능하다.

## Message Writing Rule

- summary는 영어 현재형 동사로 짧게 작성한다.
- 첫 글자는 소문자를 기본으로 한다.
- 마침표는 붙이지 않는다.
- 이슈 번호를 커밋 메시지에 기본 포함하지 않는다.
- "update stuff", "fix bug", "wip" 같은 모호한 표현은 금지한다.

## Commit Body

필요할 때만 본문을 추가한다.

- 왜 이 변경이 필요한지
- 어떤 제약이나 트레이드오프가 있는지
- 후속 작업이 무엇인지

## Do Not

- 여러 의도의 변경을 한 커밋에 섞지 않는다.
- 자동 생성 파일과 수동 수정 파일을 무분별하게 같이 넣지 않는다.
- 의미 없는 대량 포맷 변경을 기능 커밋과 같이 넣지 않는다.
- `WIP`를 기본 커밋 메시지로 사용하지 않는다.
- 이슈 번호만으로 커밋 의미를 대신하지 않는다.
