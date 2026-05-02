const { spawn } = require('node:child_process');
const { loadConfig } = require('./config');
const { CodexAppServerClient } = require('./app-server-client');
const { ensureQueue, readQueuedCommands } = require('./queue');
const { ensureState, writeState } = require('./state');
const { COLORS, sendWebhook } = require('./webhook');

const once = process.argv.includes('--once');
const RESUME_UNSUPPORTED_MARKERS = [
  'unknown subcommand',
  'unrecognized subcommand',
  'No such subcommand',
  'unrecognized option',
];

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function tail(value, maxLength = 1600) {
  if (!value) {
    return '';
  }
  return value.length > maxLength ? value.slice(value.length - maxLength) : value;
}

function buildPrompt(entry) {
  return [
    'You are running from the local Discord Codex remote-control runner.',
    'Treat the following Discord reply as the user request.',
    'When the major task is complete, summarize changed files, verification, and any blockers.',
    '',
    `Request ID: ${entry.id}`,
    `Requested by: ${entry.requestedBy?.username || 'unknown'} (${entry.requestedBy?.id || 'unknown'})`,
    '',
    entry.prompt,
  ].join('\n');
}

function getThreadId(config, state) {
  return config.codexThreadId || state.codexThreadId;
}

function shouldUseResume(config, state) {
  return config.codexResumeEnabled && Boolean(getThreadId(config, state));
}

function buildCodexArgs(config, state) {
  const threadId = getThreadId(config, state);
  const args = ['exec'];

  if (shouldUseResume(config, state)) {
    args.push('resume', threadId, '--json');
    if (config.codexSandbox === 'danger-full-access') {
      args.push('--dangerously-bypass-approvals-and-sandbox');
    }
  } else {
    args.push('--json', '--cd', config.workspaceRoot, '-s', config.codexSandbox);
  }

  if (config.codexModel) {
    args.push('-m', config.codexModel);
  }

  return args;
}

function parseCodexJson(stdout) {
  const events = [];
  const agentMessages = [];
  let threadId;

  for (const line of stdout.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed.startsWith('{')) {
      continue;
    }

    try {
      const event = JSON.parse(trimmed);
      events.push(event);
      if (event.type === 'thread.started' && event.thread_id) {
        threadId = event.thread_id;
      }
      if (event.type === 'agent_message' && event.message) {
        agentMessages.push(event.message);
      }
      if (event.type === 'item.completed' && event.item?.type === 'agent_message' && event.item.text) {
        agentMessages.push(event.item.text);
      }
    } catch {
      // Keep raw stdout as the fallback summary if Codex emits non-JSON lines.
    }
  }

  return {
    events,
    threadId,
    summary: agentMessages.length ? agentMessages.join('\n\n') : '',
  };
}

function looksLikeResumeUnsupported(stderr, stdout) {
  const combined = `${stderr || ''}\n${stdout || ''}`;
  return RESUME_UNSUPPORTED_MARKERS.some((marker) => combined.includes(marker));
}

function mapPermissionsProfile(sandbox) {
  if (sandbox === 'danger-full-access') {
    return ':danger-no-sandbox';
  }
  if (sandbox === 'read-only') {
    return ':read-only';
  }
  return ':workspace';
}

function buildThreadParams(config) {
  const params = {
    cwd: config.workspaceRoot,
    serviceName: 'discord_codex_local_bridge',
    approvalPolicy: 'never',
    permissions: {
      type: 'profile',
      id: mapPermissionsProfile(config.codexSandbox),
    },
    persistExtendedHistory: true,
  };

  if (config.codexModel) {
    params.model = config.codexModel;
  }

  return params;
}

function extractThreadId(result) {
  return result?.thread?.id || result?.id;
}

function appendAgentText(agentText, event) {
  const params = event.params || {};
  if (event.method === 'item/agentMessage/delta' && params.delta) {
    agentText.deltas.push(params.delta);
    return;
  }

  if (event.method !== 'item/completed') {
    return;
  }

  const item = params.item || {};
  if (item.type !== 'agent_message' && item.type !== 'agentMessage') {
    return;
  }

  if (typeof item.text === 'string') {
    agentText.completed.push(item.text);
  } else if (Array.isArray(item.content)) {
    for (const content of item.content) {
      if (typeof content.text === 'string') {
        agentText.completed.push(content.text);
      }
    }
  }
}

