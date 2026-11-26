# OpenSSL: generated native Bazel build

This directory contains everything needed to build OpenSSL with plain Bazel rules
(`cc_library`). Compared to driving OpenSSL's `Configure` + `make` through rules_foreign_cc it
avoids host tools at build time, keeps actions sandboxed and cacheable per source file, and
works with any injected C toolchain.

## Approach

OpenSSL's `Configure` (Perl) is run **once, offline**, by a generator. It produces a static,
pre-generated configuration: Bazel build files (overlay) plus the files `make` would normally
generate (pregen). The normal build then only needs a C compiler from the injected toolchain.

```text
 config/openssl_config.json        @openssl_generator              generator/patches/
 (Configure options, the  ──┐      (bazel-openssl-cc, pinned  ──┐  0001 generic
  OpenSSL feature set)      │       in MODULE.bazel)            │  0002 QNX targets
                            └──────────────┬────────────────────┘
                                           ▼
                 bazel run //third_party/openssl/generator:generate
                 (runs Configure for every platform, offline)
                                           │
                                           ▼
 gen_overlay/overlay   BUILD.bazel with cc_library :crypto / :ssl, per-platform source lists
 gen_overlay/pregen    generated headers and sources (configuration.h, buildinf.h, ...)
                                           │  committed, never edited by hand
                                           ▼
 @openssl        = pristine OpenSSL release + gen_overlay/overlay   (openssl_repository.bzl)
 @openssl_pregen = gen_overlay/pregen
                                           │
                                           ▼
 @openssl//:crypto, @openssl//:ssl  →  plain Bazel C/C++ rules, one action per source file
```

Properties:
- The feature set (`OPENSSL_NO_*`) is baked into the generated `configuration.h` and source lists,
  so the headers seen by consumers match what was compiled.
- No `make`, `perl`, `pkg-config` or `m4` at build time for platforms with pre-generated files;
  no sandbox escapes, no build paths or timestamps embedded in the libraries.
- Platform selection uses `@platforms//os` + `@platforms//cpu` constraints of the target
  platform; the injected toolchain only has to compile.

| Path | Content |
|---|---|
| `config/` | `openssl_config.json` (the OpenSSL feature set) and its [README](config/README.md). |
| `generator/` | `generate.sh`, its `BUILD.bazel` target and the patches for the upstream generator. |
| `gen_overlay/` | Generator output (`overlay/`, `pregen/`). Listed in `.bazelignore`. |

The OpenSSL version and checksum are defined once in the root `MODULE.bazel`
(`_OPENSSL_VERSION`, `_OPENSSL_SHA256`) and shared by the generator input and `@openssl`.

### Supported OpenSSL versions

The generator (bazel-openssl-cc) supports OpenSSL 3.0 and later; upstream CI covers 3.5 LTS and
4.0, and builds `master` nightly. This repository is validated with **OpenSSL 3.6.1** only.

## Generating

Run inside the devcontainer (needs `python3` >= 3.10 and `perl` 5):

```bash
bazel run //third_party/openssl/generator:generate
```

This fetches `@openssl_release` and `@openssl_generator` (with the patches listed in
`MODULE.bazel`), runs the generator on a private copy of the release with
`config/openssl_config.json`, and replaces `gen_overlay/`. Commit the result.

Regenerate after changing `config/openssl_config.json`, the generator patches, the generator
commit or the OpenSSL version. Then build the libraries and check the resulting feature set:

```bash
bazel build --config=x86_64-linux //:openssl //:openssl_build_info
cat bazel-bin/openssl_build_info.txt   # version + OPENSSL_NO_* list from configuration.h
```

The normal `//:openssl` and `//:openssl_build_info` targets use the generated `@openssl` build
through `:openssl_impl`; building `//:openssl` compiles the library.

## Generator patches

| Patch | Purpose |
|---|---|
| `0001-configurable-options-and-no-asm-overlay.patch` | `--configure_options_file` passes `openssl_config.json` to `Configure` (`configure_options` for all platforms, `configure_options_per_os` keyed by the `@platforms//os` name); user `-D` options become defines; no empty assembly groups for `no-asm`; package metadata without module context. |
| `0002-qnx-targets.patch` | Adds `qnx-x86_64` / `qnx-aarch64` Configure targets (`BASE_unix`, `-D_QNX_SOURCE`) and their pre-generated variants. |

Both patches are applied by the `openssl_generator` `http_archive` in `MODULE.bazel`.

## Platforms and pre-generated variants

The generator produces one pre-generated variant per upstream platform (Linux x86_64/aarch64/
arm/ppc64le/riscv64/s390x, Android, Darwin, iOS, FreeBSD, Windows), the QNX variants from `0002`,
plus `no_asm`. Only the variant matching the target platform's os/cpu constraints is selected.
The variants outside the S-CORE scope are kept only to avoid further changes to the generator;
they are not used and not validated. Only the platforms listed below are in scope and verified.

| Target | Status |
|---|---|
| x86_64 / aarch64 Linux | Verified: `@openssl//:crypto` / `:ssl` build from pre-generated files, feature set matches `openssl_config.json`. |
| x86_64 / aarch64 QNX SDP 8 | Verified: same as Linux (`qnx_x86_64` / `qnx_aarch64` variants). |
| AutoSD, EBcLfSA | In scope; expected to use the Linux variants (`os:linux`), not verified yet. |

Platforms without a pre-generated variant fall back to running OpenSSL's Perl scripts at build
time (`rules_perl`) with the generic `no_asm` configuration (derived from a Linux target). This
fallback is not used for in-scope platforms and is not validated; e.g. QNX failed to compile with
it before `0002` (`Dl_info` needs `_QNX_SOURCE`).

### OpenSSL in the QNX SDP

QNX SDP 8.0.4 (as used by `score_bazel_cpp_toolchains`) ships **OpenSSL 3.0.15** in its sysroot
(`libcrypto.so.3` / `libssl.so.3`, shared only). Its `configuration.h` disables only 25 features,
essentially the upstream defaults (plus `no-async`), so it is a near-full ("fat") build. S-CORE
components use `@score_openssl` instead; nothing in this repository links the SDP OpenSSL.

## Feature flags of the overlay

The overlay also defines ~90 `--@openssl//:no-<feature>` flags (all default `False`). They are
unused and harmless, but must not be set: they only add private `-DOPENSSL_NO_*` compile flags
and would make the libraries diverge from the generated `configuration.h`. Change
`config/openssl_config.json` and regenerate instead.
