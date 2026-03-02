# Clipboard Push Win32: AI Build Guide

**For AI assistants working on this project:**
This is a native C++ project targeting maximum compatibility (Win10/11) and minimal size (<1 MB). The build environment has strict requirements. Follow these rules exactly to avoid linker errors or runtime crashes.

---

## 1. Core Build Environment

Before running any build command, confirm the following tools are available:

- **MSVC toolchain** — Visual Studio 2022 Build Tools (or full VS 2022), `cl.exe` must be on PATH.
  Initialize with: `vcvars64.bat` from your VS installation.
  Typical location: `C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat`
  (Adjust path to match the actual VS install on this machine.)
- **vcpkg root** — Set `VCPKG_ROOT` environment variable to the vcpkg installation directory.
- **CMake toolchain file** — `%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake`
- **Ninja** — Recommended generator; falls back to MSBuild if unavailable.

---

## 2. The Canonical Build Command

### Incremental build (normal usage)

```bash
powershell -NoProfile -Command "cmd /c 'D:\APPs\z_pan_python\clipboard_push_win32-client\build_release.bat'"
```

`build_release.bat` (already in project root):
```bat
@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
cmake --build "D:\APPs\z_pan_python\clipboard_push_win32-client\build"
```

> **Important:** Do NOT use `cmd /c` directly from Git Bash — MSYS path conversion silently breaks it.
> Always wrap with `powershell -NoProfile -Command "cmd /c '...'"`.

### Clean rebuild (from scratch)

```bat
@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
cd /d "D:\APPs\z_pan_python\clipboard_push_win32-client"
rd /s /q build & mkdir build & cd build
cmake -G "Ninja" -DCMAKE_TOOLCHAIN_FILE=D:\vcpkg\scripts\buildsystems\vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x64-windows-static -DCMAKE_BUILD_TYPE=Release ..
cmake --build .
```

### Confirmed environment (this machine)
- vcvars64.bat: `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat`
- VCPKG_ROOT: `D:\vcpkg`
- Ninja: `D:\mingw64\bin\ninja.exe`

---

## 3. Four Non-Negotiable Rules

1. **Never change the static-linking configuration.**
   - Always use `-DVCPKG_TARGET_TRIPLET=x64-windows-static`.
   - `CMakeLists.txt` must retain `/MT` (Static CRT). This prevents crashes on machines without the VC++ Redistributable.

2. **Never mix compilers.**
   - If you see errors referencing a MinGW path, do not try to accommodate it. Re-initialize MSVC via `vcvars64.bat` and force `cl.exe`.

3. **Keep GUI mode (no console window).**
   - The entry point must be `APIENTRY wWinMain`.
   - `add_executable` must include the `WIN32` flag.
   - Never change back to `main()` — doing so causes a black console window to appear at runtime.

4. **Be careful with format strings in log calls.**
   - `LOG_DEBUG` / `LOG_INFO` / `LOG_ERROR` use `printf`-style formatting.
   - Never pass a raw user-supplied string or JSON payload directly as the format argument.
   - Always use `LOG_INFO("msg: %s", someString.c_str())` — never `LOG_INFO(someString.c_str())`.
   - This is especially important when logging Socket.IO JSON messages, which may contain `%` characters that would be interpreted as format specifiers and crash the process.

---

## 4. Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Compiled successfully, crashes on startup | Dynamic CRT (`/MD`) used instead of static | Check `.exe` size — correct fully static build is **940–960 KB** |
| "Cannot find header" errors | Wrong `CMAKE_TOOLCHAIN_FILE` path | Verify `VCPKG_ROOT` and re-run CMake |
| Ninja not found | Ninja not installed | Remove `-G "Ninja"` to use the default MSBuild generator (still requires `vcvars64.bat`) |
| MinGW path appears in error output | GCC picked up from PATH | Re-run `vcvars64.bat` in a fresh shell before CMake |

---

**Current version: v4.7.0 Stable**
**Protocol: 4.0 — Peer-aware, LAN direct transfer + cloud relay fallback.**
