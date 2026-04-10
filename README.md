# openDAQ-bundle

A CMake super-project that bundles [openDAQ](https://github.com/openDAQ/openDAQ) together with its optional modules:
- [OpcUaModules](https://github.com/openDAQ/OpcUaModules)
- [MQTTStreamingModule](https://github.com/openDAQ/MQTTStreamingModule)
- [LTStreamingModulesModern](https://github.com/openDAQ/LTStreamingModulesModern)
- [ASAM-CMP-Modules](https://github.com/openDAQ/ASAM-CMP-Modules)

All dependencies are fetched automatically via CMake's `FetchContent`.

## Prerequisites

- CMake 3.25 or newer
- Git
- **Windows:** Visual Studio 2017 or 2022 (with C++ workload) — used as compiler toolchain only
- **Linux:** GCC or Clang, Ninja

## Configure

Use one of the available CMake presets:

| Preset | Platform | Compiler | Arch | Config |
|---|---|---|---|---|
| `x64/msvc-22` | Windows | MSVC 2022 | x64 | Release |
| `x86/msvc-22` | Windows | MSVC 2022 | x86 | Release |
| `x64/msvc-17` | Windows | MSVC 2017 | x64 | Release |
| `x86/msvc-17` | Windows | MSVC 2017 | x86 | Release |
| `x64/gcc/release` | Linux | GCC | x64 | Release |
| `x64/gcc/debug` | Linux | GCC | x64 | Debug |
| `x64/clang/release` | Linux | Clang | x64 | Release |
| `x64/clang/debug` | Linux | Clang | x64 | Debug |

```bash
# Windows
cmake --preset="x64/msvc-22"

# Linux
cmake --preset="x64/gcc/release"
```

## Build

```bash
# Windows
cmake --build --preset="x64/msvc-22" --config Release

# Linux
cmake --build --preset="x64/gcc/release"
```

## CMake Options

| Option | Default | Description |
|---|---|---|
| `RELEASE_REPO_ENABLE_TESTS` | `OFF` | Build and enable tests |
| `RELEASE_REPO_ENABLE_OPCUA_MODULE` | `ON` | Include OPC UA module |
| `RELEASE_REPO_ENABLE_MQTT_MODULE` | `ON` | Include MQTT streaming module |
| `RELEASE_REPO_ENABLE_LT_MODULE` | `ON` | Include LT streaming module |
| `RELEASE_REPO_ENABLE_ASAM_CMP_MODULE` | `ON` | Include ASAM-CMP modules |

Pass options at configure time:

```bash
cmake --preset="x64/gcc/release" -DRELEASE_REPO_ENABLE_TESTS=ON
```
