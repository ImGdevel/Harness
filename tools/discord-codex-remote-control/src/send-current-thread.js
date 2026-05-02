const fs = require('node:fs');
const { Client, GatewayIntentBits } = require('discord.js');
const { loadConfig } = require('./config');
const { ensureState } = require('./state');
const { COLORS } = require('./webhook');

function findLastChannelId(queuePath) {
  if (!fs.existsSync(queuePath)) {
    return undefined;
  }

  const lines = fs.readFileSync(queuePath, 'utf8').trim().split(/\r?\n/).filter(Boolean).reverse();
  for (const line of lines) {
    try {
      const entry = JSON.parse(line);
      if (entry.channelId) {
        return entry.channelId;
      }
    } catch {
      // Ignore malformed queue history lines.
    }
  }

  return undefined;
}

async function main() {
  const config = loadConfig({ requireBot: true });
  const state = await ensureState(config);
  const channelId = findLastChannelId(config.queuePath);

  if (!channelId) {
    throw new Error('No channelId found in queue history');
  }

  const threadId = config.codexThreadId || state.codexThreadId || '(설정된 thread 없음)';
  const client = new Client({ intents: [GatewayIntentBits.Guilds] });
  await client.login(config.token);
  const channel = await client.channels.fetch(channelId);

  await channel.send({
    embeds: [
      {
        title: '현재 Codex Desktop 대화 thread 이어가기',
        description: [
          '현재 이 Desktop Codex 대화로 보이는 thread를 Discord Agent가 이어가도록 설정해둔 상태입니다.',
          '',
          `Codex thread id: ${threadId}`,
          '',
          '이 메시지에 답글을 달면 Agent가 Discord 입력을 Codex Desktop 입력창에 직접 타이핑하지는 않습니다.',
          '대신 같은 Codex App Server thread에 turn/start로 추가합니다.',
          'Desktop 앱에서 같은 thread를 열면 이어진 대화로 확인할 수 있습니다.',
        ].join('\n'),
        color: COLORS.info,
        timestamp: new Date().toISOString(),
        fields: [
          { name: '이어짐 여부', value: '기존 Codex thread 이어감' },
          { name: '실행 방식', value: 'Discord -> Agent -> codex app-server -> thread/resume -> turn/start' },
        ],
      },
    ],
  });

  await client.destroy();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
