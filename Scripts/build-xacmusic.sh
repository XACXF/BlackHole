#!/bin/bash
set -e

DRIVER_NAME="${DRIVER_NAME:-XACmusic}"
BUNDLE_ID="${BUNDLE_ID:-audio.xac.XACmusic}"
DEVICE_NAME="${DEVICE_NAME:-XACmusic}"
CHANNELS="${CHANNELS:-2}"
PKG_NAME="${PKG_NAME:-XACmusic}"

echo "============================================"
echo "Building ${DRIVER_NAME} (${CHANNELS}ch)"
echo "============================================"

rm -rf build
rm -rf "Scripts/${PKG_NAME}.pkg"
rm -rf "Scripts/${PKG_NAME}"

# Modify BlackHole.c defaults directly
sed -i '' "s/\"BlackHole\"/\"${DRIVER_NAME}\"/g" BlackHole/BlackHole.c
sed -i '' "s/\"com.apple.audio.BlackHoleSoundCard\"/\"${BUNDLE_ID}\"/g" BlackHole/BlackHole.c

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

# Find driver in build/Symbols/Release/ (where xcodebuild puts the final product)
DRIVER_PATH=$(find build/Symbols/Release -name "*.driver" | head -1)
if [ -z "$DRIVER_PATH" ]; then
    echo "ERROR: Driver build failed!"
    ls -laR build/ 2>/dev/null | head -50
    exit 1
fi

TARGET_NAME="${DRIVER_NAME}${CHANNELS}ch.driver"
mv "$DRIVER_PATH" "build/Symbols/Release/${TARGET_NAME}"

rm -rf "Scripts/${PKG_NAME}"
mkdir -p "Scripts/${PKG_NAME}/Library/Audio/Plug-Ins/HAL"
cp -R "build/Symbols/Release/${TARGET_NAME}" "Scripts/${PKG_NAME}/Library/Audio/Plug-Ins/HAL/"

mkdir -p "Scripts/${PKG_NAME}/Scripts"
cat > "Scripts/${PKG_NAME}/Scripts/postinstall" << 'POSTINSTALL'
#!/bin/bash
killall -9 coreaudiod 2>/dev/null || true
POSTINSTALL
chmod +x "Scripts/${PKG_NAME}/Scripts/postinstall"

pkgbuild \
  --identifier audio.xac.${PKG_NAME} \
  --version 1.0.0 \
  --root "Scripts/${PKG_NAME}" \
  --scripts "Scripts/${PKG_NAME}/Scripts" \
  --install-location "/" \
  "Scripts/${PKG_NAME}.pkg"

echo ""
echo "============================================"
echo "${PKG_NAME}.pkg created!"
echo "============================================"