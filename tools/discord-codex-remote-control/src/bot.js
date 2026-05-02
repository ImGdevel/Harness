const { Client, Events, GatewayIntentBits, Partials } = require('discord.js');
const { appendAgentEvent } = require('./agent-log');
const { createTask, getThreadId, listThreads, runCodexTask, tail } = require('./codex-service');
const { loadConfig } = require('./config');
const { refreshCodexDesktop } = require('./desktop-refresh');
const { ensureState, writeState } = require('./state');
const { COLORS } = require('./webhook');

function isAllowed(config, userId) {
  if (config.allowedUserIds.size === 0) {
    return true;
  }
  return config.allowedUserIds.has(userId);
}

function embed(title, description, color, fields = []) {
  return {
    title,
    description,
    color,
    fields: fields.filter((field) => field.value !== undefined && field.value !== null),
    timestamp: new Date().toISOString(),
  };
}

function taskDescription(prompt) {
  return [
    '요청 내용',
    prompt.slice(0, 1800),
    '',
    '이 작업은 아래 표시된 Codex App Server thread에 turn/start로 추가됩니다.',
    '완료 메시지에 답글을 달면 같은 thread로 다음 작업을 이어갑니다.',
  ].join('\n');
}

function continuityText(result, fallbackThreadId) {
  const threadId = result.threadId || fallbackThreadId || 'thread 없음';
  const mode = result.usedResume ? '기존 Codex thread 이어감' : '새 Codex thread 시작';
  return [
    `이어짐 여부: ${mode}`,
    `Codex thread id: ${threadId}`,
    '',
    '주의: Discord 메시지가 Codex Desktop 입력창에 직접 타이핑되는 것은 아닙니다.',
    '대신 Codex App Server의 같은 thread에 turn을 추가하므로, Desktop 앱에서 같은 thread를 열면 이어진 대화로 확인할 수 있습니다.',
  ].join('\n');
}

function resultDescription(task, result, fallbackThreadId) {
  if (result.ok) {
    return [
      continuityText(result, fallbackThreadId),
      '',
      '완료한 요청',
      task.prompt.slice(0, 1000),
      '',
      '완료한 작업 결과',
      tail(result.summary || result.stdout, 2200) || '(응답 내용 없음)',
      '',
      '다음 작업을 지시하려면 이 Agent 메시지에 답글을 달아주세요.',
    ].join('\n');
  }

  return [
    continuityText(result, fallbackThreadId),
    '',
    '실패한 요청',
    task.prompt.slice(0, 1000),
    '',
    '오류 결과',
    tail(result.stderr || result.summary || result.stdout, 2200) || '(오류 내용 없음)',
  ].join('\n');
}

async function recordTaskResult(config, task, result) {
  const state = await ensureState(config);
  if (result.ok && result.threadId && !config.codexThreadId) {
    state.codexThreadId = result.threadId;
  }
  state.tasks = state.tasks || {};
  state.tasks[task.id] = {
    status: result.ok ? 'completed' : 'failed',
    prompt: task.prompt,
    startedAt: task.startedAt,
    finishedAt: new Date().toISOString(),
    requestedBy: task.requestedBy,
    codexThreadId: result.threadId,
    turnId: result.turnId,
    usedResume: result.usedResume,
    engine: result.engine,
    summary: result.summary,
    stderrTail: tail(result.stderr, 1600),
  };
  await writeState(config, state);
}

async function runTaskAndReport(config, task, sendStarted, sendCompleted) {
  const state = await ensureState(config);
  const existingThreadId = getThreadId(config, state);
  const willResume = config.codexResumeEnabled && Boolean(existingThreadId);

  task.startedAt = new Date().toISOString();
  await sendStarted(embed('작업 시작', taskDescription(task.prompt), COLORS.started, [
    { name: '요청 ID', value: task.id },
    { name: '이어짐 여부', value: willResume ? '기존 Codex thread 이어감' : '새 Codex thread 시작' },
    { name: 'Codex thread id', value: existingThreadId || '(아직 없음, 새 thread 생성 예정)' },
    { name: '실행 방식', value: 'Agent 직접 실행 -> codex app-server' },
  ]));

  const result = await runCodexTask(config, state, task);
  await recordTaskResult(config, task, result);
  let desktopRefresh;
  try {
    desktopRefresh = await refreshCodexDesktop(config, result.threadId || existingThreadId);
  } catch (error) {
    desktopRefresh = { refreshed: false, error: error.message };
  }

  await sendCompleted(embed(
    result.ok ? '작업 완료 - 검토 대기' : '작업 실패',
    resultDescription(task, result, existingThreadId),
    result.ok ? COLORS.completed : COLORS.failed,
    [
      { name: '요청 ID', value: task.id },
      { name: '이어짐 여부', value: result.usedResume ? '기존 Codex thread 이어감' : '새 Codex thread 시작' },
      { name: 'Codex thread id', value: result.threadId || existingThreadId || 'thread 없음' },
      { name: 'Turn', value: result.turnId || 'turn 없음' },
      {
        name: 'Desktop 갱신',
        value: desktopRefresh?.refreshed
          ? 'codex://threads 딥링크 호출 완료'
          : `갱신 안 함${desktopRefresh?.error ? ` (${desktopRefresh.error})` : ''}`,
      },
    ],
  ));

  return result;
}