async function runCodexAppServer(config, state, entry, { forceNewThread = false } = {}) {
  const client = new CodexAppServerClient(config);
  const agentText = { deltas: [], completed: [] };
  let turnId;
  let turnStatus = 'unknown';
  let threadId = forceNewThread ? undefined : getThreadId(config, state);
  const usedResume = config.codexResumeEnabled && Boolean(threadId);

  client.on('notification', (event) => {
    appendAgentText(agentText, event);
    if (event.method === 'turn/started' && event.params?.turn?.id) {
      turnId = event.params.turn.id;
    }
    if (event.method === 'turn/completed') {
      turnStatus = event.params?.turn?.status || 'completed';
    }
  });

  try {
    client.start();
    await client.initialize();

    if (usedResume) {
      const resumed = await client.request('thread/resume', {
        ...buildThreadParams(config),
        threadId,
      });
      threadId = extractThreadId(resumed) || threadId;
    } else {
      const started = await client.request('thread/start', buildThreadParams(config));
      threadId = extractThreadId(started);
    }

    if (!threadId) {
      throw new Error('codex app-server did not return a thread id');
    }

    const completion = new Promise((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error('Timed out waiting for turn/completed')), config.appServerTurnTimeoutMs);
      client.on('notification', (event) => {
        if (event.method === 'turn/completed') {
          clearTimeout(timeout);
          resolve();
        }
      });
      client.on('close', (code) => {
        clearTimeout(timeout);
        reject(new Error(`codex app-server closed before turn completed: ${code}`));
      });
    });

    const turn = await client.request('turn/start', {
      threadId,
      input: [{ type: 'text', text: buildPrompt(entry) }],
      cwd: config.workspaceRoot,
      approvalPolicy: 'never',
      permissions: {
        type: 'profile',
        id: mapPermissionsProfile(config.codexSandbox),
      },
    });
    turnId = turn?.turn?.id || turnId;

    await completion;

    const summary = (agentText.completed.length ? agentText.completed.join('\n\n') : agentText.deltas.join('')).trim();
    return {
      code: turnStatus === 'failed' ? 1 : 0,
      stdout: summary,
      stderr: client.stderr,
      threadId,
      turnId,
      summary,
      usedResume,
      engine: 'app-server',
    };
  } catch (error) {
    return {
      code: 1,
      stdout: (agentText.completed.length ? agentText.completed.join('\n\n') : agentText.deltas.join('')).trim(),
      stderr: `${client.stderr || ''}\n${error.stack || error.message}`,
      threadId,
      turnId,
      summary: (agentText.completed.length ? agentText.completed.join('\n\n') : agentText.deltas.join('')).trim(),
      usedResume,
      engine: 'app-server',
    };
  } finally {
    client.close();
  }
}

function runCodex(config, state, entry, { forceNewThread = false } = {}) {
  return new Promise((resolve) => {
    let child;
    const effectiveState = forceNewThread ? { ...state, codexThreadId: undefined } : state;

    try {
      const windowsCommand = [
        "$codexArgs = @('exec')",
        "if ($env:CODEX_RUNNER_THREAD_ID) {",
        "  $codexArgs += @('resume', $env:CODEX_RUNNER_THREAD_ID, '--json')",
        "  if ($env:CODEX_RUNNER_SANDBOX -eq 'danger-full-access') { $codexArgs += @('--dangerously-bypass-approvals-and-sandbox') }",
        "} else {",
        "  $codexArgs += @('--json', '--cd', $env:CODEX_RUNNER_WORKSPACE_ROOT, '-s', $env:CODEX_RUNNER_SANDBOX)",
        "}",
        "if ($env:CODEX_RUNNER_MODEL) { $codexArgs += @('-m', $env:CODEX_RUNNER_MODEL) }",
        '& $env:CODEX_RUNNER_EXECUTABLE @codexArgs',
      ].join('; ');
      const command = process.platform === 'win32' ? 'powershell.exe' : config.codexExecutable;
      const args = process.platform === 'win32'
        ? ['-NoProfile', '-NonInteractive', '-Command', windowsCommand]
        : buildCodexArgs(config, effectiveState);

      child = spawn(command, args, {
        cwd: config.workspaceRoot,
        windowsHide: true,
        shell: false,
        env: {
          ...process.env,
          CODEX_RUNNER_EXECUTABLE: config.codexExecutable,
          CODEX_RUNNER_MODEL: config.codexModel || '',
          CODEX_RUNNER_SANDBOX: config.codexSandbox,
          CODEX_RUNNER_THREAD_ID: shouldUseResume(config, effectiveState) ? getThreadId(config, effectiveState) : '',
          CODEX_RUNNER_WORKSPACE_ROOT: config.workspaceRoot,
        },
      });
    } catch (error) {
      resolve({ code: 1, stdout: '', stderr: error.stack || error.message });
      return;
    }

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (chunk) => {
      stdout += chunk.toString();
    });

    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
    });

    child.on('error', (error) => {
      resolve({ code: 1, stdout, stderr: `${stderr}\n${error.stack || error.message}` });
    });

    child.on('close', (code) => {
      const parsed = parseCodexJson(stdout);
      resolve({
        code,
        stdout,
        stderr,
        threadId: parsed.threadId,
        summary: parsed.summary,
        usedResume: shouldUseResume(config, effectiveState),
      });
    });

    child.stdin.end(buildPrompt(entry));
  });
}

