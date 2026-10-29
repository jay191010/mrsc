#!/usr/bin/env bash
#
# Build an unsigned, sideload-ready MRSC IPA on a Mac.
#
# Requirements: macOS + Xcode 26 and XcodeGen (brew install xcodegen).
#
# The resulting .ipa is unsigned. Re-sign and install it with Sideloadly or
# AltStore (both can use a free Apple ID). For TestFlight/App Store, see
# docs/TESTFLIGHT.md instead.

set -euo pipefail

cd "$(dirname "$0")/.."

# 1. Generate the Xcode project from project.yml
command -v xcodegen >/dev/null || { echo "Install XcodeGen first: brew install xcodegen"; exit 1; }
xcodegen generate

# 2. Build an unsigned archive for a physical device
rm -rf build/MRSC.xcarchive
xcodebuild \
  -project MRSC.xcodeproj \
  -scheme MRSC \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/MRSC.xcarchive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  archive

# 3. Wrap the .app into Payload/ and zip it into an .ipa
APP_PATH="$(find build/MRSC.xcarchive/Products/Applications -maxdepth 1 -name '*.app' | head -n 1)"
[ -n "$APP_PATH" ] || { echo "No .app found in archive."; exit 1; }

VERSION="$(grep -E 'MARKETING_VERSION' project.yml | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')"
IPA="build/MRSC-${VERSION}-unsigned.ipa"

rm -rf build/Payload
mkdir -p build/Payload
cp -R "$APP_PATH" build/Payload/
rm -f "$IPA"
( cd build && zip -qr "$(basename "$IPA")" Payload )
rm -rf build/Payload

echo
echo "Done: $IPA"
echo "Re-sign and install it with Sideloadly or AltStore."
