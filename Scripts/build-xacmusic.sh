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

cat > /tmp/build_driver.py << PYEOF
import subprocess
import sys

driver_name = """DRIVER_NAME_PLACEHOLDER"""
bundle_id = """BUNDLE_ID_PLACEHOLDER"""
device_name = """DEVICE_NAME_PLACEHOLDER"""
channels = """CHANNELS_PLACEHOLDER"""

gcc_parts = [
    'kDriver_Name=' + repr(driver_name),
    'kPlugIn_BundleID=' + repr(bundle_id),
    'kDevice_Name=' + repr(device_name),
    'kDevice2_Name=' + repr(device_name),
    'kNumber_Of_Channels=' + repr(channels).replace("'",""),
    'kLatency_Frame_Size=128',
    'kDevice_IsHidden=' + repr('FALSE'),
    'kDevice_HasInput=' + repr('TRUE'),
    'kDevice_HasOutput=' + repr('TRUE'),
    'kDevice2_IsHidden=' + repr('FALSE'),
    'kDevice2_HasInput=' + repr('FALSE'),
    'kDevice2_HasOutput=' + repr('FALSE'),
]

gcc_def = ' '.join(gcc_parts)
print("GCC_DEF:", repr(gcc_def))

cmd = [
    'xcodebuild',
    '-project', 'BlackHole.xcodeproj',
    '-configuration', 'Release',
    '-target', 'BlackHole',
    'PRODUCT_BUNDLE_IDENTIFIER=' + bundle_id,
    'CODE_SIGNING_REQUIRED=NO',
    'CODE_SIGNING_ALLOWED=NO',
    'GCC_PREPROCESSOR_DEFINITIONS=' + gcc_def,
    'OBJROOT=build/Objects',
    'SYMROOT=build/Symbols',
    'DSTROOT=build/Archive',
]

result = subprocess.run(cmd, capture_output=False)
sys.exit(result.returncode)
PYEOF

sed -i '' "s/DRIVER_NAME_PLACEHOLDER/${DRIVER_NAME}/" /tmp/build_driver.py
sed -i '' "s/BUNDLE_ID_PLACEHOLDER/${BUNDLE_ID}/" /tmp/build_driver.py
sed -i '' "s/DEVICE_NAME_PLACEHOLDER/${DEVICE_NAME}/" /tmp/build_driver.py
sed -i '' "s/CHANNELS_PLACEHOLDER/${CHANNELS}/" /tmp/build_driver.py

echo "Running xcodebuild via Python..."
python3 /tmp/build_driver.py

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