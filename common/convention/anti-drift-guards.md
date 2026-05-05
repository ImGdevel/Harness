# Anti-Drift Guards

## Purpose

Prevent four recurring failure modes during agent sessions: lost docs, lost context, blind trust, and snippet over-copy.

## 1. Index Lookup Guard

문제: 실제 문서가 존재하는데 `index.md`에 등록이 빠져 못 찾는다.

- 작업 시작 전에 `index.md`만 읽지 않는다.
- 대상 디렉터리에 대해 `index.md` 읽기와 디렉터리 listing(`Glob`/`ls`)을 함께 수행한다.
- listing 결과에 있는데 `index.md`에 없는 `.md` 파일이 있으면 누락으로 간주한다.
- 누락을 찾으면 우선 그 문서를 읽어 실체를 확인한 뒤, 같은 변경 흐름에서 `index-sync` job을 수행한다.
- 의심되는 경우 `scripts/audit-documentation-governance.ps1`을 실행해 누락 목록을 확정한다.

## 2. Long-Run Checkpoint Guard

문제: 컨텍스트가 길어지면 사용자 요구사항, 진행 상태, 결정 근거를 잃는다.

- 작업이 단일 step보다 큰 경우 `plan-sync` job을 우선 실행해 plan 문서를 만든다.
- plan 문서에는 목표, 범위, 단계 체크리스트, 진행 상태, 미해결 결정을 적는다.
- 단계가 끝날 때마다 plan 문서의 체크리스트를 갱신한다.
- 컨텍스트 압축 또는 세션 재시작 위험이 보이면 직전 상태를 plan 문서에 즉시 기록한다.
- 새 세션은 plan 문서 재읽기로 시작한다.
- plan 위치는 `<project-root>/docs/plan/` 또는 registry의 `plan_path`를 따른다.

## 3. Verify-Before-Cite Guard

문제: 문서, 메모리, 이전 대화에서 본 파일 경로/심볼/명령을 실제 존재 확인 없이 그대로 인용한다.

- 문서나 메모리가 특정 파일 경로를 명시하면 적용 전에 `Read` 또는 `Glob`으로 존재를 확인한다.
- 함수, 클래스, 환경변수, CLI 플래그를 인용하면 `Grep`으로 현재 코드에 실제 존재하는지 확인한다.
- 명령이나 스크립트를 추천하면 해당 파일이 저장소에 있는지 먼저 확인한다.
- 검증 없이 인용 가능한 정보는 일반 개념 설명뿐이다.
- 메모리와 현재 상태가 충돌하면 현재 상태를 신뢰하고 메모리를 갱신한다.

## 4. Snippet Adaptation Guard

문제: `stack/<framework>/snippets/`의 예시는 도메인이 박힌 구체 코드라서 그대로 복사하면 작업 도메인을 오염시킨다.

- snippet은 패턴 참고 자료다. 그대로 붙여넣지 않는다.
- 적용 전에 도메인 식별자를 작업 컨텍스트로 치환한다. 대상:
  - 클래스/인터페이스 이름 (예: `PublicPostController` → 작업 도메인 컨트롤러 이름)
  - 필드/파라미터/변수 이름
  - URL 경로, 쿼리 파라미터, JSON 키
  - 예외/에러코드 식별자
- snippet의 `import`, util, exception 클래스는 작업 저장소에 동일 클래스가 있는지 `Grep`으로 확인한 뒤 사용한다.
- snippet에만 있고 작업 저장소에 없는 의존성은 추가 전에 사용자에게 확인한다.
- snippet의 비즈니스 규칙(검증 조건, 정렬 기준, 권한 규칙)은 작업 요구사항으로 다시 도출한다.
- snippet에서 따라야 할 부분은 구조와 책임 분리다. 도메인 값이 아니다.

## Checklist

- 작업 디렉터리의 `index.md`와 listing을 모두 확인했는가?
- 큰 작업이면 plan 문서를 만들고 단계마다 갱신했는가?
- 인용한 파일/심볼/명령이 현재 저장소에 실제 존재하는지 확인했는가?
- snippet의 도메인 식별자와 의존성을 작업 컨텍스트로 치환했는가?

## References

- [documentation-governance.md](</C:/Users/imdls/workspace/Project Workspace/common/convention/documentation-governance.md>)
- [project-artifact-conventions.md](</C:/Users/imdls/workspace/Project Workspace/common/convention/project-artifact-conventions.md>)
- [workflow-catalog.md](</C:/Users/imdls/workspace/Project Workspace/common/spec/workflow-catalog.md>)
