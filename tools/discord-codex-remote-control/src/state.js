const fs = require('node:fs/promises');
const path = require('node:path');

async function ensureState(config) {
  await fs.mkdir(path.dirname(config.runnerStatePath), { recursive: true });
  try {
    const content = await fs.readFile(config.runnerStatePath, 'utf8');
    return JSON.parse(content);
  } catch (error) {
    if (error.code !== 'ENOENT') {
      throw error;
    }
    return { tasks: {}, codexThreadId: config.codexThreadId };
  }
}

async function writeState(config, state) {
  await fs.mkdir(path.dirname(config.runnerStatePath), { recursive: true });
  await fs.writeFile(config.runnerStatePath, `${JSON.stringify(state, null, 2)}\n`, 'utf8');
}

module.exports = {
  ensureState,
  writeState,
};
