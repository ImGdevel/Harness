# Husky Git Hook 컨벤션

## 문서 목적

이 문서는 프로젝트 저장소에 Husky를 세팅할 때 따라야 하는 표준 절차와 필수 스니펫을 정리한다.
Node.js 도구 체인이 repository root에 있는 프로젝트는 이 문서의 스니펫을 우선 복사한 뒤 프로젝트 상황에 맞게 최소 수정한다.

## 적용 원칙

- Husky v9를 사용한다.
- Husky는 repository root 기준으로 설정한다.
- hook 파일은 `.husky/` 아래에 둔다.
- root `package.json`에는 `prepare` script를 둔다.
- `pre-commit`에는 빠른 staged 검증만 둔다.
- `commit-msg`에는 커밋 메시지 검증을 둔다.
- hook 본문은 짧게 유지하고 실제 검증 로직은 `scripts/`로 위임한다.
- CI에서는 Husky hook에 의존하지 않고 동일한 검증 스크립트를 명시적으로 실행한다.
- 프로젝트 전용 규칙이 있으면 프로젝트 규칙이 우선한다.

## 스니펫 사용 규칙

프로젝트에 Husky를 추가할 때는 대화나 임시 메모에만 남기지 말고, 프로젝트 문서에 이 문서의 스니펫을 기준으로 세팅했다고 명시한다.

프로젝트 문서에 남길 문구 예시는 다음과 같다.

```md
Husky 세팅은 하네스 공통 문서 `common/convention/husky-git-hooks-convention.md`의 스니펫을 기준으로 구성한다.
프로젝트 차이로 수정한 부분은 이 문서에 별도로 기록한다.
```

## 표준 파일 구조

```text
package.json
.gitattributes
.husky/
  pre-commit
  commit-msg
scripts/
  validate-repo.mjs
  validate-commit-message.mjs
```

## 빠른 세팅

새 프로젝트에서는 Husky v9 공식 초기화 명령을 먼저 사용한다.

```sh
npm install --save-dev husky
npx husky init
```

`npx husky init`은 `.husky/pre-commit`을 만들고 `package.json`에 `prepare` script를 추가한다.
초기화 후에는 이 문서의 `package.json`, `.husky/pre-commit`, `.husky/commit-msg` 스니펫으로 내용을 정리한다.

## OS 공통 기준

macOS와 Windows에서 같은 hook이 동작해야 하므로 hook 파일에는 OS별 shell 명령을 직접 많이 넣지 않는다.
hook은 `npm run ...`만 호출하고, 실제 로직은 Node.js 스크립트로 작성한다.

공통 규칙은 다음과 같다.

- `.husky/*` 파일은 POSIX shell 호환 문법으로 작성한다.
- hook 파일 안에서 Bash 전용 문법은 피한다.
- Windows 전용 `.cmd`, PowerShell 문법은 hook 파일에 직접 넣지 않는다.
- 경로 처리는 Node.js 스크립트에서 `node:path`을 사용한다.
- hook 파일과 shell script는 LF line ending으로 고정한다.
- Windows에서는 Git for Windows와 Git Bash가 설치되어 있어야 한다.

## .gitattributes 스니펫

Windows에서 CRLF가 hook 파일에 들어가면 shell 실행 오류가 날 수 있다.
repository root에 `.gitattributes`를 두고 hook 관련 파일의 line ending을 LF로 고정한다.

```gitattributes
.husky/* text eol=lf
*.sh text eol=lf
*.mjs text eol=lf
```

이미 CRLF로 들어간 파일이 있다면 다음 명령으로 다시 정규화한다.

```sh
git add --renormalize .husky scripts
```

## macOS 세팅

macOS에서는 일반적으로 아래 순서로 충분하다.

```sh
npm install --save-dev husky
npx husky init
npm run prepare
git config core.hooksPath
```

hook 파일 실행 권한 문제가 있으면 다음 명령으로 Git index에 실행 권한을 기록한다.

```sh
git update-index --chmod=+x .husky/pre-commit .husky/commit-msg
```

## Windows 세팅

Windows에서는 PowerShell에서 세팅해도 되지만, hook 실행은 Git for Windows가 제공하는 shell 환경을 전제로 한다.
먼저 Git for Windows와 Node.js가 설치되어 있어야 한다.

PowerShell 기준 세팅 명령은 다음과 같다.

