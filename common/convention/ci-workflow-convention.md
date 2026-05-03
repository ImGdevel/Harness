# CI Workflow Convention

## Purpose

PR 이후 실행되는 지속적 통합 파이프라인의 공통 기준을 정의한다.
CI는 로컬 hook을 대체하지 않고, 로컬에서 빠르게 막아야 할 검증과 PR에서 병렬로 수행할 검증을 분리한다.

## Source Basis

- GitHub Actions workflow syntax: `needs`로 job dependency를 만들고, 서로 `needs`가 없는 job은 병렬로 실행한다.
- GitHub Actions concurrency: 같은 branch 또는 PR의 이전 run을 취소해 runner 낭비를 줄인다.
- GitHub dependency review action: PR에서 새 dependency 취약점과 license 정책을 빠르게 확인한다.
- Gradle Actions / setup-java cache: Gradle dependency, wrapper, user home cache로 cold start 시간을 줄인다.
- `actions/checkout@v6`, `actions/setup-node@v6`, `actions/setup-java@v5`를 기본값으로 사용한다.
- Node 기반 repository tooling은 Node 24를 기본값으로 사용한다.

## Execution Boundary

| Stage | Trigger | Required Checks | Not Allowed |
| --- | --- | --- | --- |
| `pre-commit` | commit 전 | staged whitespace, 금지 경로, commit 전 빠른 정적 검증 | 전체 테스트, 통합 테스트, 네트워크 보안 스캔 |
| `pre-push` | push 전 | unit test, repository policy 검증 | DB/container 기반 통합 테스트, 외부 API 호출 |
| `pull_request CI` | PR 생성/갱신 | policy, unit, integration, security 병렬 실행 | 직렬 long pipeline 구성 |
| `scheduled/manual security` | 야간/수동 | CodeQL, 깊은 SCA, container/image scan | PR feedback을 과도하게 지연시키는 blocking 구성 |

## Local Hook Contract

Husky `pre-push`는 PR CI의 축소판이 아니다.
push 전에 막을 것은 빠른 실패뿐이다.

```sh
npm run validate:repo
npm run test:unit
```

Gradle wrapper를 npm script로 감싸면 Windows와 macOS/Linux에서 같은 명령을 사용할 수 있다.

```json
{
  "scripts": {
    "test:unit": "node scripts/run-gradle.mjs :apps:api:unitTest --build-cache --configuration-cache",
    "test:integration": "node scripts/run-gradle.mjs :apps:api:integrationTest --build-cache --configuration-cache"
  }
}
```

통합 테스트, dependency review, CodeQL, 외부 네트워크 기반 scan은 `pre-push`에 넣지 않는다.

## Setup Order

CI는 다음 순서로 구축한다.

1. 설계 문서에 pre-push/PR 경계와 병렬 job 책임을 먼저 고정한다.
2. 테스트를 `unit`과 `integration`으로 분리하고 로컬에서 두 task가 모두 통과하는지 확인한다.
3. Husky `pre-push`에는 repository policy와 unit test만 넣는다.
4. PR workflow는 policy, unit, integration, security를 병렬 job으로 구성한다.
5. 모든 병렬 job을 `needs`로 모은 뒤 Discord 알림 job을 둔다.
6. GitHub repository secret과 security analysis 설정을 확인한다.
7. 첫 PR CI 실패는 트러블슈팅 문서로 남긴다.

## PR CI Shape

PR CI는 fan-out/fan-in 구조를 기본으로 한다.

```text
pull_request
  -> policy-check      ┐
  -> unit-test         ├─ parallel
  -> integration-test  │
  -> security-scan     ┘
        ↓ needs: [all]
  -> notify-discord
```

## Required Workflow Rules

