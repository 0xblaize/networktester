// Network Tester - real internet speed testing.

const SPEED_DOWNLOAD_URL = 'https://speed.cloudflare.com/__down';
const SPEED_UPLOAD_URL = 'https://speed.cloudflare.com/__up';

const state = {
    isTesting: false
};

const speedValue = document.getElementById('speedValue');
const speedUnit = document.getElementById('speedUnit');
const speedLabel = document.getElementById('speedLabel');
const downloadSpeed = document.getElementById('downloadSpeed');
const uploadSpeed = document.getElementById('uploadSpeed');
const pingValue = document.getElementById('pingValue');
const progressFill = document.getElementById('progressFill');
const progressText = document.getElementById('progressText');
const startButton = document.getElementById('startButton');
const resetButton = document.getElementById('resetButton');
const gaugeNeedle = document.getElementById('gaugeNeedle');
const websiteUrl = document.getElementById('websiteUrl');
const websiteButton = document.getElementById('websiteButton');
const websiteStatus = document.getElementById('websiteStatus');
const websiteTotalTime = document.getElementById('websiteTotalTime');
const websiteFirstByte = document.getElementById('websiteFirstByte');
const websiteSize = document.getElementById('websiteSize');
const websiteMessage = document.getElementById('websiteMessage');

async function startTest() {
    if (state.isTesting) return;

    state.isTesting = true;
    startButton.disabled = true;
    resetButton.disabled = true;
    resetDisplay();
    updateProgress(2, 'Connecting to external speed test server...');

    try {
        const ping = await testPing();
        pingValue.textContent = `${ping} ms`;
        updateMainDisplay(ping, 'Ping');
        updateProgress(20, 'Testing real download speed...');

        const download = await testDownloadSpeed();
        downloadSpeed.textContent = `${download.toFixed(2)} Mbps`;
        updateMainDisplay(download, 'Download');
        updateProgress(62, 'Testing real upload speed...');

        const upload = await testUploadSpeed();
        uploadSpeed.textContent = `${upload.toFixed(2)} Mbps`;
        updateMainDisplay(upload, 'Upload');
        updateProgress(100, 'Real internet speed test complete');
    } catch (error) {
        console.error('Test error:', error);
        updateMainDisplay(0, 'Error');
        updateProgress(0, `Error: ${error.message}`);
    } finally {
        state.isTesting = false;
        startButton.disabled = false;
        resetButton.disabled = false;
    }
}

async function testPing() {
    const samples = [];

    for (let i = 0; i < 6; i++) {
        const start = performance.now();
        const response = await fetch(`${SPEED_DOWNLOAD_URL}?bytes=0&r=${cacheBuster()}`, {
            method: 'GET',
            cache: 'no-store'
        });

        if (!response.ok) throw new Error('External ping test failed');
        await response.arrayBuffer();
        samples.push(performance.now() - start);
        await delay(120);
    }

    samples.sort((a, b) => a - b);
    const trimmed = samples.slice(1, samples.length - 1);
    return Math.round(average(trimmed));
}

async function testDownloadSpeed() {
    const durationMs = 12000;
    const chunkSizes = [
        1 * 1024 * 1024,
        5 * 1024 * 1024,
        10 * 1024 * 1024,
        25 * 1024 * 1024
    ];
    const start = performance.now();
    let totalBytes = 0;
    let requestIndex = 0;
    const speeds = [];

    while (performance.now() - start < durationMs) {
        const size = chunkSizes[Math.min(requestIndex, chunkSizes.length - 1)];
        const requestStart = performance.now();
        const response = await fetch(`${SPEED_DOWNLOAD_URL}?bytes=${size}&r=${cacheBuster()}`, {
            method: 'GET',
            cache: 'no-store'
        });

        if (!response.ok || !response.body) throw new Error('External download test failed');

        const reader = response.body.getReader();
        let requestBytes = 0;

        while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            requestBytes += value.length;
            totalBytes += value.length;
            const elapsed = (performance.now() - start) / 1000;
            const currentMbps = bytesToMbps(totalBytes, elapsed);
            updateMainDisplay(currentMbps, 'Download');
            updateProgress(20 + Math.min(40, ((performance.now() - start) / durationMs) * 40), 'Testing real download speed...');
        }

        const requestSeconds = (performance.now() - requestStart) / 1000;
        if (requestSeconds > 0.15) speeds.push(bytesToMbps(requestBytes, requestSeconds));
        requestIndex++;
    }

    if (totalBytes === 0) throw new Error('No download data was received');
    return percentile(speeds.length ? speeds : [bytesToMbps(totalBytes, (performance.now() - start) / 1000)], 0.8);
}

