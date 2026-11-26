# openDAQ-bundle

A CMake super-project that bundles [openDAQ](https://github.com/openDAQ/openDAQ) together with its optional modules:
- [OpcUaModules](https://github.com/openDAQ/OpcUaModules)
- [MQTTStreamingModule](https://github.com/openDAQ/MQTTStreamingModule)
- [LTStreamingModulesModern](https://github.com/openDAQ/LTStreamingModulesModern)
- [ASAM-CMP-Modules](https://github.com/openDAQ/ASAM-CMP-Modules)

Each of these repositories is a **layer** at one revision, the one `bundle.json` names. What a layer publishes is
its **staging**: `opendaq`, `opcua-modules`, `mqtt-module`, `lt-streaming-modules`, `asam-cmp-modules`. The bundle
builds every layer from its sources in one tree, fetched with CMake's `FetchContent`, or takes every staging
prebuilt from a directory given (`BUNDLE_FROM=STAGINGS`, `BUNDLE_PREFIX_<STAGING>`), and packs installers. In CI the
stagings come from the registry or are staged in the run, and the bundle only packs them (see [CI](#ci)). What
the bundle is made of is `cmake/Layers.cmake`; built from sources, `cmake/Sources.cmake`; from prebuilt
stagings, `cmake/Stagings.cmake`; packed, `cmake/Packing.cmake`.

## Prerequisites

- CMake 3.25 or newer
- Git
- **Windows:** Visual Studio 2017 or 2022 (with C++ workload) — used as compiler toolchain only
- **Linux:** GCC or Clang, Ninja
- **macOS:** Xcode command line tools, Ninja
- For prebuilt stagings: [oras](https://oras.land) and read access to `ghcr.io/opendaq/staging`

On an Intel Mac with Homebrew in `/usr/local`, Homebrew's `boost`, `spdlog`, `fmt` and `rapidjson` headers shadow
the ones the build fetches. Unlink them for a build from sources (`brew unlink boost spdlog fmt rapidjson`, then
`brew link …`).

## Configure

Use one of the available CMake presets:

| Preset | Platform | Compiler | Arch | Config |
|---|---|---|---|---|
| `bundle-native` | this machine | default | this machine | Release, the layers at `bundle.json`'s revisions |
| `x64/msvc-22` | Windows | MSVC 2022 | x64 | Release |
| `x86/msvc-22` | Windows | MSVC 2022 | x86 | Release |
| `x64/msvc-17` | Windows | MSVC 2017 | x64 | Release |
| `x86/msvc-17` | Windows | MSVC 2017 | x86 | Release |
| `x64/gcc/release` | Linux | GCC | x64 | Release |
| `x64/gcc/debug` | Linux | GCC | x64 | Debug |
| `x64/clang/release` | Linux | Clang | x64 | Release |
| `x64/clang/debug` | Linux | Clang | x64 | Debug |

Every preset builds the layers at the revisions `bundle.json` names, from their sources unless a staging is given.
On `main` these are the layers' `main` branches, each taken at its head when the build is configured; a release
branch names the layers' release tags.

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
| `BUNDLE_STAGINGS` | all five | The stagings the bundle has: `opendaq;opcua-modules;mqtt-module;lt-streaming-modules;asam-cmp-modules`. Leave a module out to build and pack without it; `opendaq` is required |
| `BUNDLE_REVISION_<LAYER>` | `bundle.json`'s | The revision of a layer (a repository, its name upper-cased): a full sha, a tag or a branch, e.g. `BUNDLE_REVISION_OPCUAMODULES` |
| `BUNDLE_FROM` | `SOURCES` | `SOURCES`: every layer from its sources; `STAGINGS`: every staging prebuilt, nothing compiled |
| `BUNDLE_PREFIX_<STAGING>` | — | With `BUNDLE_FROM=STAGINGS`, a prebuilt staging, unpacked (its name upper-cased, e.g. `BUNDLE_PREFIX_OPENDAQ`); one for every staging |
| `FETCHCONTENT_SOURCE_DIR_<LAYER>` | — | A layer from a local checkout |
| `BUNDLE_TRIPLET` | the utils' | The triplet the packages are named by |
| `BUNDLE_VERSION` | `bundle.json`'s | The version of the packages |
| `BUNDLE_ENABLE_TESTS` | `OFF` | Build the tests of the layers built from sources |

Pass options at configure time:

```bash
cmake --preset="x64/gcc/release" -DBUNDLE_ENABLE_TESTS=ON
cmake --preset="x64/gcc/release" -DBUNDLE_STAGINGS="opendaq;opcua-modules" -DBUNDLE_REVISION_OPCUAMODULES=v4.0.1
cmake --preset bundle-native -DBUNDLE_STAGINGS="opendaq;opcua-modules;mqtt-module;lt-streaming-modules"   # without ASAM CMP
```

## Prebuilt stagings

The stagings are read from ghcr by [oras](https://oras.land/docs/installation), which needs a login even to read:
a GitHub token with `read:packages`, e.g. the GitHub CLI's:

```bash
gh auth refresh -h github.com -s read:packages
gh auth token | oras login ghcr.io -u <github user> --password-stdin
```

`oras login` keeps the token in `~/.docker/config.json`; another file is passed as `-DORAS_REGISTRY_CONFIG=`.

A staging is one package per platform; its tag `pkg-<sha256>` is computed from the commits and the triplet
(openDAQ/openDAQ-CI#21 shows how). Pulled and unpacked, each into a directory of its own, every staging is given as
`BUNDLE_PREFIX_<STAGING>`; the core's tarball holds its prefix, `opt/opendaq`, except on Windows:

```bash
oras pull ghcr.io/opendaq/staging/opendaq:pkg-<sha256> -o downloads/opendaq
mkdir -p stagings/opendaq && tar -xzf downloads/opendaq/*.tar.gz -C stagings/opendaq
# … the same for opcua-modules, mqtt-module, lt-streaming-modules, asam-cmp-modules
cmake --preset bundle-native -DBUNDLE_FROM=STAGINGS \
      -DBUNDLE_PREFIX_OPENDAQ=$PWD/stagings/opendaq/opt/opendaq \
      -DBUNDLE_PREFIX_OPCUA-MODULES=$PWD/stagings/opcua-modules \
      -DBUNDLE_PREFIX_MQTT-MODULE=$PWD/stagings/mqtt-module \
      -DBUNDLE_PREFIX_LT-STREAMING-MODULES=$PWD/stagings/lt-streaming-modules \
      -DBUNDLE_PREFIX_ASAM-CMP-MODULES=$PWD/stagings/asam-cmp-modules
```

Then build and pack as below; nothing is compiled.

## Package

```bash
cmake --preset bundle-native
cmake --build --preset bundle-native
cpack --preset installer -G <DEB | NSIS | productbuild>   # the core with the modules
cpack --preset core                                        # the core: runtime, C++ API, C binding
cpack --preset modules                                     # the modules, without the core
```

The packages land in `build/bundle-native/packages`, named `opendaq-<bundle|core|modules>-<version>-<triplet>`.

## CI

One workflow, [`bundle.yml`](.github/workflows/bundle.yml), builds the installers (DEB, NSIS, productbuild) for five
platforms from the stagings, nothing compiled but a staging the registry lacks:

1. **Resolve revisions**: a commit per layer: `bundle.json`'s, or an input in its place; on schedule each layer's
   `main`. A module's staging is the one built against the bundle's core.
2. **Pull stagings**: those the registry has, from `ghcr.io/opendaq/staging/<staging>`.
3. **Stage &lt;layer&gt;**: those it lacks, built in the run by the layer's own `stage.yml`, not published.
4. **Configure** and **Build**: the configure preset `bundle-prefixes`, the package preset `installer`.
5. **Push**: the installers to `ghcr.io/opendaq/bundle/native`, tagged by the commits they are built of
   (`idx-<sha256>` for the bundle, `pkg-<sha256>` for each platform).

It runs:

| Trigger | Revisions | Published |
|---|---|---|
| Schedule, Mondays 06:00 UTC, after the layers' stagings | every layer's `main` | yes |
| By hand (Actions → Bundle → Run workflow) | `bundle.json`'s, each replaced by an input given: a commit, branch or tag; `exclude-stagings` leaves modules out | unless `skip-staging-push` |
| Called by another repository (`uses: openDAQ/openDAQ-bundle/.github/workflows/bundle.yml@main`) | as by hand | never: the installers stay artifacts of the run, `package-<job>` |

[`cleanup.yml`](.github/workflows/cleanup.yml) prunes the published bundles after 30 days.

A published installer is pulled as a staging is (see [Prebuilt stagings](#prebuilt-stagings) for the login):

```bash
oras repo tags ghcr.io/opendaq/bundle/native
oras pull ghcr.io/opendaq/bundle/native:pkg-<sha256> -o downloads/bundle
```
