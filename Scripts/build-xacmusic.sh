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

# Write full xcodebuild command to file
cat > /tmp/xcode_build.sh << ENDOFSCRIPT
#!/bin/bash
xcodebuild -project BlackHole.xcodeproj -configuration Release -target BlackHole PRODUCT_BUNDLE_IDENTIFIER="${BUNDLE_ID}" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO GCC_PREPROCESSOR_DEFINITIONS="kDriver_Name=\"${DRIVER_NAME}\" kPlugIn_BundleID=\"${BUNDLE_ID}\" kDevice_Name=\"${DEVICE_NAME}\" kDevice2_Name=\"${DEVICE_NAME}\" kNumber_Of_Channels=${CHANNELS} kLatency_Frame_Size=128 kDevice_IsHidden=\"FALSE\" kDevice_HasInput=\"TRUE\" kDevice_HasOutput=\"TRUE\" kDevice2_IsHidden=\"FALSE\" kDevice2_HasInput=\"FALSE\" kDevice2_HasOutput=\"FALSE\"" OBJROOT=build/Objects SYMROOT=build/Symbols DSTROOT=build/Archive 2>&1
ENDOFSCRIPT

chmod +x /tmp/xcode_build.sh
echo "Running xcodebuild..."
bash /tmp/xcode_build.sh

DRIVER_PATH=$(find build/Archive -name "*.driver" | head -1)
if [ -z "$DRIVER_PATH" ]; then
    echo "ERROR: Driver build failed!"
    exit 1
fi

TARGET_NAME="${DRIVER_NAME}${CHANNELS}ch.driver"
mv "$DRIVER_PATH" "build/Archive/${TARGET_NAME}"

rm -rf "Scripts/${PKG_NAME}"
mkdir -p "Scripts/${PKG_NAME}/Library/Audio/Plug-Ins/HAL"
cp -R "build/Archive/${TARGET_NAME}" "Scripts/${PKG_NAME}/Library/Audio/Plug-Ins/HAL/"

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