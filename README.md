# Clipboard Push — Windows Client

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D4.svg)](https://www.microsoft.com/windows)
[![C++17](https://img.shields.io/badge/C%2B%2B-17-00599C.svg)](https://en.cppreference.com)
[![Platform](https://img.shields.io/badge/platform-x64-lightgrey.svg)]()

A lightweight, dependency-free native Windows client for **[Clipboard Push](https://clipboardpush.com)** — push clipboard text, images, and files between your PC and mobile device over Wi-Fi or through a relay server, with end-to-end AES-256-GCM encryption.

**Related:** [Website](https://clipboardpush.com) · [Android App](https://github.com/yelosheng/clipboard-push-android) · [Relay Server](https://github.com/yelosheng/clipboard-push-server)

---

## Features

- **Text sync** — push clipboard text manually (hotkey or button) or automatically on every copy
- **Image sync** — copy a screenshot on PC, paste it instantly on your phone, and vice versa
- **File transfer** — direct LAN pull for fast local transfers; automatic cloud relay fallback
- **End-to-end encryption** — AES-256-GCM; the relay server never sees plaintext content
- **QR code pairing** — scan the in-app QR code from Android to connect in seconds
- **Zero dependencies** — single statically linked `.exe`, runs on clean Windows 10/11 with no installer
- **System tray** — color-coded status indicator (green = synced, yellow = connected, red = disconnected)
- **Auto-start** — optional Windows startup registration

---

## Quick Start

1. Download the latest `ClipboardPushWin32.exe` from [Releases](../../releases).
2. Run it — no installer needed. Configuration is stored in `config.json` next to the `.exe`.
3. Open Settings (tray icon → Settings) and scan the QR code with the Android app.

The app connects to the relay server specified in Settings. Point it at your own self-hosted instance or use the default for testing.

---

## Build from Source

### Prerequisites

| Tool | Notes |
|------|-------|
| **Visual Studio 2022 Build Tools** (MSVC) | `cl.exe` required — MinGW/GCC is not supported |
| **CMake** ≥ 3.21 | |
| **vcpkg** | Set `VCPKG_ROOT` environment variable to its root directory |
| **Ninja** | Recommended; CMake falls back to MSBuild without it |

### Steps

```powershell
# 1. Clone
git clone https://github.com/yelosheng/clipboard-push-win32.git
cd clipboard-push-win32

# 2. Install vcpkg dependencies (static triplet is required)
vcpkg install --triplet x64-windows-static

# 3. Initialize MSVC environment
#    Adjust the path below to match your Visual Studio installation
call "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

# 4. Configure
cmake -G Ninja ^
  -DCMAKE_TOOLCHAIN_FILE=%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake ^
  -DVCPKG_TARGET_TRIPLET=x64-windows-static ^
  -DCMAKE_BUILD_TYPE=Release ^
  -B build

# 5. Build
cmake --build build
```

The output binary is `build/ClipboardPushWin32.exe` (~1 MB, no runtime dependencies).

> **Important:** You must use MSVC. If MinGW is also on your PATH, the build will fail or produce an incorrect binary. See [AI_BUILD_GUIDE.md](AI_BUILD_GUIDE.md) for details.

---

## Configuration

Settings are saved to `config.json` next to the `.exe`. Most options are available through the Settings window (tray → Settings).

| Key | Default | Description |
|-----|---------|-------------|
| `relay_server_url` | `http://your-server.com:12505/` | Your relay server address |
| `room_id` | auto-generated | Room identifier shared with your phone |
| `room_key` | auto-generated | AES-256 encryption key shared with your phone |
| `push_hotkey` | `Ctrl+F6` | Global hotkey to manually push clipboard |
| `auto_push_text` | `false` | Automatically push text on every clipboard copy |
| `auto_push_image` | `false` | Automatically push images |
| `auto_push_file` | `false` | Automatically push files |
| `auto_copy_image` | `true` | Auto-copy received images to clipboard |
| `auto_copy_file` | `true` | Auto-copy received files to clipboard |
| `lan_timeout` | `10` | Seconds to wait for LAN transfer before falling back to relay |
| `start_minimized` | `false` | Start directly to system tray |
| `auto_start` | `false` | Register with Windows startup |

**QR code pairing:** The QR code in Settings encodes all connection details (`room_id`, `room_key`, `relay_server_url`). Scan it once from the Android app to connect — no manual entry needed.

---

## Self-Hosting

This client requires a running instance of the [Clipboard Push Relay Server](https://github.com/yelosheng/clipboard-push-server).

1. Deploy your own relay server following its README.
2. In the Windows client, open Settings and update **Server URL** to point to your instance.
3. Re-scan the QR code on Android.

A public server is available for testing at [clipboardpush.com](https://clipboardpush.com), but it provides no uptime guarantees for production use.

---

## Security

### Encryption
All clipboard content (text, images, files) is AES-256-GCM encrypted on-device before transmission. The encryption key (`room_key`) never leaves your devices — the relay server relays only ciphertext.

Wire format: `[12-byte IV] + [ciphertext] + [16-byte GCM tag]`, Base64-encoded. Compatible with the Android client.

### Auto-Update
The application checks for updates at startup by fetching a version JSON from the configured download URL and, if a newer version is found, **automatically downloads and replaces the running `.exe` without signature verification**.

- If you build from source or deploy internally, you should **disable or modify** `CheckForUpdates()` in `main.cpp` and `PerformAutoUpdate()` to prevent unintended updates.
- The update URL is defined in `version-win32.json` and the `scripts/update_build.ps1` helper.

### Cloud File Relay
When a direct LAN transfer is not possible, files are uploaded to the relay server's configured storage backend (Cloudflare R2 or local disk) as a fallback. Files are always encrypted before upload (AES-256-GCM). The relay server automatically purges **all stored files every 60 minutes**, so files are never stored beyond the transfer window.

### LAN File Server
The built-in HTTP server (used for direct LAN file transfer) is protected by a shared `X-Room-ID` header. Only peers that know the `room_id` can access it. Run this only on trusted local networks.

---

## Project Structure

```
src/
├── main.cpp                 # Entry point, message loop, sync orchestration
├── core/
│   ├── Config              # JSON config load/save, auto-start registry
│   ├── Crypto              # AES-256-GCM (Windows BCrypt API), Base64
│   ├── Logger              # Thread-safe logging (OutputDebugString + printf)
│   ├── Network             # WinHTTP wrapper (HTTP client + WebSocket client)
│   ├── SocketIOService     # Socket.IO protocol (connect, join room, events)
│   ├── LocalServer         # LAN HTTP server for direct file transfer (cpp-httplib)
│   └── Utils               # String conversion, network metadata, registry helpers
├── platform/
│   ├── Platform            # GDI+, Winsock init/shutdown
│   ├── Clipboard           # Read/write text, images (DIB), files (CF_HDROP)
│   ├── ClipboardMonitor    # AddClipboardFormatListener, loop-prevention
│   └── Hotkey              # RegisterHotKey global hotkey
└── ui/
    ├── MainWindow          # Main input window + status display
    ├── SettingsWindow      # Settings dialog + live QR code rendering
    ├── TrayIcon            # System tray icon, dynamic GDI+ status badge
    └── NotificationWindow  # Custom toast notification popup
```

---

## Third-Party Libraries

| Library | License | Usage |
|---------|---------|-------|
| [nlohmann/json](https://github.com/nlohmann/json) | MIT | JSON parsing (vcpkg) |
| [nayuki/QR-Code-generator](https://github.com/nayuki/QR-Code-generator) | MIT | QR code rendering (vcpkg) |
| [yhirose/cpp-httplib](https://github.com/yhirose/cpp-httplib) v0.32.0 | MIT | LAN HTTP server (vendored in `src/core/httplib.h`) |

---

## License

MIT License — see [LICENSE](LICENSE).