- Workflow name은 reviewer가 바로 이해할 수 있게 `CI` 또는 `Pull Request CI`로 쓴다.
- Trigger는 기본적으로 `pull_request`와 `workflow_dispatch`를 둔다.
- `push` trigger는 `develop`, `main` 같은 long-lived branch에만 둔다.
- `concurrency.group`은 `${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}` 형태로 같은 PR의 이전 run만 취소한다.
- `permissions`는 job에 필요한 최소 권한만 둔다.
- PR job은 병렬 실행한다. 하나의 큰 `verify` job에 policy/test/security를 모두 넣지 않는다.
- 최종 알림 job은 `if: ${{ always() }}`와 `needs`를 함께 사용해 성공/실패/취소를 모두 보고한다.
- Discord webhook URL은 repository secret으로만 읽는다. workflow 파일에 URL을 직접 쓰지 않는다.
- fork PR 또는 초기 설정 전에는 secret이 없을 수 있으므로 Discord 알림 step은 webhook이 없으면 skip한다.
- Discord 알림 실패는 CI 본문 결과를 뒤집지 않도록 처리한다.
- Linux runner에서 Gradle wrapper를 실행하려면 `gradlew`가 Git index에서 executable bit를 가져야 한다.

```bash
git update-index --chmod=+x gradlew
```

## Recommended PR Jobs

| Job | Target Runtime | Responsibility |
| --- | --- | --- |
| `policy-check` | < 30s | repository policy, generated file, forbidden path, workflow syntax |
| `unit-test` | < 60s | pure unit test, DTO/util/policy test |
| `integration-test` | < 120s | Spring context, MVC slice, JPA/Flyway/H2, Testcontainers |
| `security-scan` | < 60s | dependency review, secret scan, fast supply-chain gate |
| `notify-discord` | < 10s | all job result summary |

PR feedback loop 목표는 총 3분 내외다.
긴 정적 분석이나 full CodeQL이 3분을 안정적으로 넘으면 PR blocking job에 넣지 않고 scheduled/manual job으로 분리한다.

## Cache Rules

- Java/Gradle 프로젝트는 `gradle/actions/setup-gradle` 또는 `actions/setup-java` Gradle cache 중 하나를 명시적으로 사용한다.
- 같은 cache 영역을 여러 action이 동시에 관리하지 않는다.
- Gradle task는 `--build-cache`를 기본으로 사용한다.
- `--configuration-cache`는 프로젝트에서 한 번 검증한 뒤 CI에 켠다.
- PR branch cache는 기본 branch cache를 restore할 수 있지만, 신뢰되지 않은 branch가 default branch cache를 오염시키지 않도록 read-only cache 정책을 검토한다.
- Node 기반 repository policy가 있으면 `actions/setup-node@v6`의 npm cache를 사용한다.

```yaml
- uses: actions/setup-node@v6
  with:
    node-version: 24
    cache: npm
```

```yaml
- uses: actions/setup-java@v5
  with:
    distribution: temurin
    java-version: 21
```

## Fast Security Gate

PR에서 기본으로 권장하는 빠른 security gate는 다음이다.

```yaml
security-scan:
  runs-on: ubuntu-latest
  permissions:
    contents: read
  steps:
    - uses: actions/checkout@v6
    - uses: actions/setup-node@v6
      with:
        node-version: 24
        cache: npm
    - run: npm ci
    - id: dependency-review
      uses: actions/dependency-review-action@v4
      if: ${{ github.event_name == 'pull_request' }}
      continue-on-error: true
      with:
        fail-on-severity: high
    - name: Report dependency review limitation
      if: ${{ steps.dependency-review.outcome == 'failure' }}
      run: |
        echo "::warning::Dependency Review did not complete. Enable Dependency graph to make this gate blocking."
    - run: npm audit --audit-level=high
    - run: npm run security:secrets
```

Dependency Review는 repository dependency graph 설정에 의존한다.
Dependency graph가 활성화된 저장소에서는 `continue-on-error`를 제거하고 blocking gate로 승격한다.
설정 전에는 warning으로 남기되 `npm audit`이나 lockfile 기반 SCA, secret scan처럼 코드 기반으로 실행 가능한 gate를 blocking으로 둔다.

CodeQL은 좋은 선택이지만 Java/Spring 프로젝트에서 build/analyze 시간이 길어질 수 있다.
MVP PR CI에서는 빠른 SCA와 secret scan을 먼저 붙이고, CodeQL은 다음 중 하나로 운영한다.

- PR runtime이 안정적으로 3분 안에 들어오면 PR blocking job으로 승격한다.
- 3분을 넘으면 `schedule`, `workflow_dispatch`, `push to main/develop` 전용 workflow로 분리한다.

