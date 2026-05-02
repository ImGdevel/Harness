const crypto = require('node:crypto');
const { CodexAppServerClient } = require('./app-server-client');

function tail(value, maxLength = 1600) {
  if (!value) {
    return '';
  }
  return value.length > maxLength ? value.slice(value.length - maxLength) : value;
}

function getThreadId(config, state) {
  return config.codexThreadId || state.codexThreadId;
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
    serviceName: 'discord_codex_agent',
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

function buildPrompt(task) {
  return [
    'You are receiving this request from the Discord Agent connected to local Codex App Server.',
    'Treat the Discord message as the user request.',
    'When complete, summarize changed files, verification, and blockers in Korean unless the user asked otherwise.',
    '',
    `Request ID: ${task.id}`,
    `Requested by: ${task.requestedBy?.username || 'unknown'} (${task.requestedBy?.id || 'unknown'})`,
    '',
    task.prompt,
  ].join('\n');
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

async function withAppServer(config, fn) {
  const client = new CodexAppServerClient(config);
  try {
    client.start();
    await client.initialize();
    return await fn(client);
  } finally {
    client.close();
  }
}

async function listThreads(config, limit = 5) {
  return withAppServer(config, (client) =>
    client.request('thread/list', {
      limit,
      archived: false,
      sortKey: 'updated_at',
      cwd: config.workspaceRoot,
    }),
  );
}

async function runCodexTask(config, state, task, { forceNewThread = false } = {}) {
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
      input: [{ type: 'text', text: buildPrompt(task) }],
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
      ok: turnStatus !== 'failed',
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
      ok: false,
      code: 1,
      stdout: (agentText.completed.length ? agentText.completed.join('\n\n') : agentText.deltas.join('')).trim(),
      stderr: tail(`${client.stderr || ''}\n${error.stack || error.message}`, 4000),
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

function createTask(prompt, requestedBy, extra = {}) {
  return {
    id: crypto.randomUUID(),
    createdAt: new Date().toISOString(),
    prompt,
    requestedBy,
    ...extra,
  };
}

module.exports = {
  createTask,
  getThreadId,
  listThreads,
  runCodexTask,
  tail,
};
