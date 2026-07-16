#!/bin/bash
set -e

DRIVER_NAME="XACliv"
BUNDLE_ID="audio.xac.XACliv"
DEVICE_NAME="XACliv"
CHANNELS=2
PKG_NAME="XACliv"

echo "============================================"
echo "Building ${DRIVER_NAME} (${CHANNELS}ch)"
echo "============================================"

# Clean
rm -rf build
rm -rf Scripts/${PKG_NAME}.pkg
rm -rf Scripts/${PKG_NAME}

# Build from repo root
xcodebuild -project BlackHole.xcodeproj \
  -configuration Release \
  -target BlackHole \
  PRODUCT_BUNDLE_IDENTIFIER=${BUNDLE_ID} \
  GCC_PREPROCESSOR_DEFINITIONS="$GCC_PREPROCESSOR_DEFINITIONS kDriver_Name=\"${DRIVER_NAME}\" kPlugIn_BundleID=\"${BUNDLE_ID}\" kDevice_Name=\"${DEVICE_NAME}\" kDevice2_Name=\"${DEVICE_NAME}\" kNumber_Of_Channels=${CHANNELS} kLatency_Frame_Size=128 kDevice_IsHidden=\"FALSE\" kDevice_HasInput=\"TRUE\" kDevice_HasOutput=\"TRUE\" kDevice2_IsHidden=\"FALSE\" kDevice2_HasInput=\"FALSE\" kDevice2_HasOutput=\"FALSE\"" \
  OBJROOT=build/Objects \
  SYMROOT=build/Symbols \
  DSTROOT=build/Archive 2>&1

DRIVER_PATH=$(find build/Archive -name "*.driver" | head -1)
if [ -z "$DRIVER_PATH" ]; then
    echo "ERROR: Driver build failed!"
    exit 1
fi

TARGET_NAME="${DRIVER_NAME}${CHANNELS}ch.driver"
mv "$DRIVER_PATH" "build/Archive/${TARGET_NAME}"

# Create package
rm -rf Scripts/${PKG_NAME}
mkdir -p Scripts/${PKG_NAME}/Library/Audio/Plug-Ins/HAL
cp -R "build/Archive/${TARGET_NAME}" Scripts/${PKG_NAME}/Library/Audio/Plug-Ins/HAL/

mkdir -p Scripts/${PKG_NAME}/Scripts
cat > Scripts/${PKG_NAME}/Scripts/postinstall << 'POSTINSTALL'
#!/bin/bash
DRIVER_NAME="XACliv"
CHANNELS=2
DRIVER_PATH="/Library/Audio/Plug-Ins/HAL/${DRIVER_NAME}${CHANNELS}ch.driver"
[ -d "$DRIVER_PATH" ] && rm -rf "$DRIVER_PATH"
cp -R "$(dirname $0)/../Library/Audio/Plug-Ins/HAL/${DRIVER_NAME}${CHANNELS}ch.driver" /Library/Audio/Plug-Ins/HAL/
killall -9 coreaudiod 2>/dev/null || true
POSTINSTALL
chmod +x Scripts/${PKG_NAME}/Scripts/postinstall

pkgbuild \
  --identifier audio.xac.${PKG_NAME} \
  --version 1.0.0 \
  --root Scripts/${PKG_NAME} \
  --scripts Scripts/${PKG_NAME}/Scripts \
  --install-location "/" \
  Scripts/${PKG_NAME}.pkg

echo ""
echo "============================================"
echo "XACliv.pkg created!"
echo "============================================"