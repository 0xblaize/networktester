# NetworkTester

NetworkTester is a standalone Windows desktop application for testing real internet connection performance.

It is built with C# WinForms and runs as a normal `.exe` application. The app measures download speed, upload speed, and ping using external Cloudflare speed test servers, then displays the results in a simple speedometer-style interface.

## Overview

NetworkTester was built to make internet speed testing simple, visual, and easy to understand.

Instead of opening a browser-based speed test website, users can launch NetworkTester directly from their Windows desktop and test their connection inside a clean desktop app window.

The goal is to provide a lightweight tool that helps users quickly understand how strong, weak, or unstable their internet connection is.

## Features

- Standalone Windows `.exe` application
- Built with C# WinForms
- Real internet speed testing
- Download speed test
- Upload speed test
- Ping test
- Speedometer-style user interface
- Uses external Cloudflare speed test servers
- Simple and beginner-friendly desktop experience
- Displays low speeds below 1 Mbps in Kbps

## Why I Built This

Many users experience slow or unstable internet but do not always know what the issue is.

Sometimes the connection is slow. Sometimes the ping is high. Sometimes upload speed is the real problem. Sometimes the network is connected but unstable.

NetworkTester helps users check these basic network metrics from a simple Windows desktop app.

## Tech Stack

- C#
- WinForms
- .NET Framework
- Cloudflare speed test endpoints

## How It Works

NetworkTester runs as a desktop application on Windows.

When the user starts a test, the app connects to external Cloudflare speed test servers and measures:

- Download speed by fetching test data
- Upload speed by sending test data
- Ping by measuring response time

The results are displayed inside the app through a visual speedometer-style interface.

## Getting Started

### Option 1: Install The App

Build the installer:

```bat
build-installer.bat
```

Then open:

```text
dist\NetworkTesterSetup.exe
```

The installer copies NetworkTester to your Windows user app folder and creates Desktop and Start Menu shortcuts.

The installer is built directly with C# and does not use IExpress. The build scripts use the project folder as their root, so they do not depend on a specific user path like `C:\Users\USER\...`.

### Option 2: Run The App Directly

Open the executable file:

```text
dist\NetworkTester.exe
```

Double-click the file to launch the app.

### Option 3: Build From Source

Clone the repository:

```bash
git clone https://github.com/0xblaize/networktester.git
```

Build the native Windows app:

```bat
build-native.bat
```

After building, run:

```text
dist\NetworkTester.exe
```

## Project Structure

```text
network tester/
├── build-native.bat
├── build-installer.bat
├── dist/
│   ├── NetworkTester.exe
│   └── NetworkTesterSetup.exe
└── src/
    └── native/
        ├── Installer.cs
        └── NetworkTester.cs
```

## Project Status

NetworkTester is currently in active development.

The core version can test download speed, upload speed, and ping from a standalone Windows desktop app.

## Planned Improvements

- Improve speed test accuracy
- Add better error handling for poor connections
- Add a network stability score
- Add result history
- Add dark mode
- Add Windows installer support
- Improve the speedometer animation
- Add more detailed connection reports

## Use Cases

NetworkTester can be useful for:

- Checking internet speed quickly
- Testing unstable Wi-Fi connections
- Confirming download and upload performance
- Checking ping before online meetings, gaming, or streaming
- Learning how desktop network tools work in C#

## Author

Built by Alawode Christopher (Blaize)

GitHub: [0xblaize](https://github.com/0xblaize)

## License

This project is open source and available under the MIT License.
