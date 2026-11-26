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
cmake --build build\x64\msvc-22 --config Release

# Linux
cmake --build build/x64/gcc/release
```

## CMake Options

| Option | Default | Description |
|---|---|---|
| `BUNDLE_ENABLE_TESTS` | `OFF` | Build the tests of the layers |
| `BUNDLE_STAGINGS` | all | The parts of the bundle: `opendaq;opcua-modules;mqtt-module;lt-streaming-modules;asam-cmp-modules`; leave a module out to build without it, `opendaq` is required |
| `BUNDLE_REVISION_<REPOSITORY>` | `bundle.json`'s | A repository's revision (a commit, tag or branch), e.g. `BUNDLE_REVISION_OPCUAMODULES=v4.0.1` |

Pass options at configure time:

```bash
cmake --preset="x64/gcc/release" -DBUNDLE_ENABLE_TESTS=ON
cmake --preset="x64/gcc/release" -DBUNDLE_STAGINGS="opendaq;opcua-modules;mqtt-module;lt-streaming-modules"   # without ASAM CMP
```

## Build from stagings

A staging is what a repository publishes, prebuilt, to `ghcr.io/opendaq/staging/<staging>`: one package per platform.
The bundle can take every part prebuilt instead of building it, and then only packs the installer.

Read the registry with [oras](https://oras.land/docs/installation), logged in with a GitHub token that has
`read:packages`:

```bash
gh auth refresh -h github.com -s read:packages
gh auth token | oras login ghcr.io -u <github user> --password-stdin
```

Pull each staging for your platform and unpack it into a directory of its own; the core's tarball holds its prefix,
`opt/opendaq`, except on Windows. A package's tag, `pkg-<sha256>`, is listed by `oras repo tags`:

```bash
oras pull ghcr.io/opendaq/staging/opendaq:pkg-<sha256> -o downloads/opendaq
mkdir -p stagings/opendaq && tar -xzf downloads/opendaq/*.tar.gz -C stagings/opendaq
# … the same for opcua-modules, mqtt-module, lt-streaming-modules, asam-cmp-modules
```

Configure with `BUNDLE_FROM=STAGINGS` and a `BUNDLE_PREFIX_<STAGING>` for each, then build and pack; nothing is
compiled:

```bash
cmake --preset bundle-native -DBUNDLE_FROM=STAGINGS \
      -DBUNDLE_PREFIX_OPENDAQ=$PWD/stagings/opendaq/opt/opendaq \
      -DBUNDLE_PREFIX_OPCUA-MODULES=$PWD/stagings/opcua-modules \
      -DBUNDLE_PREFIX_MQTT-MODULE=$PWD/stagings/mqtt-module \
      -DBUNDLE_PREFIX_LT-STREAMING-MODULES=$PWD/stagings/lt-streaming-modules \
      -DBUNDLE_PREFIX_ASAM-CMP-MODULES=$PWD/stagings/asam-cmp-modules
cmake --build --preset bundle-native
cpack --preset installer -G <DEB | NSIS | productbuild>
```

The installer lands in `build/bundle-native/packages`.
