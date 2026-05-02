# Discode

Discord에서 Agent 봇에게 Codex 작업 요청을 보내고, 같은 Agent 봇이 로컬 Codex App Server를 직접 실행한 뒤 결과를 답글로 보고하는 로컬 브리지다.

## What It Does

- `/codex task prompt:<text>`: Agent가 즉시 로컬 Codex App Server에 작업을 실행한다.
- `/codex status`: 봇 상태, 현재 작업, 현재 Codex thread를 확인한다.
- `/codex threads`: 현재 워크스페이스의 최근 Codex App Server thread를 확인한다.
- `/codex thread-set thread_id:<id>`: Agent가 이어갈 Codex thread id를 직접 지정한다.
- `/codex thread-new`: 저장된 thread id를 지워 다음 작업에서 새 thread를 만든다.
- `/codex done summary:<text>`: Agent가 완료 알림 메시지를 보낸다.
- Agent가 보낸 완료 메시지에 답글을 달면 그 답글 본문을 즉시 다음 Codex 작업으로 실행한다.
- `npm run notify -- "summary" "details"`와 `npm run start:runner`는 남아 있지만 기본 운영 흐름에서는 필요 없다.

이 앱은 Discord 입력을 임의 셸 명령으로 실행하지 않는다. Agent가 `codex app-server`의 JSON-RPC 메서드(`thread/resume`, `turn/start`)로 Codex thread에 작업을 추가한다.

## Documents

- [Architecture](docs/ARCHITECTURE.md)
- [Security Notes](docs/SECURITY.md)

## Setup

1. Discord Developer Portal에서 애플리케이션과 봇을 만든다.
2. 봇 토큰, Application ID, 테스트 서버 ID를 준비한다. webhook URL은 수동 fallback 알림을 쓸 때만 필요하다.
3. 이 디렉터리에서 `.env.example`을 참고해 `.env`를 만든다.
4. 패키지를 설치하고 slash command를 등록한다.

```powershell
npm install
npm run register
npm start
```

이제 기본 구조에서는 runner가 필요 없다. 봇 하나만 실행하면 된다.

```powershell
npm start
```

## Required Discord Settings

- Bot scope: `bot`, `applications.commands`
- Bot permission: slash command만 쓰는 경우 높은 권한은 필요 없다.
- Gateway intent:
  - slash command만 쓰면 `Guilds`만 사용한다.
  - 완료 보고에 답글을 달아 다음 명령으로 쓰려면 Developer Portal의 Bot 메뉴에서 `Message Content Intent`를 켜고 `.env`의 `ENABLE_REPLY_CAPTURE=true`를 설정한다.
- 빠른 테스트는 `DISCORD_GUILD_ID`를 설정한 guild command 등록을 권장한다.

## Notification CLI

주요 작업 완료 시 수동 알림이 필요하면 아래처럼 보낼 수 있다. 단, 기본 작업 완료 보고는 Agent 봇이 직접 보낸다.

```powershell
npm run notify -- "작업 완료" "검토할 요약 내용"
```

두 번째 인자는 이제 Discord 완료 메시지 본문 안에 `세부 작업` 섹션으로 들어간다.

Agent가 보낸 완료 메시지가 Discord에 올라오면 해당 메시지에 답글로 다음 지시를 남긴다.

```text
이제 테스트 실패한 부분부터 고쳐줘
```

봇은 허용된 사용자 답글만 받아 즉시 Codex App Server 작업으로 실행한다.

## Discord Message Colors

- 파란색: 일반 안내
- 보라색: 원격 작업 요청 접수
- 노란색: 작업 시작
- 초록색: 작업 완료 및 검토 대기. 이 메시지에 답글을 달면 다음 작업으로 실행된다.
- 빨간색: 작업 실패 또는 Agent 오류

## Direct Agent Runner

기본 실행 경로는 큐 없는 직결 구조다.

```text
Discord 메시지 또는 slash command
-> Agent 봇
-> codex app-server
-> thread/start 또는 thread/resume
-> turn/start
-> Agent 봇의 완료 답글
-> Codex Desktop thread 딥링크 재오픈
```