## Discord Notification Snippet

```yaml
notify-discord:
  runs-on: ubuntu-latest
  needs: [policy-check, unit-test, integration-test, security-scan]
  if: ${{ always() }}
  env:
    DISCORD_WEBHOOK_URL: ${{ secrets.DISCORD_WEBHOOK_URL }}
  steps:
    - name: Skip when webhook is absent
      if: ${{ env.DISCORD_WEBHOOK_URL == '' }}
      run: echo "DISCORD_WEBHOOK_URL is not configured. Skip Discord notification."
    - name: Send Discord notification
      if: ${{ env.DISCORD_WEBHOOK_URL != '' }}
      env:
        POLICY_RESULT: ${{ needs.policy-check.result }}
        UNIT_RESULT: ${{ needs.unit-test.result }}
        INTEGRATION_RESULT: ${{ needs.integration-test.result }}
        SECURITY_RESULT: ${{ needs.security-scan.result }}
      run: |
        if [ -z "$DISCORD_WEBHOOK_URL" ]; then
          echo "DISCORD_WEBHOOK_URL is not configured. Skip notification."
          exit 0
        fi
        python - <<'PY'
        import json, os
        status = "success"
        results = [
            os.environ["POLICY_RESULT"],
            os.environ["UNIT_RESULT"],
            os.environ["INTEGRATION_RESULT"],
            os.environ["SECURITY_RESULT"],
        ]
        if "failure" in results:
            status = "failure"
        elif "cancelled" in results:
            status = "cancelled"
        payload = {
            "embeds": [{
                "title": f"CI {status}",
                "description": "\\n".join([
                    f"policy: {os.environ['POLICY_RESULT']}",
                    f"unit: {os.environ['UNIT_RESULT']}",
                    f"integration: {os.environ['INTEGRATION_RESULT']}",
                    f"security: {os.environ['SECURITY_RESULT']}",
                ]),
            }]
        }
        with open("discord-payload.json", "w", encoding="utf-8") as file:
            json.dump(payload, file)
        PY
        curl -fsS -H "Content-Type: application/json" -d @discord-payload.json "$DISCORD_WEBHOOK_URL" || true
```

## Troubleshooting Record Rule

CI 구축 또는 운영 중 다음 문제가 발생하면 프로젝트 문서 원천에 트러블슈팅 기록을 남긴다.

- runner OS 차이로 local pass / CI fail이 발생한 경우
- dependency graph, secret, repository setting처럼 workflow 파일 밖의 설정이 원인인 경우
- cache, permission, wrapper 실행 권한 때문에 CI가 실패한 경우
- 알림, review bot, external integration이 skip 또는 failure로 끝난 경우

기록 위치는 프로젝트 registry의 문서 원천을 따른다.
`docs_source: wiki` 프로젝트는 Wiki troubleshooting 페이지에 남기고, 일반 프로젝트는 `<project-root>/docs/troubleshooting/`에 남긴다.

필수 내용은 문제 증상, 원인, 조치, 검증 run 또는 commit, 재발 방지 인사이트다.

## Review Checklist

- `pre-push`와 PR CI의 테스트 책임이 분리되어 있는가?
- PR CI job이 병렬 fan-out 구조인가?
- 최종 알림 job이 `always()`로 실패도 보고하는가?
- Gradle/Node cache가 설정되어 있는가?
- secret 값이 workflow 파일에 직접 들어가지 않았는가?
- 3분 목표를 넘을 가능성이 큰 scan은 scheduled/manual로 분리했는가?
- Dependency Review가 repository dependency graph 설정 상태에 맞게 blocking 또는 warning으로 구성되어 있는가?
- `gradlew` 실행 권한과 GitHub Actions secret 설정을 확인했는가?
- CI 실패가 발생했다면 troubleshooting record가 남았는가?

## References

- GitHub Actions workflow syntax and `needs`: https://docs.github.com/en/actions
- GitHub Actions concurrency: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- GitHub Dependency Review: https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-dependency-review
- Gradle build cache and configuration cache: https://docs.gradle.org/current/userguide/performance.html
- `actions/setup-node`: https://github.com/actions/setup-node
- `actions/setup-java`: https://github.com/actions/setup-java
