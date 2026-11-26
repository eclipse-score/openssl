# OpenSSL build configuration

## General

| Option | Reason |
|---|---|
| `no-asm` | Portable C only; avoids assembler/toolchain differences (GCC inline assembly issues, QCC). |
| `no-makedepend` | Dependency generation is a `make` feature; no effect on the Bazel build. |
| `no-sock` | Socket/network BIO not needed for a crypto library; avoids missing socket APIs in the QNX sysroot. |
| `-DUSE_TIMEGM` | QNX does not provide the `timezone` global. In OpenSSL 3.6.1 only used by `test/testutil/helper.c`, so currently without effect on the libraries. |

### Linux only (`configure_options_per_os.linux`)

| Option | Reason |
|---|---|
| `-D_GNU_SOURCE` | The S-CORE toolchains compile with `-std=c11 -D_XOPEN_SOURCE=700`, which hides `syscall`/`madvise` used by `crypto/mem_sec.c`. Must not be set for QNX: OpenSSL then assumes the GNU `strerror_r` (returns `char *`), while QNX's returns `int`. |

The ENGINE API stays enabled for SoftHSM compatibility (deprecated in OpenSSL 3.x, removed in 4.x).

## Build scope reduction: applications and tools

These only change `OPENSSL_NO_APPS/TESTS/DOCS` in `configuration.h`. The generated
`@openssl//:openssl` CLI and `@openssl//:install` targets therefore have no sources and must not
be built.

| Option | Reason |
|---|---|
| `no-apps` | CLI tools not needed for library use. |
| `no-tests` | Test suite not built. |
| `no-docs` | Documentation not generated. |
| `no-ui-console` | Console UI not needed. |

## Build scope reduction: protocols

TLS 1.2 and 1.3 are intentionally retained (feat_req__sec_crypt__tls_support).

| Option | Reason |
|---|---|
| `no-ssl3` | SSLv3 is insecure. |
| `no-tls1` | TLS 1.0 is insecure. |
| `no-tls1_1` | TLS 1.1 is insecure. |
| `no-dtls` | DTLS not in S-CORE requirements. |
| `no-srtp` | SRTP not in S-CORE requirements. |

## Build scope reduction: high-level features

| Option | Reason |
|---|---|
| `no-cms` | Cryptographic Message Syntax not in S-CORE requirements. |
| `no-ct` | Certificate Transparency not in S-CORE requirements. |
| `no-srp` | SRP protocol not in S-CORE requirements. |
| `no-ocsp` | OCSP not in S-CORE requirements. |
| `no-psk` | Pre-shared keys not in S-CORE requirements. |
| `no-nextprotoneg` | NPN superseded by ALPN. |
| `no-comp` | TLS compression is a CRIME attack vector. |

## Build scope reduction: legacy and obsolete algorithms

DES (3DES / `CKM_DES3_CBC`) and MD5 (TLS PRF) are intentionally kept for SoftHSM compatibility.

| Option | Reason |
|---|---|
| `no-md2`, `no-md4`, `no-mdc2` | Obsolete hashes. |
| `no-rc2` | Insecure, vulnerable key schedule. |
| `no-rc4` | Broken stream cipher. |
| `no-rc5` | Patented/legacy. |
| `no-idea`, `no-bf`, `no-cast` | Legacy block ciphers (Blowfish superseded by AES). |
| `no-seed`, `no-camellia`, `no-aria` | Not in S-CORE requirements; AES is primary. |
| `no-rmd160`, `no-whirlpool` | Legacy hashes. |
| `no-legacy` | Legacy provider not used; only the default provider. |

## Build scope reduction: regional and platform specific

| Option | Reason |
|---|---|
| `no-sm2`, `no-sm3`, `no-sm4` | Chinese national standard algorithms, not in S-CORE requirements. |
| `no-gost` | Russian national standard cipher suite, not in S-CORE requirements. |
| `no-afalgeng` | Linux AF_ALG engine requires `linux/version.h`, not available in the QNX sysroot. |
| `no-padlockeng` | VIA Padlock engine is x86-only and irrelevant for the targets. |
| `no-async` | Async dispatch unused. |
