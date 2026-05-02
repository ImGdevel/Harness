# Architecture

Discode connects Discord to the local Codex App Server.

## Default Flow

```text
Discord reply or /codex task
-> Discord Agent bot
-> codex app-server
-> thread/start or thread/resume
-> turn/start
-> turn/completed
-> Discord Agent completion reply
-> optional Codex Desktop deep-link refresh
```

The default path does not use a queue. The bot process handles Discord events, runs the Codex App Server turn, and posts the result back to Discord.

## Main Components

- `src/bot.js`: Discord bot entry point. Handles slash commands and message replies.
- `src/codex-service.js`: Builds Codex prompts and runs App Server thread/turn calls.
- `src/app-server-client.js`: JSON-RPC client for `codex app-server` over stdio.
- `src/desktop-refresh.js`: Opens `codex://settings` and `codex://threads/<threadId>` to refresh Codex Desktop.
- `src/state.js`: Stores current thread id and task summaries in `data/runner-state.json`.
- `src/commands.js`: Defines Discord slash commands.
- `src/register-commands.js`: Registers slash commands to Discord.

## Thread Continuity

The current Codex thread id is loaded from:

1. `CODEX_RUNNER_THREAD_ID`, if set.
2. `data/runner-state.json`, if the app has already run.
3. A new App Server thread, if neither exists.

`/codex threads` lists recent Codex App Server threads for the workspace. `/codex thread-set` pins the Discord Agent to one thread.

## Desktop Refresh

Codex Desktop may not live-refresh a thread when an external App Server client writes to it. The bot can force a route refresh after each completed turn:

```text
codex://settings
codex://threads/<threadId>
```

This is a pragmatic refresh workaround, not a guaranteed live-subscription API.

## Legacy Runner

The old JSONL queue runner remains in `src/runner.js` for fallback/manual testing. It is not required for the default Agent flow.