async function testUploadSpeed() {
    const durationMs = 10000;
    const payloadSizes = [
        512 * 1024,
        1 * 1024 * 1024,
        5 * 1024 * 1024,
        10 * 1024 * 1024
    ];
    const start = performance.now();
    let totalBytes = 0;
    let requestIndex = 0;
    const speeds = [];

    while (performance.now() - start < durationMs) {
        const size = payloadSizes[Math.min(requestIndex, payloadSizes.length - 1)];
        const payload = new Uint8Array(size);
        const requestStart = performance.now();

        const response = await fetch(`${SPEED_UPLOAD_URL}?r=${cacheBuster()}`, {
            method: 'POST',
            body: payload,
            cache: 'no-store'
        });

        if (!response.ok) throw new Error('External upload test failed');
        await response.arrayBuffer();

        totalBytes += size;
        const requestSeconds = (performance.now() - requestStart) / 1000;
        if (requestSeconds > 0.15) speeds.push(bytesToMbps(size, requestSeconds));

        const elapsed = (performance.now() - start) / 1000;
        const currentMbps = bytesToMbps(totalBytes, elapsed);
        updateMainDisplay(currentMbps, 'Upload');
        updateProgress(62 + Math.min(36, ((performance.now() - start) / durationMs) * 36), 'Testing real upload speed...');
        requestIndex++;
    }

    if (totalBytes === 0) throw new Error('No upload data was sent');
    return percentile(speeds.length ? speeds : [bytesToMbps(totalBytes, (performance.now() - start) / 1000)], 0.8);
}

function updateMainDisplay(value, label) {
    const displayValue = Number.isFinite(value) ? Math.max(0, value) : 0;
    speedValue.textContent = displayValue >= 100 ? displayValue.toFixed(0) : displayValue.toFixed(2);
    speedUnit.textContent = label === 'Ping' ? 'ms' : 'Mbps';
    speedLabel.textContent = label === 'Ping' ? 'External Ping' : `${label} Speed`;
    updateGauge(label === 'Ping' ? 0 : displayValue);
}

function updateGauge(mbps) {
    const capped = Math.min(Math.max(mbps, 0), 1000);
    const normalized = Math.log10(capped + 1) / Math.log10(1001);
    const degrees = -120 + normalized * 240;
    gaugeNeedle.style.transform = `rotate(${degrees}deg)`;
}

function updateProgress(percentage, text) {
    progressFill.style.width = `${Math.max(0, Math.min(100, percentage))}%`;
    progressText.textContent = text;
}

function resetTest() {
    if (state.isTesting) return;

    speedValue.textContent = '0';
    speedUnit.textContent = 'Mbps';
    speedLabel.textContent = 'Click "Start Test" to begin';
    downloadSpeed.textContent = '-- Mbps';
    uploadSpeed.textContent = '-- Mbps';
    pingValue.textContent = '-- ms';
    progressFill.style.width = '0%';
    progressText.textContent = 'Ready to test real internet speed';
    updateGauge(0);
}

function resetDisplay() {
    resetTest();
}

async function testWebsite() {
    const url = websiteUrl.value.trim();
    if (!url) {
        websiteMessage.textContent = 'Enter a website URL first.';
        return;
    }

    websiteButton.disabled = true;
    websiteMessage.textContent = 'Testing website...';
    websiteStatus.textContent = '--';
    websiteTotalTime.textContent = '-- ms';
    websiteFirstByte.textContent = '-- ms';
    websiteSize.textContent = '--';

    try {
        const result = await window.networkTester.testWebsite(url);

        websiteStatus.textContent = String(result.statusCode || '--');
        websiteTotalTime.textContent = `${result.totalTimeMs} ms`;
        websiteFirstByte.textContent = result.firstByteTimeMs === null ? 'N/A' : `${result.firstByteTimeMs} ms`;
        websiteSize.textContent = formatBytes(result.downloadBytes || 0);
        websiteMessage.textContent = `Final URL: ${result.finalUrl}`;
    } catch (error) {
        websiteMessage.textContent = `Error: ${error.message}`;
    } finally {
        websiteButton.disabled = false;
    }
}

function bytesToMbps(bytes, seconds) {
    return (bytes * 8) / (1024 * 1024) / seconds;
}

function average(values) {
    return values.reduce((sum, value) => sum + value, 0) / values.length;
}

function percentile(values, p) {
    const sorted = [...values].sort((a, b) => a - b);
    const index = Math.min(sorted.length - 1, Math.max(0, Math.ceil(sorted.length * p) - 1));
    return sorted[index];
}

function cacheBuster() {
    return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function formatBytes(bytes) {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
}

function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

window.addEventListener('DOMContentLoaded', () => {
    resetDisplay();
});
