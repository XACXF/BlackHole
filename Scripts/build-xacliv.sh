#!/bin/bash
set -e

DRIVER_NAME="${DRIVER_NAME:-XAClive}"
BUNDLE_ID="${BUNDLE_ID:-audio.xac.XAClive}"
CHANNELS="${CHANNELS:-2}"
PKG_NAME="${PKG_NAME:-XAClive}"
TARGET_NAME="${DRIVER_NAME}2ch.driver"

echo "============================================"
echo "Building ${DRIVER_NAME} (${CHANNELS}ch)"
echo "============================================"

rm -rf build
rm -rf "dist/${PKG_NAME}"
rm -rf "dist/${PKG_NAME}.pkg"

# Modify BlackHole.c defaults
sed -i '' "s/\"BlackHole\"/\"${DRIVER_NAME}\"/g" BlackHole/BlackHole.c
sed -i '' "s/audio\\.existential\\.BlackHole2ch/${BUNDLE_ID}2ch/g" BlackHole/BlackHole.c

# Build the driver
xcodebuild -project BlackHole.xcodeproj \
  -configuration Release \
  -target BlackHole \
  PRODUCT_BUNDLE_IDENTIFIER="${BUNDLE_ID}" \
  PRODUCT_NAME='XAC live 2ch' \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  GCC_PREPROCESSOR_DEFINITIONS="kNumber_Of_Channels=${CHANNELS} kLatency_Frame_Size=128 kDevice_HasInput=1 kDevice_HasOutput=1 kDevice2_HasInput=0 kDevice2_HasOutput=0 kSampleRates=44100,48000,88200,96000,176400,192000" \
  OBJROOT=build/Objects \
  SYMROOT=build/Symbols \
  DSTROOT=build/Archive 2>&1

DRIVER_DIR="build/Symbols/Release/XAC live 2ch.driver"
if [ ! -d "$DRIVER_DIR" ]; then
    echo "ERROR: Driver not found at $DRIVER_DIR"
    exit 1
fi
echo "Driver built: $DRIVER_DIR"

PKG_PATH="dist/${PKG_NAME}.pkg"
rm -f "$PKG_PATH"
mkdir -p "$(dirname "$PKG_PATH")"

SCRIPTS_DIR="build/pkg_scripts_${PKG_NAME}"
rm -rf "$SCRIPTS_DIR"
mkdir -p "$SCRIPTS_DIR"
cat > "$SCRIPTS_DIR/postinstall" << 'POST_EOF'
#!/bin/bash
killall -9 coreaudiod 2>/dev/null || true
exit 0
POST_EOF
chmod +x "$SCRIPTS_DIR/postinstall"

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
