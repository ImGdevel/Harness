const path = require('node:path');
const dotenv = require('dotenv');

dotenv.config();

const rootDir = path.resolve(__dirname, '..');

function readRequired(name) {
  const value = process.env[name];
  if (!value || !value.trim()) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value.trim();
}

function readOptional(name) {
  const value = process.env[name];
  return value && value.trim() ? value.trim() : undefined;
}

function readAllowedUserIds() {
  const raw = readOptional('ALLOWED_USER_IDS');
  if (!raw) {
    return new Set();
  }
  return new Set(
    raw
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean),
  );
}

function parseBoolean(value) {
  return ['1', 'true', 'yes', 'on'].includes(String(value || '').trim().toLowerCase());
}

function parseWebhookId(webhookUrl) {
  if (!webhookUrl) {
    return undefined;
  }

  try {
    const url = new URL(webhookUrl);
    const parts = url.pathname.split('/').filter(Boolean);
    const webhookIndex = parts.indexOf('webhooks');
    return webhookIndex >= 0 ? parts[webhookIndex + 1] : undefined;
  } catch {
    return undefined;
  }
}

function loadConfig({ requireBot = false, requireWebhook = false } = {}) {
  const queuePath = readOptional('COMMAND_QUEUE_PATH')
    ? path.resolve(readOptional('COMMAND_QUEUE_PATH'))
    : path.join(rootDir, 'data', 'commands.jsonl');

  const webhookUrl = requireWebhook ? readRequired('DISCORD_WEBHOOK_URL') : readOptional('DISCORD_WEBHOOK_URL');
  const workspaceRoot = readOptional('CODEX_WORKSPACE_ROOT')
    ? path.resolve(readOptional('CODEX_WORKSPACE_ROOT'))
    : path.resolve(rootDir, '..', '..');
  const runnerStatePath = readOptional('RUNNER_STATE_PATH')
    ? path.resolve(readOptional('RUNNER_STATE_PATH'))
    : path.join(rootDir, 'data', 'runner-state.json');

  return {
    rootDir,
    token: requireBot ? readRequired('DISCORD_BOT_TOKEN') : readOptional('DISCORD_BOT_TOKEN'),
    clientId: requireBot ? readRequired('DISCORD_CLIENT_ID') : readOptional('DISCORD_CLIENT_ID'),
    guildId: readOptional('DISCORD_GUILD_ID'),
    webhookUrl,
    webhookId: parseWebhookId(webhookUrl),
    allowedUserIds: readAllowedUserIds(),
    enableReplyCapture: parseBoolean(process.env.ENABLE_REPLY_CAPTURE),
    queuePath,
    codexRunnerEngine: readOptional('CODEX_RUNNER_ENGINE') || 'app-server',
    codexExecutable: readOptional('CODEX_EXECUTABLE') || (process.platform === 'win32' ? 'codex.cmd' : 'codex'),
    codexModel: readOptional('CODEX_MODEL'),
    codexSandbox: readOptional('CODEX_SANDBOX') || 'workspace-write',
    codexResumeEnabled: readOptional('CODEX_RESUME_ENABLED') !== 'false',
    codexThreadId: readOptional('CODEX_RUNNER_THREAD_ID'),
    runnerStatePath,
    runnerPollIntervalMs: Number(readOptional('RUNNER_POLL_INTERVAL_MS') || 3000),
    appServerTurnTimeoutMs: Number(readOptional('APP_SERVER_TURN_TIMEOUT_MS') || 20 * 60 * 1000),
    refreshCodexDesktop: readOptional('REFRESH_CODEX_DESKTOP') !== 'false',
    codexDesktopRefreshBounce: parseBoolean(readOptional('CODEX_DESKTOP_REFRESH_BOUNCE') || 'true'),
    codexDesktopRefreshDelayMs: Number(readOptional('CODEX_DESKTOP_REFRESH_DELAY_MS') || 800),
    workspaceRoot,
  };
}

module.exports = {
  loadConfig,
};
