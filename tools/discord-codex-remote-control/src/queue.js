const fs = require('node:fs/promises');
const path = require('node:path');
const crypto = require('node:crypto');

async function ensureQueue(queuePath) {
  await fs.mkdir(path.dirname(queuePath), { recursive: true });
  try {
    await fs.access(queuePath);
  } catch {
    await fs.writeFile(queuePath, '', 'utf8');
  }
}

async function enqueueCommand(queuePath, payload) {
  await ensureQueue(queuePath);

  const entry = {
    id: crypto.randomUUID(),
    status: 'pending',
    createdAt: new Date().toISOString(),
    ...payload,
  };

  await fs.appendFile(queuePath, `${JSON.stringify(entry)}\n`, 'utf8');
  return entry;
}

async function countQueuedCommands(queuePath) {
  try {
    const content = await fs.readFile(queuePath, 'utf8');
    return content.split('\n').filter((line) => line.trim()).length;
  } catch (error) {
    if (error.code === 'ENOENT') {
      return 0;
    }
    throw error;
  }
}

async function readQueuedCommands(queuePath) {
  try {
    const content = await fs.readFile(queuePath, 'utf8');
    return content
      .split('\n')
      .map((line) => line.trim())
      .filter(Boolean)
      .map((line) => JSON.parse(line));
  } catch (error) {
    if (error.code === 'ENOENT') {
      return [];
    }
    throw error;
  }
}

module.exports = {
  countQueuedCommands,
  enqueueCommand,
  ensureQueue,
  readQueuedCommands,
};
