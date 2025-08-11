#!/bin/bash

INSTALLER_PATH="/Applications/Install macOS Sequoia.app"
STARTOSINSTALL="${INSTALLER_PATH}/Contents/Resources/startosinstall"
VERSION="15.5"

echo "🔍 Checking for existing macOS ${VERSION} installer..."

if [ -x "$STARTOSINSTALL" ]; then
  echo "✅ Found working installer: $STARTOSINSTALL"
else
  echo "⚠️ Installer is missing or broken. Cleaning up..."
  sudo rm -rf "$INSTALLER_PATH"

  echo "🔽 Re-downloading full macOS ${VERSION} installer..."
  sudo softwareupdate --fetch-full-installer --full-installer-version "$VERSION"

  echo "📦 Verifying installer..."
  if [ -x "$STARTOSINSTALL" ]; then
    echo "✅ Successfully downloaded full macOS ${VERSION} installer with startosinstall."
  else
    echo "❌ Download failed or incomplete. Please try again or use alternate method (e.g. installinstallmacos.py)."
    exit 1
  fi
fi

# 🛠️ Uncomment this block if you want to silently initiate the upgrade after verification
# echo "🚀 Starting macOS ${VERSION} upgrade silently..."
# sudo "$STARTOSINSTALL" --agreetolicense --nointeraction --forcequitapps

echo "🎉 Done. Installer is ready at: $STARTOSINSTALL"
