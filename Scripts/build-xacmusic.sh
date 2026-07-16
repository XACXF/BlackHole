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

# Use printf to safely write the xcodebuild command to a file
# This avoids all shell quoting issues with GCC_PREPROCESSOR_DEFINITIONS
cat > /tmp/build_driver.sh << 'INNER_EOF'
#!/bin/bash
xcodebuild -project BlackHole.xcodeproj \
  -configuration Release \
  -target BlackHole \
  PRODUCT_BUNDLE_IDENTIFIER="__BUNDLE_ID__" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  "GCC_PREPROCESSOR_DEFINITIONS=GCC_PREPROCESSOR_DEFINITIONS kDriver_Name=\"__DRIVER_NAME__\" kPlugIn_BundleID=\"__BUNDLE_ID__\" kDevice_Name=\"__DEVICE_NAME__\" kDevice2_Name=\"__DEVICE_NAME__\" kNumber_Of_Channels=__CHANNELS__ kLatency_Frame_Size=128 kDevice_IsHidden=\"FALSE\" kDevice_HasInput=\"TRUE\" kDevice_HasOutput=\"TRUE\" kDevice2_IsHidden=\"FALSE\" kDevice2_HasInput=\"FALSE\" kDevice2_HasOutput=\"FALSE\"" \
  OBJROOT=build/Objects \
  SYMROOT=build/Symbols \
  DSTROOT=build/Archive 2>&1
INNER_EOF

# Replace placeholders
sed -i "s/__DRIVER_NAME__/${DRIVER_NAME}/g" /tmp/build_driver.sh
sed -i "s/__BUNDLE_ID__/${BUNDLE_ID}/g" /tmp/build_driver.sh
sed -i "s/__DEVICE_NAME__/${DEVICE_NAME}/g" /tmp/build_driver.sh
sed -i "s/__CHANNELS__/${CHANNELS}/g" /tmp/build_driver.sh
sed -i "s/__PKG_NAME__/${PKG_NAME}/g" /tmp/build_driver.sh

echo "Running xcodebuild..."
bash /tmp/build_driver.sh

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