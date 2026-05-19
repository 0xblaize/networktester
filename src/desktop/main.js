const { app, BrowserWindow, ipcMain, Menu } = require('electron');
const https = require('node:https');
const http = require('node:http');
const path = require('node:path');

function createWindow() {
    const window = new BrowserWindow({
        width: 860,
        height: 920,
        minWidth: 760,
        minHeight: 760,
        title: 'Network Tester',
        backgroundColor: '#101820',
        autoHideMenuBar: true,
        webPreferences: {
            preload: path.join(__dirname, 'preload.js'),
            contextIsolation: true,
            nodeIntegration: false,
            sandbox: false
        }
    });

    Menu.setApplicationMenu(null);
    window.loadFile(path.join(__dirname, '../../public/index.html'));
}

app.whenReady().then(() => {
    ipcMain.handle('website:test', async (_event, url) => testWebsite(url));
    createWindow();

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) {
            createWindow();
        }
    });
});

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

function testWebsite(rawUrl) {
    return new Promise((resolve, reject) => {
        let target = String(rawUrl || '').trim();
        if (!target) {
            reject(new Error('URL is required'));
            return;
        }

        if (!/^https?:\/\//i.test(target)) {
            target = `https://${target}`;
        }

        let parsed;
        try {
            parsed = new URL(target);
        } catch {
            reject(new Error('Enter a valid website URL'));
            return;
        }

        const client = parsed.protocol === 'http:' ? http : https;
        const startedAt = performance.now();
        let firstByteAt = 0;
        let bytes = 0;

        const request = client.request(parsed, {
            method: 'GET',
            timeout: 15000,
            headers: {
                'User-Agent': 'Network Tester/1.0'
            }
        }, response => {
            response.on('data', chunk => {
                if (!firstByteAt) {
                    firstByteAt = performance.now();
                }
                bytes += chunk.length;
            });

            response.on('end', () => {
                const endedAt = performance.now();
                resolve({
                    url: target,
                    finalUrl: target,
                    statusCode: response.statusCode || 0,
                    totalTimeMs: Math.round(endedAt - startedAt),
                    firstByteTimeMs: firstByteAt ? Math.round(firstByteAt - startedAt) : null,
                    downloadBytes: bytes
                });
            });
        });

        request.on('timeout', () => {
            request.destroy(new Error('Website request timed out'));
        });

        request.on('error', error => {
            reject(error);
        });

        request.end();
    });
}
