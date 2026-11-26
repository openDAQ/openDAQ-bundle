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
- **Windows:** Visual Studio 2017 or 2022 (with C++ workload) — used as compiler toolchain only;
  [NSIS](https://nsis.sourceforge.io) 3 for the installer
- **Linux:** GCC or Clang, Ninja
- **macOS:** Xcode Command Line Tools (Apple Clang, `productbuild`), Ninja

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
| `x64/clang/release` | macOS | Apple Clang | the machine's | Release |

```bash
# Windows
cmake --preset="x64/msvc-22"

# Linux
cmake --preset="x64/gcc/release"

# macOS
cmake --preset="x64/clang/release"
```

## Build

```bash
# Windows
cmake --build build\x64\msvc-22 --config Release

# Linux
cmake --build build/x64/gcc/release

# macOS
cmake --build build/x64/clang/release
```

## Package

```bash
# Windows
cpack --config build\x64\msvc-22\CPackConfig.cmake -G NSIS -C Release ^
      -D "BUNDLE_PACK_STAGINGS=opendaq;opcua-modules;mqtt-module;lt-streaming-modules;asam-cmp-modules" ^
      -D "BUNDLE_PACK_COMPONENTS=Runtime;Development" ^
      -D CPACK_OPENDAQ_META_PACKAGE_NAME=opendaq-bundle

# Linux
cpack --config build/x64/gcc/release/CPackConfig.cmake -G DEB \
      -D "BUNDLE_PACK_STAGINGS=opendaq;opcua-modules;mqtt-module;lt-streaming-modules;asam-cmp-modules" \
      -D "BUNDLE_PACK_COMPONENTS=Runtime;Development" \
      -D CPACK_OPENDAQ_META_PACKAGE_NAME=opendaq-bundle

# macOS
cpack --config build/x64/clang/release/CPackConfig.cmake -G productbuild \
      -D "BUNDLE_PACK_STAGINGS=opendaq;opcua-modules;mqtt-module;lt-streaming-modules;asam-cmp-modules" \
      -D "BUNDLE_PACK_COMPONENTS=Runtime;Development" \
      -D CPACK_OPENDAQ_META_PACKAGE_NAME=opendaq-bundle
```

The installer lands in `build/<preset>/packages`; it installs into `/opt/opendaq` (DEB, productbuild) or the folder
chosen (NSIS).

## bundle.json

The bundle's version and the revision of each repository, read at every configure:

```json
{
    "version": "2026.11.0",
    "layers": {
        "openDAQ": "main",
        "OpcUaModules": "main",
        "MQTTStreamingModule": "main",
        "LTStreamingModulesModern": "main",
        "ASAM-CMP-Modules": "main"
    }
}
```

- `version`: the version of the packages and installers, `YYYY.MM.N`; `-DBUNDLE_VERSION` replaces it.
- `layers`: one revision per repository, a commit, tag or branch; `-DBUNDLE_REVISION_<REPOSITORY>` replaces one.

## CMake Options

| Option | Default | Description |
|---|---|---|
| `BUNDLE_ENABLE_TESTS` | `OFF` | Build the tests of the layers |
| `BUNDLE_STAGINGS` | all | The parts of the bundle, separated by semicolons: `opendaq;opcua-modules;mqtt-module;lt-streaming-modules;asam-cmp-modules`; leave a module out to build without it, `opendaq` is required |
| `BUNDLE_REVISION_<REPOSITORY>` | `bundle.json`'s | A repository's revision (a commit, tag or branch), e.g. `BUNDLE_REVISION_OPCUAMODULES=v4.0.1` |
| `BUNDLE_VERSION` | `bundle.json`'s | The version of the packages and installers |
| `BUNDLE_TRIPLET` | this machine's | The triplet the packages are named by, `<arch>-<platform>-<compiler>-<version>-<build_type>`:<ul><li>`x86_64-linux-gcc-11-release`</li><li>`armv8-linux-gcc-11-release`</li><li>`x86_64-windows-msvc-143-release`</li><li>`armv8-macos-apple-clang-21-release`</li><li>`x86_64-macos-apple-clang-21-release`</li></ul> |

## CPack Options

What goes into a package, passed to cpack with `-D`:

| Option | Description |
|---|---|
| `BUNDLE_PACK_STAGINGS` | The parts packed, by the names `BUNDLE_STAGINGS` takes; a part the build left out is left out |
| `BUNDLE_PACK_COMPONENTS` | `Runtime` (libraries, modules, executables), `Development` (headers, CMake configs) or both |
| `CPACK_OPENDAQ_META_PACKAGE_NAME` | The package's name, e.g. `opendaq-bundle` |
