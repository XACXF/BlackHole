#!/bin/bash
set -e

DRIVER_NAME="${DRIVER_NAME:-XACliv}"
BUNDLE_ID="${BUNDLE_ID:-audio.xac.XACliv}"
CHANNELS="${CHANNELS:-2}"
PKG_NAME="${PKG_NAME:-XACliv}"
TARGET_NAME="${DRIVER_NAME}${CHANNELS}ch.driver"

echo "============================================"
echo "Building ${DRIVER_NAME} (${CHANNELS}ch)"
echo "============================================"

rm -rf build
rm -rf "dist/${PKG_NAME}"
rm -rf "dist/${PKG_NAME}.dmg"

# Modify BlackHole.c defaults
sed -i '' "s/\"BlackHole\"/\"${DRIVER_NAME}\"/g" BlackHole/BlackHole.c
sed -i '' "s/\"com.apple.audio.BlackHoleSoundCard\"/\"${BUNDLE_ID}\"/g" BlackHole/BlackHole.c

# Build the driver
xcodebuild -project BlackHole.xcodeproj \
  -configuration Release \
  -target BlackHole \
  PRODUCT_BUNDLE_IDENTIFIER="${BUNDLE_ID}" \
  PRODUCT_NAME="${DRIVER_NAME}${CHANNELS}ch" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  GCC_PREPROCESSOR_DEFINITIONS="kNumber_Of_Channels=${CHANNELS} kLatency_Frame_Size=128 kDevice_HasInput=1 kDevice_HasOutput=1 kDevice2_HasInput=0 kDevice2_HasOutput=0" \
  OBJROOT=build/Objects \
  SYMROOT=build/Symbols \
  DSTROOT=build/Archive 2>&1

DRIVER_DIR="build/Symbols/Release/${TARGET_NAME}"
if [ ! -d "$DRIVER_DIR" ]; then
    echo "ERROR: Driver not found at $DRIVER_DIR"
    exit 1
fi

echo "Driver built: $DRIVER_DIR"

# Stage DMG contents
INSTALLER_DIR="dist/${PKG_NAME}-Installer"
rm -rf "$INSTALLER_DIR"
mkdir -p "$INSTALLER_DIR"

# Copy driver bundle
cp -R "$DRIVER_DIR" "$INSTALLER_DIR/"

# Write install.sh
cat > "$INSTALLER_DIR/install.sh" << 'INSTALL_EOF'
#!/bin/bash
# BlackHole-derived audio driver installer
# Usage: sudo ./install.sh

set -e

DRIVER_NAME="$1"
if [ -z "$DRIVER_NAME" ]; then
    # Auto-detect the .driver bundle in current directory
    DRIVER_NAME=$(ls -d *.driver 2>/dev/null | head -1)
    if [ -z "$DRIVER_NAME" ]; then
        echo "ERROR: No .driver bundle found in current directory"
        echo "Usage: sudo ./install.sh <DriverName.driver>"
        exit 1
    fi
fi

if [ ! -d "$DRIVER_NAME" ]; then
    echo "ERROR: $DRIVER_NAME not found"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This installer requires root privileges."
    echo "Please run: sudo ./install.sh"
    exit 1
fi

DEST="/Library/Audio/Plug-Ins/HAL"
echo "Installing $DRIVER_NAME to $DEST ..."

if [ -d "$DEST/$DRIVER_NAME" ]; then
    echo "  - Removing existing $DRIVER_NAME ..."
    rm -rf "$DEST/$DRIVER_NAME"
fi

cp -R "$DRIVER_NAME" "$DEST/"
echo "  - Copied driver bundle"

# Set proper ownership and permissions
chown -R root:wheel "$DEST/$DRIVER_NAME"
chmod -R 755 "$DEST/$DRIVER_NAME"

# Restart coreaudiod to load the new driver
echo "  - Restarting coreaudiod ..."
killall -9 coreaudiod 2>/dev/null || true
sleep 2

echo ""
echo "============================================"
echo "Installation complete!"
echo "Driver: $DRIVER_NAME"
echo "Location: $DEST/$DRIVER_NAME"
echo ""
echo "Open 'Audio MIDI Setup' to verify the new device."
echo "============================================"
INSTALL_EOF
chmod +x "$INSTALLER_DIR/install.sh"

# Write uninstall.sh
cat > "$INSTALLER_DIR/uninstall.sh" << 'UNINSTALL_EOF'
#!/bin/bash
# Uninstaller for BlackHole-derived audio driver
# Usage: sudo ./uninstall.sh

set -e

DRIVER_NAME="$1"
if [ -z "$DRIVER_NAME" ]; then
    DRIVER_NAME=$(ls -d *.driver 2>/dev/null | head -1)
    if [ -z "$DRIVER_NAME" ]; then
        echo "ERROR: No .driver bundle found"
        exit 1
    fi
fi

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run: sudo ./uninstall.sh"
    exit 1
fi

DEST="/Library/Audio/Plug-Ins/HAL"
if [ -d "$DEST/$DRIVER_NAME" ]; then
    echo "Removing $DEST/$DRIVER_NAME ..."
    rm -rf "$DEST/$DRIVER_NAME"
    killall -9 coreaudiod 2>/dev/null || true
    sleep 1
    echo "Uninstall complete."
else
    echo "$DRIVER_NAME is not installed."
fi
UNINSTALL_EOF
chmod +x "$INSTALLER_DIR/uninstall.sh"

# Write README
cat > "$INSTALLER_DIR/README.txt" << README_EOF
${PKG_NAME} Audio Driver Installer
================================

This is a custom audio driver derived from ExistentialAudio/BlackHole.

INSTALLATION
------------
Method 1 (Recommended - terminal):
  1. Open Terminal
  2. cd to this folder
  3. Run: sudo ./install.sh
  4. Wait for "Installation complete!"

Method 2 (Manual drag-and-drop):
  1. Open Finder
  2. Press Cmd+Shift+G and type: /Library/Audio/Plug-Ins/HAL/
  3. Drag ${TARGET_NAME} into that folder (provide admin password)
  4. Open Terminal and run: sudo killall -9 coreaudiod

VERIFICATION
------------
- Open "Audio MIDI Setup" (in /Applications/Utilities/)
- Look for "${DRIVER_NAME}" in the device list on the left
- If you don't see it, restart your Mac

UNINSTALLATION
--------------
  sudo ./uninstall.sh

Or manually:
  1. Delete ${TARGET_NAME} from /Library/Audio/Plug-Ins/HAL/
  2. Run: sudo killall -9 coreaudiod

Built automatically by GitHub Actions.
README_EOF

# Create DMG
echo ""
echo "Creating DMG ..."
DMG_PATH="dist/${PKG_NAME}.dmg"
DMG_TEMP="dist/${PKG_NAME}-temp.dmg"

# Create a read-only DMG
hdiutil create -volname "${PKG_NAME} Installer" \
    -srcfolder "$INSTALLER_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

if [ -f "$DMG_PATH" ]; then
    echo ""
    echo "============================================"
    echo "${PKG_NAME}.dmg created!"
    ls -lh "$DMG_PATH"
    echo "============================================"
else
    echo "ERROR: DMG was not created"
    exit 1
fi