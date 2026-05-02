const { loadConfig } = require('./config');
const { COLORS, sendWebhook } = require('./webhook');

async function main() {
  const [summary, details] = process.argv.slice(2);

  if (!summary) {
    throw new Error('Usage: npm run notify -- "summary" "optional details"');
  }

  const config = loadConfig({ requireWebhook: true });
  await sendWebhook(config.webhookUrl, {
    title: '작업 완료 - 검토 대기',
    description: [
      summary,
      details ? '' : null,
      details ? ['세부 작업', details.slice(0, 1800)].join('\n') : null,
      '',
      '다음 작업을 지시하려면 이 Discord 메시지에 답글을 달아주세요.',
    ]
      .filter(Boolean)
      .join('\n'),
    color: COLORS.completed,
  });

  console.log('Discord notification sent.');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