```powershell
npm install --save-dev husky
npx husky init
npm run prepare
git config core.hooksPath
```

`git config core.hooksPath` 결과가 `.husky/_`가 아니면 Husky가 제대로 설치되지 않은 상태다.
이 경우 `npm run prepare`를 다시 실행한다.

Windows에서 hook 파일을 작성할 때는 다음을 지킨다.

- `.husky/pre-commit`과 `.husky/commit-msg`에는 `npm run ...`만 둔다.
- `./gradlew`, `grep`, `sed`, `awk` 같은 Unix 명령을 hook 파일에 직접 넣지 않는다.
- Windows 경로인 `C:\...`를 hook 파일에 직접 넣지 않는다.
- 긴 검증 로직은 `.mjs` 파일로 옮긴다.

Windows에서 임시로 Husky를 끄는 명령은 shell마다 다르다.

```powershell
# PowerShell
$env:HUSKY = "0"
git commit -m "hotfix: 긴급 수정"
Remove-Item Env:HUSKY
```

```cmd
:: Command Prompt
set HUSKY=0 && git commit -m "hotfix: 긴급 수정"
```

```sh
# Git Bash
HUSKY=0 git commit -m "hotfix: 긴급 수정"
```

## Windows Git Bash와 Yarn 오류 대응

Windows 10, Git Bash, Yarn 조합에서 `stdin is not a tty` 오류가 발생할 수 있다.
이 경우 사용자별 Husky 초기화 파일에 공식 우회 스크립트를 둔다.

Windows 경로:

```text
C:\Users\<username>\.config\husky\init.sh
```

`init.sh` 내용:

```sh
command_exists () {
  command -v "$1" >/dev/null 2>&1
}

if command_exists winpty && test -t 1; then
  exec < /dev/tty
fi
```

특정 PC에서 Husky를 항상 비활성화해야 하면 같은 파일에 다음 값을 둘 수 있다.
다만 프로젝트 검증을 우회하는 설정이므로 기본값으로 사용하지 않는다.

```sh
export HUSKY=0
```

## package.json 스니펫

기본 스니펫은 다음과 같다.

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

`prepare`에는 `husky || true`를 둔다.
dev dependency가 설치되지 않는 환경에서도 package install 자체가 실패하지 않게 하기 위해서다.
CI에서는 별도로 `HUSKY=0`을 설정한다.

## pre-commit 스니펫

`.husky/pre-commit`은 repository-local 빠른 검증만 실행한다.

```sh
npm run validate:repo
```

권장 검증 범위는 다음과 같다.

- staged whitespace 검증
- 금지 경로 검증
- 생성 산출물 검증
- 빠르게 끝나는 lint 또는 format 검증

전체 테스트, 통합 테스트, 느린 빌드는 `pre-commit`에 넣지 않는다.
이 검증은 CI나 별도 명령에서 실행한다.

## commit-msg 스니펫

`.husky/commit-msg`는 Git이 넘겨주는 커밋 메시지 파일 경로를 검증 스크립트에 전달한다.

```sh
npm run validate:commit-message -- "$1"
```

Husky v9에서는 예전 `HUSKY_GIT_PARAMS` 대신 Git native parameter인 `$1`을 사용한다.

## validate-repo.mjs 스니펫

프로젝트별 금지 경로와 staged whitespace 검증을 최소 기준으로 둔다.

```js
import { execFileSync } from "node:child_process";

const forbiddenPrefixes = ["docs/", "review/", "검토-필요/"];

function runGit(args) {
  return execFileSync("git", args, { encoding: "utf8" });
}

runGit(["diff", "--cached", "--check"]);

const stagedFiles = runGit(["diff", "--cached", "--name-only"])
  .split(/\r?\n/)
  .filter(Boolean);

const forbiddenFiles = stagedFiles.filter((file) =>
  forbiddenPrefixes.some((prefix) => file.startsWith(prefix)),
);

if (forbiddenFiles.length > 0) {
  console.error("Forbidden staged paths:");
  for (const file of forbiddenFiles) {
    console.error(`- ${file}`);
  }
  process.exit(1);
}
```

금지 경로는 프로젝트 정책에 맞게 수정한다.
예를 들어 Techlog Hub는 문서를 GitHub Wiki에 두므로 main repo의 `docs/`를 금지할 수 있다.

