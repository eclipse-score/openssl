# Generated code. DO NOT EDIT.

ASM_CRYPTO_EXTRA_SRCS = [
    "ms/uplink.c",
]

ASM_SSL_EXTRA_SRCS = []

ASM_APP_EXTRA_SRCS = []

PERLASM = {
    "crypto/uplink-x86_64.s": {
        "args": [],
        "script": "ms/uplink-x86_64.pl",
    },
}

LIBCRYPTO_DEFINES = [
    "-DOPENSSL_USE_APPLINK",
]

LIBSSL_DEFINES = []

OPENSSL_APP_DEFINES = [
    "-DNDEBUG",
]

OPENSSL_DEFINES = [
    "-DNDEBUG",
    "-DOPENSSL_BUILDING_OPENSSL",
    "-DOPENSSL_NO_KTLS",
    "-DOPENSSL_PIC",
    "-DOPENSSL_SYS_WIN32",
    "-DUNICODE",
    "-DUSE_TIMEGM",
    "-DWIN32_LEAN_AND_MEAN",
    "-D_CRT_SECURE_NO_DEPRECATE",
    "-D_UNICODE",
    "-D_WINSOCK_DEPRECATED_NO_WARNINGS",
]
