#!/bin/bash
set -e

DRIVER_NAME="${DRIVER_NAME:-XACliv}"
BUNDLE_ID="${BUNDLE_ID:-audio.xac.XACliv}"
DEVICE_NAME="${DEVICE_NAME:-XACliv}"
CHANNELS="${CHANNELS:-2}"
PKG_NAME="${PKG_NAME:-XACliv}"

echo "============================================"
echo "Building ${DRIVER_NAME} (${CHANNELS}ch)"
echo "============================================"

rm -rf build
rm -rf "Scripts/${PKG_NAME}.pkg"
rm -rf "Scripts/${PKG_NAME}"

GCC_DEF=$(python3 -c "
import shlex

driver = '''${DRIVER_NAME}'''
bundle = '''${BUNDLE_ID}'''
device = '''${DEVICE_NAME}'''
chans = '''${CHANNELS}'''

parts = [
    'kDriver_Name=' + repr(driver),
    'kPlugIn_BundleID=' + repr(bundle),
    'kDevice_Name=' + repr(device),
    'kDevice2_Name=' + repr(device),
    'kNumber_Of_Channels=' + chans,
    'kLatency_Frame_Size=128',
    'kDevice_IsHidden=' + repr('FALSE'),
    'kDevice_HasInput=' + repr('TRUE'),
    'kDevice_HasOutput=' + repr('TRUE'),
    'kDevice2_IsHidden=' + repr('FALSE'),
    'kDevice2_HasInput=' + repr('FALSE'),
    'kDevice2_HasOutput=' + repr('FALSE'),
]
print('GCC_PREPROCESSOR_DEFINITIONS=' + ' '.join(parts))
")

echo "GCC_DEF: $GCC_DEF"

xcodebuild -project BlackHole.xcodeproj \
  -configuration Release \
  -target BlackHole \
  PRODUCT_BUNDLE_IDENTIFIER="${BUNDLE_ID}" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  "${GCC_DEF}" \
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