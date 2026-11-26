#!/usr/bin/env bash
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

# Regenerates third_party/openssl/gen_overlay/{overlay,pregen}. Run via:
#   bazel run //third_party/openssl/generator:generate
# Arguments (set by the BUILD target): runfiles paths of a file in the generator
# repository, of VERSION.dat in the OpenSSL release and of the configuration.
set -euo pipefail

if [[ -z "${BUILD_WORKSPACE_DIRECTORY:-}" ]]; then
    echo "Run this script with 'bazel run //third_party/openssl/generator:generate'" >&2
    exit 1
fi

runfiles="${RUNFILES_DIR:-$0.runfiles}"
generator_dir="$(dirname "$(readlink -f "${runfiles}/$1")")"
openssl_dir="$(dirname "$(readlink -f "${runfiles}/$2")")"
config="$(readlink -f "${runfiles}/$3")"
out_dir="${BUILD_WORKSPACE_DIRECTORY}/third_party/openssl/gen_overlay"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

# Configure writes into the source tree, so work on a private copy of the release.
cp -rL "${openssl_dir}" "${work}/openssl"
chmod -R u+w "${work}/openssl"

# The generator treats BUILD_WORKSPACE_DIRECTORY as its own repository root.
env -u BUILD_WORKSPACE_DIRECTORY PYTHONDONTWRITEBYTECODE=1 \
    python3 "${generator_dir}/generator/generate_constants.py" \
    --openssl_source_dir "${work}/openssl" \
    --output_dir "${work}/out/overlay" \
    --pregen_dir "${work}/out/pregen" \
    --configure_options_file "${config}" \
    --buildifier "$(command -v buildifier || true)"

rm -rf "${out_dir}"
mkdir -p "${out_dir}"
cp -r "${work}/out/overlay" "${work}/out/pregen" "${out_dir}/"
echo "Generated overlay and pregen into ${out_dir}"
