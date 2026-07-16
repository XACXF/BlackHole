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

# Use Python to write GCC_PREPROCESSOR_DEFINITIONS to file (avoids all shell quoting issues)
python3 -c "
import json, sys

driver_name = '''${DRIVER_NAME}'''
bundle_id = '''${BUNDLE_ID}'''
device_name = '''${DEVICE_NAME}'''
channels = '''${CHANNELS}'''

gcc_def = (
    'GCC_PREPROCESSOR_DEFINITIONS=' +
    json.dumps(
        'kDriver_Name=' + json.dumps(driver_name)[1:-1] +
        ' kPlugIn_BundleID=' + json.dumps(bundle_id)[1:-1] +
        ' kDevice_Name=' + json.dumps(device_name)[1:-1] +
        ' kDevice2_Name=' + json.dumps(device_name)[1:-1] +
        ' kNumber_Of_Channels=' + channels +
        ' kLatency_Frame_Size=128' +
        ' kDevice_IsHidden=' + json.dumps('FALSE')[1:-1] +
        ' kDevice_HasInput=' + json.dumps('TRUE')[1:-1] +
        ' kDevice_HasOutput=' + json.dumps('TRUE')[1:-1] +
        ' kDevice2_IsHidden=' + json.dumps('FALSE')[1:-1] +
        ' kDevice2_HasInput=' + json.dumps('FALSE')[1:-1] +
        ' kDevice2_HasOutput=' + json.dumps('FALSE')[1:-1]
    )
)
print(gcc_def)
"

xcodebuild -project BlackHole.xcodeproj \
  -configuration Release \
  -target BlackHole \
  PRODUCT_BUNDLE_IDENTIFIER="${BUNDLE_ID}" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  "$(python3 -c "
import json
driver_name = '''${DRIVER_NAME}'''
bundle_id = '''${BUNDLE_ID}'''
device_name = '''${DEVICE_NAME}'''
channels = '''${CHANNELS}'''
gcc_def = (
    'GCC_PREPROCESSOR_DEFINITIONS=' +
    json.dumps(
        'kDriver_Name=' + json.dumps(driver_name)[1:-1] +
        ' kPlugIn_BundleID=' + json.dumps(bundle_id)[1:-1] +
        ' kDevice_Name=' + json.dumps(device_name)[1:-1] +
        ' kDevice2_Name=' + json.dumps(device_name)[1:-1] +
        ' kNumber_Of_Channels=' + channels +
        ' kLatency_Frame_Size=128' +
        ' kDevice_IsHidden=' + json.dumps('FALSE')[1:-1] +
        ' kDevice_HasInput=' + json.dumps('TRUE')[1:-1] +
        ' kDevice_HasOutput=' + json.dumps('TRUE')[1:-1] +
        ' kDevice2_IsHidden=' + json.dumps('FALSE')[1:-1] +
        ' kDevice2_HasInput=' + json.dumps('FALSE')[1:-1] +
        ' kDevice2_HasOutput=' + json.dumps('FALSE')[1:-1]
    )
)
print(gcc_def)
")" \
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