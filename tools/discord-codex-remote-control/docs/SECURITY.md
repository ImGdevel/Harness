# Security Notes

Discode gives Discord users a path to run local Codex tasks. Treat it like a remote-control surface.

## Never Commit Secrets

Do not commit:

- `.env`
- Discord bot token
- Discord webhook URL
- `data/*.json`, `data/*.jsonl`, `data/*.log`
- `node_modules/`

The repository `.gitignore` excludes these by default. Use `.env.example` as the public template.

## Restrict Users

Set `ALLOWED_USER_IDS` to a comma-separated allow-list of Discord user ids:

```text
ALLOWED_USER_IDS=123456789012345678
```

Leaving it empty allows anyone in the configured server/channel context to use the bridge.

## Discord Settings

Reply capture requires Discord's Message Content Intent. Enable it only for a trusted private server or controlled test environment.

## Local Execution

Discord input is not executed as a shell command. It is sent to Codex App Server as a user turn. Codex may still choose to run local tools depending on your Codex permissions and sandbox settings.

Recommended defaults:

```text
CODEX_SANDBOX=workspace-write
CODEX_RESUME_ENABLED=true
REFRESH_CODEX_DESKTOP=true
```

Use `danger-full-access` only when you understand the risk.

## Token Rotation

If a token or webhook URL is ever posted in chat, logs, screenshots, or a public repo, rotate it in Discord Developer Portal immediately.
