# Husky Git Hook 컨벤션

## 목적

프로젝트 저장소에서 로컬 Git hook 실행기로 Husky를 사용한다.
Node.js 도구 체인이 repository root에 있을 때 기본값으로 적용한다.

## 기본 원칙

- Husky v9를 사용한다.
- Husky 설정은 repository root에 둔다.
- hook 파일은 `.husky/` 아래에 둔다.
- root `package.json`에는 `prepare` script를 둔다.
- CI, production Docker build, 긴급 우회 명령에서는 `HUSKY=0`을 사용한다.
- 오래 걸리는 전체 테스트를 `pre-commit`에 넣지 않는다.
- 빠른 staged 검증은 `pre-commit`에서 실행한다.
- 커밋 메시지 검증은 `commit-msg`에서 실행한다.
- hook 본문은 짧게 유지하고 실제 로직은 `scripts/`로 위임한다.
- Husky hook을 CI 검증의 유일한 기준으로 쓰지 않는다.
- 프로젝트 코드가 아직 없어도 Husky 설치가 가능해야 한다.

## 표준 파일 구조

```text
package.json
.husky/
  pre-commit
  commit-msg
scripts/
  validate-repo.mjs
  validate-commit-message.mjs
```

## package.json 기준

기본 script는 다음과 같이 둔다.

```json
{
  "scripts": {
    "prepare": "husky || true",
    "validate:repo": "node scripts/validate-repo.mjs",
    "validate:commit-message": "node scripts/validate-commit-message.mjs"
  },
  "devDependencies": {
    "husky": "9.1.7"
  }
}
```

dev dependency가 없는 환경에서도 install 실패를 피해야 한다면 `prepare`에는 `husky || true`를 사용한다.
CI에서는 별도로 `HUSKY=0`을 설정한다.

## Hook 정책

`pre-commit`에는 repository-local 빠른 검증만 둔다.

예시:

- staged whitespace 검증
- 금지 경로 검증
- 생성 산출물 검증
- frontend package가 있는 경우 `lint-staged`

`commit-msg`에는 커밋 메시지 계약 검증을 둔다.

예시:

- conventional subject prefix
- 프로젝트가 요구하는 경우 한국어 제목
- 필수 본문 라벨
- 금지 attribution 문구

## 커밋 메시지 계약

기본 프로젝트 계약은 다음과 같다.

```text
<type>(optional-scope): <한국어 요약>

What changed:
- ...

Why:
- ...

Evidence:
- ...
```

허용 커밋 타입은 프로젝트별로 더 엄격하게 제한할 수 있다.
프로젝트 전용 커밋 컨벤션이 있으면 프로젝트 컨벤션이 우선한다.

## CI 기준

GitHub Actions에서는 기본적으로 다음 값을 둔다.

```yaml
env:
  HUSKY: 0
```

CI는 로컬 hook에 의존하지 않고 동일한 검증 스크립트를 명시적으로 실행해야 한다.

## 참고

- Husky v9 공식 setup: `npx husky init`
- Husky v9 prepare script: `prepare: husky`
- Husky v9 CI bypass: `HUSKY=0`
