#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="AetherWall"
BUNDLE_DIR="${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Building ${APP_NAME} (Release)..."
swift build -c release

BIN_PATH=$(swift build -c release --show-bin-path)
EXECUTABLE="${BIN_PATH}/${APP_NAME}"

rm -rf "${BUNDLE_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${EXECUTABLE}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

if [ -f "Sources/AetherWall/Resources/curated_4k_catalog.json" ]; then
    cp "Sources/AetherWall/Resources/curated_4k_catalog.json" "${RESOURCES_DIR}/curated_4k_catalog.json"
fi

cat > "${CONTENTS_DIR}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.opensource.aetherwall</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>AetherWall needs administrator permission to install custom 4K videos into the macOS Lock Screen &amp; Aerial wallpaper engine.</string>
</dict>
</plist>
EOF

codesign --force --deep --sign - "${BUNDLE_DIR}" 2>/dev/null || true

echo "Successfully packaged ${PWD}/${BUNDLE_DIR}"
