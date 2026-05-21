# NetworkTester

NetworkTester is a standalone desktop application for testing real internet connection performance.

The Windows version is built with C# WinForms and runs as a normal `.exe` application. A separate macOS version is included as a SwiftUI app that can be packaged into a `.dmg` installer on a Mac.

The app measures download speed, upload speed, and ping using external Cloudflare speed test servers, then displays the results in a simple speedometer-style interface.

## Overview

NetworkTester was built to make internet speed testing simple, visual, and easy to understand.

Instead of opening a browser-based speed test website, users can launch NetworkTester directly from their desktop and test their connection inside a clean native app window.

The goal is to provide a lightweight tool that helps users quickly understand how strong, weak, or unstable their internet connection is.

## Features

- Standalone Windows `.exe` application
- Windows installer generated as `NetworkTesterSetup.exe`
- macOS SwiftUI version with `.dmg` build script
- Real internet speed testing
- Download speed test
- Upload speed test
- Ping test
- Website response test
- Speedometer-style user interface
- Uses external Cloudflare speed test servers
- Displays speeds below 1 Mbps in Kbps
- Simple desktop experience

## Tech Stack

- C#
- WinForms
- .NET Framework
- Swift
- SwiftUI
- Cloudflare speed test endpoints

## How It Works

When the user starts a test, NetworkTester connects to external Cloudflare speed test servers and measures:

- Download speed by fetching test data
- Upload speed by sending test data
- Ping by measuring response time

The results are displayed inside the app through a visual speedometer-style interface.

## Windows

### Build The Windows App

Run this from the project root:

```bat
build-native.bat
```

Output:

```text
dist\NetworkTester.exe
```

### Build The Windows Installer

Run this from the project root:

```bat
build-installer.bat
```

Output:

```text
dist\NetworkTesterSetup.exe
```

Double-click `NetworkTesterSetup.exe` to install the app. The installer copies NetworkTester to the current user's Windows app folder and creates Desktop and Start Menu shortcuts.

The build scripts use the project folder as their root, so they do not depend on a specific path like `C:\Users\USER\...`.

## macOS DMG

The macOS `.dmg` must be built on a Mac. Windows cannot build a real macOS `.dmg` app because it needs Apple's SwiftUI, Xcode tools, and `hdiutil`.

On a Mac, install Xcode Command Line Tools:

```bash
xcode-select --install
```

Then run this from the project root:

```bash
chmod +x macos/build-dmg.sh
./macos/build-dmg.sh
```

Output:

```text
dist/NetworkTester.dmg
```

Open the DMG on macOS, then drag `NetworkTester.app` into Applications.

## Run From Source

Clone the repository:

```bash
git clone https://github.com/0xblaize/networktester.git
```

Build the Windows app on Windows:

```bat
build-native.bat
```

Build the macOS DMG on macOS:

```bash
chmod +x macos/build-dmg.sh
./macos/build-dmg.sh
```

## Project Structure

```text
network tester/
+-- build-native.bat
+-- build-installer.bat
+-- dist/
|   +-- NetworkTester.exe
|   +-- NetworkTesterSetup.exe
|   +-- NetworkTester.dmg
+-- macos/
|   +-- Info.plist
|   +-- NetworkTesterMac.swift
|   +-- build-dmg.sh
+-- src/
    +-- native/
        +-- Installer.cs
        +-- NetworkTester.cs
```

## Project Status

NetworkTester is currently in active development.

The core version can test download speed, upload speed, ping, and website response from a standalone desktop app.

## Planned Improvements

- Improve speed test accuracy
- Add better error handling for poor connections
- Add a network stability score
- Add result history
- Improve the speedometer animation
- Add more detailed connection reports
- Add signed release builds

## Use Cases

NetworkTester can be useful for:

- Checking internet speed quickly
- Testing unstable Wi-Fi connections
- Confirming download and upload performance
- Checking ping before online meetings, gaming, or streaming
- Testing if a website is reachable and how fast it responds
- Learning how desktop network tools work

## Author

Built by Alawode Christopher (Blaize)

GitHub: [0xblaize](https://github.com/0xblaize)

## License

This project is open source and available under the MIT License.
