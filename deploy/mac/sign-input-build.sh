#!/bin/bash
# SPDX-FileCopyrightText: (C) 2026 Deskflow Developers
# SPDX-License-Identifier: MIT
set -euo pipefail

app=$1
identity=$2
certificate=$3

# macdeployqt has already signed the nested libraries. Re-sign the two TCC
# clients with explicit, content-independent identities, then seal the bundle.
sign() {
  local target=$1 identifier=$2
  /usr/bin/codesign --force --options runtime --timestamp=none \
    --sign "$identity" --identifier "$identifier" \
    --requirements "=designated => identifier \"$identifier\" and anchor \"$certificate\"" \
    "$target"
}

sign "$app/Contents/MacOS/deskflow-core" deskflow-core
sign "$app" org.deskflow.deskflow
/usr/bin/codesign --verify --deep --strict --verbose=2 "$app"
