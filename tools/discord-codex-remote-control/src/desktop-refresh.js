const { spawn } = require('node:child_process');

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function openUrl(url) {
  return new Promise((resolve, reject) => {
    const child = spawn('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      'Start-Process -FilePath $env:CODEX_DESKTOP_URL',
    ], {
      windowsHide: true,
      env: {
        ...process.env,
        CODEX_DESKTOP_URL: url,
      },
    });

    child.on('error', reject);
    child.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Failed to open ${url}: exit ${code}`));
      }
    });
  });
}

async function refreshCodexDesktop(config, threadId) {
  if (!config.refreshCodexDesktop || !threadId || process.platform !== 'win32') {
    return { refreshed: false };
  }

  if (config.codexDesktopRefreshBounce) {
    await openUrl('codex://settings');
    await sleep(config.codexDesktopRefreshDelayMs);
  }

  const threadUrl = `codex://threads/${encodeURIComponent(threadId)}`;
  await openUrl(threadUrl);
  return { refreshed: true, url: threadUrl };
}

module.exports = {
  refreshCodexDesktop,
};