첫 작업은 `thread/start`로 새 Codex App Server thread를 만들고, 응답의 `thread.id`를 `data/runner-state.json`에 저장한다. 이후 작업은 `thread/resume`으로 같은 thread를 불러온 뒤 `turn/start`로 Discord 메시지를 추가한다. 특정 thread를 강제로 쓰려면 `.env`의 `CODEX_RUNNER_THREAD_ID`에 넣고, 세션 이어가기를 끄려면 `CODEX_RESUME_ENABLED=false`로 설정한다.

공식 프로토콜 흐름:

```text
initialize -> initialized -> thread/start 또는 thread/resume -> turn/start -> turn/completed
```

기본 실행 설정:

```text
CODEX_RUNNER_ENGINE=app-server
CODEX_WORKSPACE_ROOT=<하네스 루트>
CODEX_EXECUTABLE=codex.cmd
CODEX_SANDBOX=workspace-write
CODEX_RESUME_ENABLED=true
CODEX_RUNNER_THREAD_ID=
```

처리 상태와 현재 thread id는 `data/runner-state.json`에 저장한다. 큐 파일은 기본 흐름에서 사용하지 않는다.

## Desktop Refresh

Discord Agent가 같은 thread에 turn을 추가해도 이미 열려 있는 Codex Desktop 화면이 자동으로 pull하지 않을 수 있다. 기본 설정은 작업 완료 후 Desktop route를 다시 열어 최신 thread를 보이도록 유도한다.

```text
REFRESH_CODEX_DESKTOP=true
CODEX_DESKTOP_REFRESH_BOUNCE=true
CODEX_DESKTOP_REFRESH_DELAY_MS=800
```

동작 순서:

1. `codex://settings`를 열어 현재 thread 화면에서 잠깐 벗어난다.
2. `codex://threads/<threadId>`를 열어 해당 thread 화면을 다시 마운트한다.

이 방식은 Desktop 앱의 실시간 구독이 아니라 딥링크 기반 refresh 우회다. Desktop 앱이 `codex://threads/<threadId>` 스킴을 처리하지 못하면 완료 메시지의 `Desktop 갱신` 필드에 실패가 표시된다.

## Desktop Codex Integration

Codex Desktop/CLI/IDE는 같은 Codex App Server 계층을 사용한다. 이 브리지는 `codex app-server`를 직접 호출해 thread를 만들거나 resume하므로, `codex exec`보다 Desktop history 연동 가능성이 높다.

단, 현재 열린 Desktop 창의 active 입력창에 메시지를 실시간 주입하는 기능은 별개다. 이 브리지는 App Server thread에 turn을 추가하고, Desktop에서 같은 thread가 history에 표시되면 그 thread를 열어 확인하는 방식이다. Desktop history에서 보이지 않으면 `runner-state.json`의 `codexThreadId`를 `CODEX_RUNNER_THREAD_ID`로 고정해 계속 같은 App Server thread를 이어간다.

Desktop에서 현재 대화와 맞추는 운영 절차:

1. Discord에서 `/codex threads`를 실행한다.
2. Desktop에서 이어가려는 대화의 preview와 같은 thread id를 찾는다.
3. `/codex thread-set thread_id:<id>`로 지정한다.
4. 이후 완료 알림에 답글을 달거나 `/codex task`를 쓰면 해당 thread에 `turn/start`가 추가된다.

## Legacy Command Queue

이전 구조의 큐 파일은 fallback runner용으로 남아 있다.

```text
data/commands.jsonl
```

기본 Agent 직결 운영에서는 이 파일을 확인할 필요가 없다.

## Security Notes

- `.env`는 Git에 커밋하지 않는다.
- `ALLOWED_USER_IDS`에 본인 Discord user ID를 넣는다.
- webhook URL과 bot token은 비밀번호처럼 취급한다.
- 이 앱은 의도적으로 arbitrary shell execution을 넣지 않았다. Discord 입력은 Codex App Server turn으로 전달된다.
- 답글 캡처는 Discord의 Message Content Intent가 필요하다. 개인 테스트 서버와 허용 사용자 제한을 전제로 사용한다.
- Agent는 Discord 답글을 실제 Codex 작업으로 실행한다. `ALLOWED_USER_IDS`를 반드시 설정하고, 토큰이 노출되면 즉시 재발급한다.