async function processEntry(config, state, entry) {
  const existingThreadId = getThreadId(config, state);
  const willResume = shouldUseResume(config, state);
  state.tasks[entry.id] = {
    status: 'running',
    startedAt: new Date().toISOString(),
    prompt: entry.prompt,
    codexThreadId: existingThreadId,
    usedResume: willResume,
  };
  await writeState(config, state);

  await sendWebhook(config.webhookUrl, {
    title: '작업 시작',
    description: entry.prompt.slice(0, 1800),
    color: COLORS.started,
    fields: [
      { name: '요청 ID', value: entry.id },
      { name: '세션', value: willResume ? `기존 세션 이어감 (${existingThreadId})` : '새 Codex 세션 시작' },
    ],
  });

  let result = config.codexRunnerEngine === 'exec'
    ? await runCodex(config, state, entry)
    : await runCodexAppServer(config, state, entry);
  if (config.codexRunnerEngine === 'exec' && result.code !== 0 && result.usedResume && !config.codexThreadId && looksLikeResumeUnsupported(result.stderr, result.stdout)) {
    state.codexThreadId = undefined;
    result = await runCodex(config, state, entry, { forceNewThread: true });
  }
  if (config.codexRunnerEngine !== 'exec' && result.code !== 0 && result.usedResume && !config.codexThreadId) {
    state.codexThreadId = undefined;
    result = await runCodexAppServer(config, state, entry, { forceNewThread: true });
  }
  const finishedAt = new Date().toISOString();
  const ok = result.code === 0;
  if (ok && result.threadId && !config.codexThreadId) {
    state.codexThreadId = result.threadId;
  }

  state.tasks[entry.id] = {
    ...state.tasks[entry.id],
    status: ok ? 'completed' : 'failed',
    finishedAt,
    exitCode: result.code,
    codexThreadId: result.threadId || existingThreadId,
    usedResume: result.usedResume,
    summary: result.summary,
    engine: result.engine || config.codexRunnerEngine,
    turnId: result.turnId,
    stdoutTail: tail(result.stdout),
    stderrTail: tail(result.stderr),
  };
  await writeState(config, state);

  await sendWebhook(config.webhookUrl, {
    title: ok ? '작업 완료 - 검토 대기' : '작업 실패',
    description: ok
      ? [
          '완료한 요청',
          entry.prompt.slice(0, 1100),
          '',
          '완료한 작업 결과',
          tail(result.summary || result.stdout, 1400) || '(no output)',
          '',
          '다음 작업을 지시하려면 이 Discord 메시지에 답글을 달아주세요.',
        ].join('\n')
      : [
          '실패한 요청',
          entry.prompt.slice(0, 1100),
          '',
          '오류 결과',
          tail(result.stderr || result.stdout, 1400) || '(no output)',
        ].join('\n'),
    color: ok ? COLORS.completed : COLORS.failed,
    fields: [
      { name: '요청 ID', value: entry.id },
      { name: '엔진', value: result.engine || config.codexRunnerEngine },
      { name: '종료 코드', value: String(result.code) },
      { name: '세션', value: result.threadId || existingThreadId || '새 세션 ID 없음' },
      {
        name: ok ? '실행 결과' : '오류',
        value: tail(ok ? result.summary || result.stdout : result.stderr || result.stdout, 1000) || '(no output)',
      },
    ],
  });
}

async function processPending(config) {
  await ensureQueue(config.queuePath);
  const state = await ensureState(config);
  const entries = await readQueuedCommands(config.queuePath);
  const pending = entries.filter((entry) => {
    const task = state.tasks[entry.id];
    return !task || task.status === 'failed' || task.status === 'running';
  });

  for (const entry of pending) {
    await processEntry(config, state, entry);
  }

  return pending.length;
}

async function main() {
  const config = loadConfig({ requireWebhook: true });
  console.log(`Runner watching: ${config.queuePath}`);
  console.log(`Runner state: ${config.runnerStatePath}`);
  console.log(`Workspace root: ${config.workspaceRoot}`);
  console.log(`Codex engine: ${config.codexRunnerEngine}`);
  console.log(`Codex command: ${config.codexExecutable} ${config.codexRunnerEngine === 'exec' ? 'exec' : 'app-server'}`);
  console.log(`Codex resume: ${config.codexResumeEnabled ? 'enabled' : 'disabled'}`);

  do {
    try {
      const processed = await processPending(config);
      if (once) {
        console.log(`Processed ${processed} pending task(s).`);
        return;
      }
    } catch (error) {
      console.error(error);
      await sendWebhook(config.webhookUrl, {
        title: '자동 실행기 오류',
        description: error.message,
        color: COLORS.failed,
      });
    }

    await sleep(config.runnerPollIntervalMs);
  } while (true);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
