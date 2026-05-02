const fs = require('node:fs/promises');
const path = require('node:path');

async function appendAgentEvent(config, type, payload = {}) {
  const filePath = path.join(config.rootDir, 'data', 'agent-events.jsonl');
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.appendFile(filePath, `${JSON.stringify({
    at: new Date().toISOString(),
    type,
    ...payload,
  })}\n`, 'utf8');
}

module.exports = {
  appendAgentEvent,
};
