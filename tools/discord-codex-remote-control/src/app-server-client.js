const { spawn } = require('node:child_process');
const { EventEmitter } = require('node:events');

function splitLines(buffer) {
  const lines = buffer.split(/\r?\n/);
  return {
    complete: lines.slice(0, -1),
    rest: lines.at(-1) || '',
  };
}

class CodexAppServerClient extends EventEmitter {
  constructor(config) {
    super();
    this.config = config;
    this.nextId = 1;
    this.pending = new Map();
    this.stdoutBuffer = '';
    this.stderr = '';
    this.child = undefined;
  }

  start() {
    const command = process.platform === 'win32' ? 'powershell.exe' : this.config.codexExecutable;
    const args = process.platform === 'win32'
      ? ['-NoProfile', '-NonInteractive', '-Command', '& $env:CODEX_RUNNER_EXECUTABLE app-server']
      : ['app-server'];

    this.child = spawn(command, args, {
      cwd: this.config.workspaceRoot,
      windowsHide: true,
      shell: false,
      env: {
        ...process.env,
        CODEX_RUNNER_EXECUTABLE: this.config.codexExecutable,
      },
    });

    this.child.stdout.on('data', (chunk) => this.handleStdout(chunk));
    this.child.stderr.on('data', (chunk) => {
      this.stderr += chunk.toString();
    });
    this.child.on('error', (error) => {
      this.rejectAll(error);
      this.emit('error', error);
    });
    this.child.on('close', (code) => {
      const error = new Error(`codex app-server exited with code ${code}`);
      error.code = code;
      this.rejectAll(error);
      this.emit('close', code);
    });
  }

  handleStdout(chunk) {
    this.stdoutBuffer += chunk.toString();
    const { complete, rest } = splitLines(this.stdoutBuffer);
    this.stdoutBuffer = rest;

    for (const line of complete) {
      const trimmed = line.trim();
      if (!trimmed) {
        continue;
      }

      let message;
      try {
        message = JSON.parse(trimmed);
      } catch (error) {
        this.emit('parseError', { line: trimmed, error });
        continue;
      }

      if (Object.prototype.hasOwnProperty.call(message, 'id')) {
        const pending = this.pending.get(message.id);
        if (pending) {
          this.pending.delete(message.id);
          if (message.error) {
            const error = new Error(message.error.message || JSON.stringify(message.error));
            error.rpcError = message.error;
            pending.reject(error);
          } else {
            pending.resolve(message.result);
          }
        }
      } else if (message.method) {
        this.emit('notification', message);
      }
    }
  }

  rejectAll(error) {
    for (const pending of this.pending.values()) {
      pending.reject(error);
    }
    this.pending.clear();
  }

  request(method, params = {}) {
    if (!this.child || !this.child.stdin.writable) {
      return Promise.reject(new Error('codex app-server is not running'));
    }

    const id = this.nextId;
    this.nextId += 1;
    const payload = { id, method, params };

    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.child.stdin.write(`${JSON.stringify(payload)}\n`, (error) => {
        if (error) {
          this.pending.delete(id);
          reject(error);
        }
      });
    });
  }

  notify(method, params = {}) {
    if (!this.child || !this.child.stdin.writable) {
      throw new Error('codex app-server is not running');
    }
    this.child.stdin.write(`${JSON.stringify({ method, params })}\n`);
  }

  async initialize() {
    const result = await this.request('initialize', {
      clientInfo: {
        name: 'discord_codex_local_bridge',
        title: 'Discord Codex Local Bridge',
        version: '0.1.0',
      },
      capabilities: {
        experimentalApi: true,
      },
    });
    this.notify('initialized');
    return result;
  }

  close() {
    if (!this.child) {
      return;
    }
    if (this.child.stdin.writable) {
      this.child.stdin.end();
    }
    this.child.kill();
  }
}

module.exports = {
  CodexAppServerClient,
};
