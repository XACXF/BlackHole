#!/bin/bash
set -e

DRIVER_NAME="${DRIVER_NAME:-XACmusic}"
BUNDLE_ID="${BUNDLE_ID:-audio.xac.XACmusic}"
CHANNELS="${CHANNELS:-2}"
PKG_NAME="${PKG_NAME:-XACmusic}"
TARGET_NAME="${DRIVER_NAME}${CHANNELS}ch.driver"

echo "============================================"
echo "Building ${DRIVER_NAME} (${CHANNELS}ch)"
echo "============================================"

rm -rf build
rm -rf "Scripts/${PKG_NAME}-component.pkg"
rm -rf "Scripts/${PKG_NAME}.pkg"
rm -rf "Scripts/${PKG_NAME}"

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

# Stage the package root
rm -rf "Scripts/${PKG_NAME}"
mkdir -p "Scripts/${PKG_NAME}/Library/Audio/Plug-Ins/HAL"
cp -R "$DRIVER_DIR" "Scripts/${PKG_NAME}/Library/Audio/Plug-Ins/HAL/"

mkdir -p "Scripts/${PKG_NAME}/Scripts"
cat > "Scripts/${PKG_NAME}/Scripts/postinstall" << 'POSTINSTALL'
#!/bin/bash
killall -9 coreaudiod 2>/dev/null || true
POSTINSTALL
chmod +x "Scripts/${PKG_NAME}/Scripts/postinstall"

# Step 1: Build a component package with pkgbuild
pkgbuild \
  --root "Scripts/${PKG_NAME}" \
  --identifier audio.xac.${PKG_NAME} \
  --version 1.0.0 \
  --install-location "/" \
  --scripts "Scripts/${PKG_NAME}/Scripts" \
  "Scripts/${PKG_NAME}-component.pkg"

# Step 2: Wrap it in a distribution package with productbuild
# This produces a .pkg that macOS Installer.app can open and display
productbuild \
  --package "Scripts/${PKG_NAME}-component.pkg" \
  "Scripts/${PKG_NAME}.pkg"

echo ""
echo "============================================"
echo "${PKG_NAME}.pkg created!"
ls -lh "Scripts/${PKG_NAME}.pkg"
echo "============================================"