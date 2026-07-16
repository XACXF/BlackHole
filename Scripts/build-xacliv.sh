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
rm -rf "dist/${PKG_NAME}.pkg"

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

echo "Driver built: $DRIVER_DIR"

# Package as a flat component .pkg (compatible with macOS 12 through macOS 26)
PKG_PATH="dist/${PKG_NAME}.pkg"
rm -f "$PKG_PATH"
mkdir -p "$(dirname "$PKG_PATH")"

# Post-install script: reload coreaudiod so the new device appears
SCRIPTS_DIR="build/pkg_scripts_${PKG_NAME}"
rm -rf "$SCRIPTS_DIR"
mkdir -p "$SCRIPTS_DIR"
cat > "$SCRIPTS_DIR/postinstall" << 'POST_EOF'
#!/bin/bash
killall -9 coreaudiod 2>/dev/null || true
exit 0
POST_EOF
chmod +x "$SCRIPTS_DIR/postinstall"

echo ""
echo "Creating .pkg (flat, macOS 12+ compatible) ..."
pkgbuild --identifier "${BUNDLE_ID}" \
  --version "1.0.0" \
  --install-location "/Library/Audio/Plug-Ins/HAL" \
  --component "$DRIVER_DIR" \
  --scripts "$SCRIPTS_DIR" \
  "$PKG_PATH"

if [ -f "$PKG_PATH" ]; then
    echo ""
    echo "============================================"
    echo "${PKG_NAME}.pkg created!"
    ls -lh "$PKG_PATH"
    echo "============================================"
else
    echo "ERROR: .pkg was not created"
    exit 1
fi
