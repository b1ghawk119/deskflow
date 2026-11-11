#!/bin/bash
# SPDX-FileCopyrightText: (C) 2026 Deskflow Developers
# SPDX-License-Identifier: MIT
set -euo pipefail

app=$1
certificate=$2
identity=$3
report=$4

test "$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app/Contents/Info.plist")" = org.deskflow.deskflow
/usr/bin/codesign --verify --deep --strict --verbose=2 "$app"

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
: > "$report"
for identifier in org.deskflow.deskflow deskflow-core; do
  target="$app"
  binary="$app/Contents/MacOS/Deskflow"
  if [[ "$identifier" == deskflow-core ]]; then
    target="$app/Contents/MacOS/deskflow-core"
    binary="$target"
  fi
  test "$(lipo -archs "$binary")" = arm64
  expected="identifier \"$identifier\" and anchor \"$certificate\""
  codesign --verify --strict -R="$expected" "$target"
  actual=$(codesign -d -r- "$target" 2>&1 | sed -n 's/^designated => //p')
  test -n "$actual"
  if [[ "$actual" == *cdhash* ]]; then
    echo 'Content-dependent designated requirement is not allowed' >&2
    exit 1
  fi
  codesign -d --entitlements :- "$target" > "$scratch/entitlements.plist" 2>/dev/null
  if grep -Eq 'get-task-allow|disable-library-validation|allow-jit' "$scratch/entitlements.plist"; then
    echo 'Development entitlements found in release' >&2
    exit 1
  fi

  # A different binary signed by this identity must satisfy the shipped DR.
  # This tests upgrade identity, not just a signature on a single build.
  printf 'int main(void) { return 42; }\n' > "$scratch/changed.c"
  clang "$scratch/changed.c" -o "$scratch/changed"
  codesign --force --sign "$identity" --identifier "$identifier" --timestamp=none \
    --requirements "designated => $expected" "$scratch/changed"
  codesign --verify --strict -R="$actual" "$scratch/changed"

  # A matching identifier alone must not impersonate the signed application.
  cp "$scratch/changed" "$scratch/unsigned"
  codesign --force --sign - --identifier "$identifier" "$scratch/unsigned"
  if codesign --verify -R="$actual" "$scratch/unsigned" 2>/dev/null; then
    echo 'Ad-hoc impostor unexpectedly satisfies the designated requirement' >&2
    exit 1
  fi
  printf '%s: arm64; certificate-pinned identity; changed binary accepted; ad-hoc impostor rejected\nDR: %s\n' \
    "$identifier" "$actual" | tee -a "$report"
done
