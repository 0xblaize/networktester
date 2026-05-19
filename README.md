# Network Tester

A lightweight Windows desktop-style network tester. It measures real download speed, real upload speed, external ping latency, and website response timing in an app window.

## Build A Real Native Windows App

This project includes a C# WinForms native version. It does not need PHP, Node, Electron, or a browser.

Build it:

```bat
build-native.bat
```

Run it:

```text
dist\NetworkTester.exe
```

This is the recommended version if you want a normal Windows desktop app.

## Electron Desktop Version

Install the desktop dependencies once:

```powershell
npm install
```

Run the app:

```powershell
npm start
```

Build a Windows installer:

```powershell
npm run build
```

The installer will be created inside `dist`.

## Old Portable Launcher

1. Install Network Tester shortcuts:
   ```bat
   install-app.bat
   ```

2. Launch **Network Tester** from your Desktop or Start Menu.

The launcher starts a local app server in the background, opens the app in a standalone Edge or Chrome app window, and stops the server when the app window closes.

## Portable Run

Double-click:

```bat
run-app.bat
```

## Project Structure

```text
network tester/
+-- install-app.bat
+-- Install-NetworkTester.ps1
+-- NetworkTester.ps1
+-- run-app.bat
+-- index.php
+-- public/
|   +-- index.html
|   +-- styles.css
|   +-- app.js
+-- src/
    +-- api/
        +-- ping.php
        +-- download-test.php
        +-- upload-test.php
        +-- website-test.php
```

## Notes

- This is a local desktop app wrapper.
- It does not need PHP to launch on Windows.
- Internet speed tests use Cloudflare's public speed test endpoints, so the data crosses your internet connection.
- Do not expose the local app server to the public internet.
