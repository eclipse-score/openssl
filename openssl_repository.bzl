# *******************************************************************************
# Copyright (c) 2026 Contributors to the Eclipse Foundation
#
# See the NOTICE file(s) distributed with this work for additional
# information regarding copyright ownership.
#
# This program and the accompanying materials are made available under the
# terms of the Apache License Version 2.0 which is available at
# https://www.apache.org/licenses/LICENSE-2.0
#
# SPDX-License-Identifier: Apache-2.0
# *******************************************************************************

"""Repository rule combining a pristine OpenSSL release with the generated Bazel overlay."""

def _link_tree(rctx, root):
    pending = [(root, "")]

    # Starlark has no recursion or while loops; the bound only guards against runaway trees.
    for _ in range(100000):
        if not pending:
            return
        src, prefix = pending.pop()
        for entry in src.readdir():
            dst = prefix + entry.basename
            if entry.is_dir:
                pending.append((entry, dst + "/"))
            else:
                rctx.symlink(entry, dst)
    fail("Overlay tree {} is too large".format(root))

def _openssl_repository_impl(rctx):
    if rctx.attr.urls:
        rctx.download_and_extract(
            url = rctx.attr.urls,
            sha256 = rctx.attr.sha256,
            stripPrefix = rctx.attr.strip_prefix,
        )

    # The overlay lives in a .bazelignore'd directory, so it is addressed relative to this module's root.
    overlay = rctx.path(Label("//:MODULE.bazel")).dirname.get_child(rctx.attr.overlay)
    if not overlay.exists:
        fail("Overlay directory {} does not exist; run 'bazel run //third_party/openssl/generator:generate'".format(overlay))
    rctx.watch_tree(overlay)
    _link_tree(rctx, overlay)

openssl_repository = repository_rule(
    implementation = _openssl_repository_impl,
    attrs = {
        "overlay": attr.string(
            mandatory = True,
            doc = "Directory, relative to the score_openssl module root, copied on top of the archive.",
        ),
        "sha256": attr.string(),
        "strip_prefix": attr.string(),
        "urls": attr.string_list(doc = "Optional archive; without it the repository contains only the overlay."),
    },
)
