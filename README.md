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

A package is tagged `pkg-<sha256>`, the sha256 of the lines `key=value` below, sorted and joined by newlines (no
newline after the last): the commit it is built of, the triplet of its platform and, for a module, the core's
commit it is built against. On macOS use `shasum -a 256` in place of `sha256sum`:

```bash
# the sha256 of its arguments, key=value, sorted and joined by newlines
pkg_hash() { printf '%s' "$(printf '%s\n' "$@" | LC_ALL=C sort)" | sha256sum | cut -d' ' -f1; }
# the core: its commit, the triplet
core_hash() { pkg_hash org.opencontainers.image.revision=$1 com.opendaq.package.triplet=$2; }
# a module: its commit, the core's commit it is built against, the triplet
module_hash() { pkg_hash org.opencontainers.image.revision=$1 com.opendaq.dependencies.opendaq.revision=$2 \
                         com.opendaq.package.triplet=$3; }

# the revisions, full commits: the core, and the modules built against it
rev_core=<openDAQ commit>
rev_opcua=<OpcUaModules commit>
rev_mqtt=<MQTTStreamingModule commit>
rev_lt=<LTStreamingModulesModern commit>
rev_asam=<ASAM-CMP-Modules commit>

# the triplets:
#   x86_64-linux-gcc-11-release
#   armv8-linux-gcc-11-release
#   x86_64-windows-msvc-143-release
#   armv8-macos-apple-clang-21-release
#   x86_64-macos-apple-clang-21-release
triplet=x86_64-linux-gcc-11-release

tag_opendaq=pkg-$(core_hash $rev_core $triplet)
tag_opcua_modules=pkg-$(module_hash $rev_opcua $rev_core $triplet)
tag_mqtt_module=pkg-$(module_hash $rev_mqtt $rev_core $triplet)
tag_lt_streaming_modules=pkg-$(module_hash $rev_lt $rev_core $triplet)
tag_asam_cmp_modules=pkg-$(module_hash $rev_asam $rev_core $triplet)
```

Pull each staging and unpack it into a directory of its own; the core's tarball holds its prefix, `opt/opendaq`,
except on Windows:

```bash
for staging in opendaq:$tag_opendaq opcua-modules:$tag_opcua_modules mqtt-module:$tag_mqtt_module \
               lt-streaming-modules:$tag_lt_streaming_modules asam-cmp-modules:$tag_asam_cmp_modules; do
    name=${staging%%:*}
    oras pull ghcr.io/opendaq/staging/$staging -o downloads/$name
    mkdir -p stagings/$name && tar -xzf downloads/$name/*.tar.gz -C stagings/$name
done
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
