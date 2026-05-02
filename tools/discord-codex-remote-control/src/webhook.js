const COLORS = {
  info: 0x3498db,
  queued: 0x9b59b6,
  started: 0xf1c40f,
  completed: 0x2ecc71,
  failed: 0xe74c3c,
};

async function sendWebhook(webhookUrl, { title, description, fields = [], color = COLORS.info }) {
  if (!webhookUrl) {
    return false;
  }

  const response = await fetch(webhookUrl, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      username: 'Codex Local Bridge',
      allowed_mentions: { parse: [] },
      embeds: [
        {
          title,
          description,
          color,
          fields,
          timestamp: new Date().toISOString(),
        },
      ],
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Discord webhook failed: ${response.status} ${body}`);
  }

  return true;
}

module.exports = {
  COLORS,
  sendWebhook,
};