function formatThread(thread) {
  const updated = thread.updatedAt || thread.createdAt;
  const date = updated ? new Date(updated * 1000).toISOString().replace('T', ' ').slice(0, 19) : 'unknown';
  const preview = (thread.name || thread.preview || '(no preview)').replace(/\s+/g, ' ').slice(0, 90);
  return `${thread.id} | ${date} | ${preview}`;
}

async function handleTask(config, interaction, active) {
  const prompt = interaction.options.getString('prompt', true);
  await appendAgentEvent(config, 'slash_task_received', {
    userId: interaction.user.id,
    username: interaction.user.username,
    channelId: interaction.channelId,
    prompt,
  });

  if (active.current) {
    await interaction.reply({
      content: `이미 작업 중입니다. 현재 요청 ID: ${active.current.id}`,
      ephemeral: true,
    });
    return;
  }

  const task = createTask(prompt, {
    id: interaction.user.id,
    username: interaction.user.username,
  }, {
    source: 'discord-slash',
    guildId: interaction.guildId,
    channelId: interaction.channelId,
  });

  active.current = task;
  try {
    await runTaskAndReport(
      config,
      task,
      (startedEmbed) => interaction.reply({ embeds: [startedEmbed] }),
      (completedEmbed) => interaction.channel.send({ embeds: [completedEmbed] }),
    );
    await appendAgentEvent(config, 'slash_task_completed', { taskId: task.id });
  } finally {
    active.current = null;
  }
}

async function handleDone(interaction) {
  const summary = interaction.options.getString('summary', true);
  const details = interaction.options.getString('details', false);

  await interaction.reply({
    embeds: [embed(
      '작업 완료 - 검토 대기',
      [
        summary,
        details ? '' : null,
        details ? ['세부 작업', details.slice(0, 1800)].join('\n') : null,
        '',
        '다음 작업을 지시하려면 이 Agent 메시지에 답글을 달아주세요.',
      ].filter(Boolean).join('\n'),
      COLORS.completed,
    )],
  });
}

async function handleStatus(config, interaction, startedAt, active) {
  const state = await ensureState(config);
  const uptimeSeconds = Math.round((Date.now() - startedAt.getTime()) / 1000);

  await interaction.reply({
    content: [
      `Agent online for ${uptimeSeconds}s.`,
      `Mode: direct Agent execution.`,
      `Runner process: not required.`,
      `Current task: ${active.current ? active.current.id : '(idle)'}.`,
      `Current thread: ${config.codexThreadId || state.codexThreadId || '(next task starts a new thread)'}.`,
      `Reply capture: ${config.enableReplyCapture ? 'enabled' : 'disabled'}.`,
    ].join('\n'),
    ephemeral: true,
  });
}

async function handleThreads(config, interaction) {
  await interaction.deferReply({ ephemeral: true });
  const limit = interaction.options.getInteger('limit', false) || 5;
  const result = await listThreads(config, limit);
  const threads = result?.data || [];

  await interaction.editReply({
    content: threads.length
      ? ['Recent Codex threads:', ...threads.map(formatThread)].join('\n')
      : 'No Codex threads found for this workspace.',
  });
}

async function handleThreadSet(config, interaction) {
  const threadId = interaction.options.getString('thread_id', true).trim();
  const state = await ensureState(config);
  state.codexThreadId = threadId;
  await writeState(config, state);

  await interaction.reply({
    content: `Current Codex thread set to ${threadId}.`,
    ephemeral: true,
  });
}

async function handleThreadNew(config, interaction) {
  const state = await ensureState(config);
  delete state.codexThreadId;
  await writeState(config, state);

  await interaction.reply({
    content: 'Stored Codex thread cleared. The next task will start a new App Server thread.',
    ephemeral: true,
  });
}

async function getReplyTarget(config, client, message) {
  if (!message.reference?.messageId) {
    return { ok: false, reason: 'no_reference' };
  }

  const referenced = await message.channel.messages.fetch(message.reference.messageId);
  if (referenced.author?.id === client.user.id) {
    return { ok: true, kind: 'agent', referenced };
  }
  if (config.webhookId && referenced.webhookId === config.webhookId) {
    return { ok: true, kind: 'webhook', referenced };
  }

  return {
    ok: false,
    reason: 'not_bridge_message',
    referencedAuthorId: referenced.author?.id,
    referencedWebhookId: referenced.webhookId,
  };
}

