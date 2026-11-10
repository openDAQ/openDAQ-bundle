# openDAQ-bundle

A CMake super-project that bundles [openDAQ](https://github.com/openDAQ/openDAQ) together with its optional modules:
- [OpcUaModules](https://github.com/openDAQ/OpcUaModules)
- [MQTTStreamingModule](https://github.com/openDAQ/MQTTStreamingModule)
- [LTStreamingModulesModern](https://github.com/openDAQ/LTStreamingModulesModern)
- [ASAM-CMP-Modules](https://github.com/openDAQ/ASAM-CMP-Modules)

Each of these repositories is a **layer** at one revision. What a layer publishes is its **staging**: `opendaq`,
`opcua-modules`, `mqtt-module`, `lt-streaming-modules`, `asam-cmp-modules`. The bundle takes each staging prebuilt,
from a store of stagings, when one fits its revision, its dependencies' revisions and this platform. Otherwise it
builds the layer from its sources in the same tree, fetched with CMake's `FetchContent`. The engine is
`cmake/FetchLayer.cmake`; what the bundle is made of is `cmake/Layers.cmake`.

## Prerequisites

- CMake 3.25 or newer
- Git
- **Windows:** Visual Studio 2017 or 2022 (with C++ workload) — used as compiler toolchain only
- **Linux:** GCC or Clang, Ninja
- **macOS:** Xcode command line tools, Ninja
- For prebuilt stagings: [oras](https://oras.land) and read access to `ghcr.io/opendaq/dev/staging`

On an Intel Mac with Homebrew in `/usr/local`, Homebrew's `boost`, `spdlog`, `fmt` and `rapidjson` headers shadow
the ones the build fetches. Unlink them for a build from sources (`brew unlink boost spdlog fmt rapidjson`, then
`brew link …`).

## Configure

Use one of the available CMake presets:

| Preset | Platform | Compiler | Arch | Config |
|---|---|---|---|---|
| `bundle-native` | this machine | default | this machine | Release, prebuilt stagings from `build/store` |
| `x64/msvc-22` | Windows | MSVC 2022 | x64 | Release |
| `x86/msvc-22` | Windows | MSVC 2022 | x86 | Release |
| `x64/msvc-17` | Windows | MSVC 2017 | x64 | Release |
| `x86/msvc-17` | Windows | MSVC 2017 | x86 | Release |
| `x64/gcc/release` | Linux | GCC | x64 | Release |
| `x64/gcc/debug` | Linux | GCC | x64 | Debug |
| `x64/clang/release` | Linux | Clang | x64 | Release |
| `x64/clang/debug` | Linux | Clang | x64 | Debug |

`bundle-native` pins every layer to a commit whose stagings are published. The others set no store, so they build
every layer from its `main` branch.

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
| `BUNDLE_STAGINGS` | all five | The stagings to make available, dependencies first: `opendaq;opcua-modules;mqtt-module;lt-streaming-modules;asam-cmp-modules` |
| `BUNDLE_REVISION_<LAYER>` | `main` | The revision of a layer (a repository, its name upper-cased): a full sha, a tag or a branch, e.g. `BUNDLE_REVISION_OPCUAMODULES` |
| `FETCHLAYER_BUILD` | `MISSING` | `NEVER`: prebuilt stagings only; `MISSING`: prebuilt where there is one, else from sources; `ALWAYS`: from sources. `FETCHLAYER_BUILD_<LAYER>` for one layer |
| `FETCHLAYER_STORE` | — | The store of prebuilt stagings, `<store>/<staging>/idx-<hash>/<triplet>/`; without one, everything is built from sources |
| `FETCHCONTENT_SOURCE_DIR_<LAYER>` | — | A layer from a local checkout, always built from it |
| `BUNDLE_AXIS_TRIPLET` | this build's | The triplets to make available; others than this build's come prebuilt, as files only |
| `BUNDLE_ENABLE_TESTS` | `OFF` | Build the tests of the layers built from sources |

Pass options at configure time:

```bash
cmake --preset="x64/gcc/release" -DBUNDLE_ENABLE_TESTS=ON
cmake --preset="x64/gcc/release" -DBUNDLE_STAGINGS="opendaq;opcua-modules" -DBUNDLE_REVISION_OPCUAMODULES=v4.0.1
cmake --preset bundle-native -DFETCHLAYER_BUILD_OPCUAMODULES=ALWAYS     # OPC UA from sources, the rest prebuilt
```

## Prebuilt stagings

The stagings are read from ghcr by [oras](https://oras.land/docs/installation), which needs a login even to read:
a GitHub token with `read:packages`, e.g. the GitHub CLI's:

```bash
gh auth refresh -h github.com -s read:packages
gh auth token | oras login ghcr.io -u <github user> --password-stdin
```

`oras login` keeps the token in `~/.docker/config.json`; another file is passed as `-DORAS_REGISTRY_CONFIG=`.

The store is filled from the registry once, for the revisions `bundle-native` pins (see `CMakePresets.json`):

```bash
cmake -DSTORE=build/store -DREGISTRY=ghcr.io/opendaq/dev/staging \
      [-DORAS_REGISTRY_CONFIG=$HOME/.oras/config.json] \
      "-DLAYERS=opendaq=<sha>;opcua-modules=<sha>;mqtt-module=<sha>;lt-streaming-modules=<sha>;asam-cmp-modules=<sha>" \
      -P tools/fill-store.cmake
```

It takes every platform of each staging; a build already in the store is kept. Configuring from a filled store
needs no network, apart from the first fetch of `opendaq-cmake-utils`.

## Package

With prebuilt stagings in a store, `bundle-native` configures without building, and the package presets pack:

```bash
cmake --preset bundle-native
cmake --build --preset bundle-native
cpack --preset core       # the core: runtime, C++ API, C binding
cpack --preset modules    # the modules, without the core
```

The packages land in `build/bundle-native/packages`, named `opendaq-<core|modules>-<version>-<triplet>.tar.gz`.

## Tests

```bash
cmake -P tests/identity.cmake        # the identity hash against its check vector
cmake -P tests/axis.cmake            # axes and variants
cmake -S tests/fetchlayer-axes -B build/fetchlayer-axes      # variants by two axes, the layer's decision
cmake -S tests/fetchlayer-git  -B build/fetchlayer-git       # the git origin (network)
cmake -S tests/fetchlayer -B build/fetchlayer -G Ninja \
      -DFETCHLAYER_STORE=$PWD/build/store -DFETCHLAYER_TRIPLET=<triplet>   # on the store, with a smoke test
```
