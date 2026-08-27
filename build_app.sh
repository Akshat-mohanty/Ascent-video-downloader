#!/bin/bash
set -e

APP_NAME="AetherTube"
BUNDLE_NAME="${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_NAME}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "🔨 Building ${APP_NAME} in Release mode..."
swift build -c release

echo "📦 Packaging ${BUNDLE_NAME}..."
rm -rf "${BUNDLE_NAME}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy binary
cp ".build/release/YouTubeDownloader" "${MACOS_DIR}/YouTubeDownloader"
chmod +x "${MACOS_DIR}/YouTubeDownloader"

# Copy Info.plist
cp "Info.plist" "${CONTENTS_DIR}/Info.plist"

# Generate crisp AppIcon
swift generate_icon.swift

echo "✅ Successfully built ${BUNDLE_NAME}!"
echo "🚀 You can now launch it by running: open '${BUNDLE_NAME}'"