async function handleMessageReply(config, client, message, active) {
  await appendAgentEvent(config, 'message_seen', {
    authorId: message.author.id,
    authorBot: message.author.bot,
    channelId: message.channelId,
    messageId: message.id,
    referenceMessageId: message.reference?.messageId,
    content: message.content.slice(0, 500),
  });

  if (!config.enableReplyCapture || message.author.bot || !message.content.trim()) {
    await appendAgentEvent(config, 'message_ignored', {
      messageId: message.id,
      reason: !config.enableReplyCapture ? 'reply_capture_disabled' : message.author.bot ? 'bot_author' : 'empty_content',
    });
    return;
  }

  if (!isAllowed(config, message.author.id)) {
    await appendAgentEvent(config, 'message_ignored', {
      messageId: message.id,
      reason: 'not_allowed',
      authorId: message.author.id,
    });
    return;
  }

  const replyTarget = await getReplyTarget(config, client, message);
  if (!replyTarget.ok) {
    await appendAgentEvent(config, 'message_ignored', {
      messageId: message.id,
      ...replyTarget,
    });
    return;
  }

  if (active.current) {
    await message.reply({
      content: `이미 작업 중입니다. 현재 요청 ID: ${active.current.id}`,
      allowedMentions: { repliedUser: false },
    });
    return;
  }

  const task = createTask(message.content.trim(), {
    id: message.author.id,
    username: message.author.username,
  }, {
    source: 'discord-reply',
    guildId: message.guildId,
    channelId: message.channelId,
    replyToMessageId: message.reference.messageId,
    messageId: message.id,
  });
  await appendAgentEvent(config, 'reply_task_received', {
    taskId: task.id,
    targetKind: replyTarget.kind,
    channelId: message.channelId,
    messageId: message.id,
    prompt: task.prompt,
  });

  active.current = task;
  try {
    let startedMessage;
    await runTaskAndReport(
      config,
      task,
      async (startedEmbed) => {
        startedMessage = await message.reply({
          embeds: [startedEmbed],
          allowedMentions: { repliedUser: false },
        });
      },
      async (completedEmbed) => {
        try {
          await startedMessage.reply({
            embeds: [completedEmbed],
            allowedMentions: { repliedUser: false },
          });
        } catch (error) {
          await appendAgentEvent(config, 'completed_reply_failed_fallback_channel_send', {
            taskId: task.id,
            error: error.message,
          });
          await message.channel.send({ embeds: [completedEmbed] });
        }
      },
    );
    await appendAgentEvent(config, 'reply_task_completed', { taskId: task.id });
  } finally {
    active.current = null;
  }
}

async function main() {
  const config = loadConfig({ requireBot: true });
  const startedAt = new Date();
  const active = { current: null };
  const intents = [GatewayIntentBits.Guilds];

  if (config.enableReplyCapture) {
    intents.push(GatewayIntentBits.GuildMessages, GatewayIntentBits.MessageContent);
  }

  const client = new Client({
    intents,
    partials: [Partials.Channel, Partials.Message],
  });

  client.once(Events.ClientReady, (readyClient) => {
    console.log(`Discord Agent ready as ${readyClient.user.tag}.`);
    console.log('Mode: direct Agent execution -> codex app-server');
    console.log(`Reply capture: ${config.enableReplyCapture ? 'enabled' : 'disabled'}`);
  });

  client.on(Events.InteractionCreate, async (interaction) => {
    if (!interaction.isChatInputCommand() || interaction.commandName !== 'codex') {
      return;
    }

    if (!isAllowed(config, interaction.user.id)) {
      await interaction.reply({
        content: 'You are not allowed to use this Agent.',
        ephemeral: true,
      });
      return;
    }

    try {
      const subcommand = interaction.options.getSubcommand();

      if (subcommand === 'task') {
        await handleTask(config, interaction, active);
      } else if (subcommand === 'done') {
        await handleDone(interaction);
      } else if (subcommand === 'status') {
        await handleStatus(config, interaction, startedAt, active);
      } else if (subcommand === 'threads') {
        await handleThreads(config, interaction);
      } else if (subcommand === 'thread-set') {
        await handleThreadSet(config, interaction);
      } else if (subcommand === 'thread-new') {
        await handleThreadNew(config, interaction);
      }
    } catch (error) {
      console.error(error);
      const response = {
        content: `Agent error: ${error.message}`,
        ephemeral: true,
      };

      if (interaction.deferred || interaction.replied) {
        await interaction.followUp(response);
      } else {
        await interaction.reply(response);
      }
    }
  });

  client.on(Events.MessageCreate, async (message) => {
    try {
      await handleMessageReply(config, client, message, active);
    } catch (error) {
      console.error(error);
    }
  });

  await client.login(config.token);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