## validate-commit-message.mjs 스니펫

커밋 메시지 제목은 한국어로 작성하고, 본문에는 변경 내용과 근거를 남긴다.

```js
import { readFileSync } from "node:fs";

const messagePath = process.argv[2];
const message = readFileSync(messagePath, "utf8").trim();
const [subject, ...bodyLines] = message.split(/\r?\n/);
const body = bodyLines.join("\n");

const allowedTypes = [
  "feat",
  "fix",
  "docs",
  "style",
  "refactor",
  "test",
  "chore",
  "build",
  "ci",
  "perf",
  "hotfix",
];

if (/^(Merge|Revert|fixup!|squash!)/.test(subject)) {
  process.exit(0);
}

const subjectPattern = new RegExp(
  `^(${allowedTypes.join("|")})(\\([a-z0-9-]+\\))?: .+`,
);

const errors = [];

if (!subjectPattern.test(subject)) {
  errors.push("제목은 <type>(optional-scope): <한국어 요약> 형식이어야 한다.");
}

if (!/[가-힣]/.test(subject)) {
  errors.push("커밋 메시지 제목은 한국어를 포함해야 한다.");
}

for (const label of ["What changed:", "Why:", "Evidence:"]) {
  if (!body.includes(label)) {
    errors.push(`본문에 ${label} 섹션이 필요하다.`);
  }
}

if (/(Generated with|Co-authored-by:|Co-committed-by:|Claude|Codex)/i.test(message)) {
  errors.push("AI attribution 또는 공동 작성 footer를 남기지 않는다.");
}

if (errors.length > 0) {
  console.error("Invalid commit message:");
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}
```

프로젝트가 다른 커밋 타입이나 본문 라벨을 쓰는 경우 이 스니펫을 프로젝트 컨벤션에 맞게 조정한다.

## 커밋 메시지 예시

```text
docs(convention): 허스키 세팅 가이드를 추가한다

What changed:
- Husky v9 설치 절차와 hook 스니펫을 추가했다.
- pre-commit과 commit-msg 검증 기준을 문서화했다.

Why:
- 프로젝트마다 Git hook 세팅 방식이 달라지는 문제를 줄이기 위해서다.

Evidence:
- npm run validate:repo
- npm run validate:commit-message -- .git/COMMIT_EDITMSG
```

## CI 스니펫

CI에서는 Husky 설치와 hook 실행을 비활성화하고, 필요한 검증 명령을 workflow에 직접 둔다.

```yaml
env:
  HUSKY: 0

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: npm run validate:repo
```

## 우회 명령

긴급 상황에서만 hook을 우회한다.
우회한 검증은 이후 별도 명령이나 CI에서 반드시 확인한다.

```sh
git commit --no-verify -m "hotfix: 긴급 수정"
HUSKY=0 git commit -m "hotfix: 긴급 수정"
```

Windows PowerShell에서는 inline `HUSKY=0` 문법을 사용할 수 없으므로 `Windows 세팅` 섹션의 PowerShell 예시를 따른다.

## 세팅 체크리스트

- [ ] `npm install --save-dev husky`를 실행했다.
- [ ] `npx husky init`을 실행했다.
- [ ] `.gitattributes`로 `.husky/*`의 LF line ending을 고정했다.
- [ ] `package.json`에 `prepare`, `validate:repo`, `validate:commit-message`가 있다.
- [ ] `.husky/pre-commit`이 `npm run validate:repo`를 실행한다.
- [ ] `.husky/commit-msg`가 `npm run validate:commit-message -- "$1"`을 실행한다.
- [ ] `scripts/validate-repo.mjs`가 staged 변경만 검증한다.
- [ ] `scripts/validate-commit-message.mjs`가 프로젝트 커밋 메시지 규칙을 검증한다.
- [ ] Windows에서도 `git config core.hooksPath`가 `.husky/_`를 출력한다.
- [ ] CI에 `HUSKY=0`이 설정되어 있다.
- [ ] CI가 Husky hook에 의존하지 않고 검증 스크립트를 직접 실행한다.

## 참고

- Husky v9 공식 setup: `npx husky init`
- Husky v9 prepare script: `prepare: husky`
- Husky v9 CI bypass: `HUSKY=0`
- Husky v9 commit-msg parameter: `$1`
- Husky v9 startup file: `~/.config/husky/init.sh`
