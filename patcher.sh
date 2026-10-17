#!/bin/bash

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Utility: Patches a given boot.bin or boot.img with Magisk
# Expectation: In your current working directory, you have the following files: 
# 1. boot.bin or boot.img - an unencryped raw binary of your android's environment's boot partition
# 2. Magisk-v27.0.apk (or other magisk APK)

# NOTE: Please run this as sudo

# ==========================================
# Configuration & File Checks
# ==========================================
ORIG_DIR="$PWD"
MAGISK_APK="Magisk-v27.0.apk"
TEXT_LAUNCHER_APK="textlauncher.apk"
FINAL_OUT="boot.patched.img"
SDK_VER=23
CPU_ABI="arm64-v8a"

# Define a permanent, self-contained key vault folder inside the user's home directory
TARGET_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$TARGET_USER)
VAULT_DIR="$USER_HOME/tonal_keys"
ADB_PUB_KEY="$VAULT_DIR/adbkey.pub"
ADB_PRIV_KEY="$VAULT_DIR/adbkey"

# Ensure script is run with sudo and is ran with bash shell
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root. Please use sudo or su." >&2
    exit 1
fi
if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script must be run using the Bash shell." >&2
    exit 1
fi

# Auto-detect whether the boot image is named .img or .bin
if [ -f "boot.img" ]; then
    BOOT_IMG="boot.img"
elif [ -f "boot.bin" ]; then
    BOOT_IMG="boot.bin"
else
    echo "[!] Error: Neither boot.img nor boot.bin found in current directory."
    exit 1
fi

# Ensure Magisk APK is Present. 
if [ ! -f "$MAGISK_APK" ]; then
    # Uncomment for alternative later version of the v27.0.0.8 canary release
    #MAGISK_APK="Magisk-v27.0.0.8.apk"
    #wget https://github.com/topjohnwu/Magisk/releases/download/canary-27008/app-debug.apk -O $MAGISK_APK
    wget https://github.com/topjohnwu/Magisk/releases/download/v27.0/Magisk-v27.0.apk -O $MAGISK_APK
fi
if [ ! -f "$MAGISK_APK" ]; then
    echo "[!] Error: $MAGISK_APK not found!"
    exit 1
fi

# Ensure text launcher apk is present.
if [ ! -f "$TEXT_LAUNCHER_APK" ]; then
   wget https://github.com/ademar111190/TextLauncher/releases/download/1.4.1/app-release.apk -O $TEXT_LAUNCHER_APK
fi
if [ ! -f "$TEXT_LAUNCHER_APK" ]; then
    echo "[!] Error: $TEXT_LAUNCHER_APK not found!"
    exit 1
fi

# ==========================================
# Phase 1: Golden Key Vault Generation
# ==========================================
echo "[*] Ensuring permanent ADB golden key exists..."
mkdir -p "$VAULT_DIR"

if [ ! -f "$ADB_PUB_KEY" ] || [ ! -f "$ADB_PRIV_KEY" ]; then
    echo "    -> Generating a fresh, immutable ADB key pair in $VAULT_DIR..."
    su - "$TARGET_USER" -c "adb kill-server >/dev/null 2>&1; rm -f ~/.android/adbkey ~/.android/adbkey.pub; adb start-server >/dev/null 2>&1"
    
    if [ -f "$USER_HOME/.android/adbkey.pub" ]; then
        cp "$USER_HOME/.android/adbkey" "$ADB_PRIV_KEY"
        cp "$USER_HOME/.android/adbkey.pub" "$ADB_PUB_KEY"
    else
        openssl genrsa -out "$ADB_PRIV_KEY" 2048 2>/dev/null
        openssl rsa -in "$ADB_PRIV_KEY" -pubout -out "$ADB_PUB_KEY" 2>/dev/null
    fi
fi

chown -R "$TARGET_USER:$TARGET_USER" "$VAULT_DIR"
chmod 0600 "$ADB_PRIV_KEY"
chmod 0644 "$ADB_PUB_KEY"
echo "    -> Golden Key Vault ready at $VAULT_DIR"

# ==========================================
# Phase 2: Set Up Temporary Workspace
# ==========================================
TEMP_DIR=$(mktemp -d)
echo "[*] Created temporary workspace at $TEMP_DIR"

# Ensure cleanup happens even if the script exits abruptly
trap 'echo "[*] Cleaning up workspace..."; cd "$ORIG_DIR"; rm -rf "$TEMP_DIR"; umount "$MOUNT_DIR" 2>/dev/null; rmdir "$MOUNT_DIR" 2>/dev/null' EXIT

cd "$TEMP_DIR" || exit 1

# ==========================================
# Phase 3: Extract Magisk Tools
# ==========================================
echo "[*] Extracting Magisk tools from $MAGISK_APK..."
unzip -q -o -j "$ORIG_DIR/$MAGISK_APK" "assets/boot_patch.sh" -d .
unzip -q -o -j "$ORIG_DIR/$MAGISK_APK" "assets/util_functions.sh" -d .
unzip -q -o -j "$ORIG_DIR/$MAGISK_APK" "assets/stub.apk" -d .
unzip -q -o -j "$ORIG_DIR/$MAGISK_APK" "lib/arm64-v8a/libmagiskboot.so" -d .
unzip -q -o -j "$ORIG_DIR/$MAGISK_APK" "lib/arm64-v8a/libmagiskinit.so" -d .
unzip -q -o -j "$ORIG_DIR/$MAGISK_APK" "lib/arm64-v8a/libmagisk64.so" -d .
unzip -q -o -j "$ORIG_DIR/$MAGISK_APK" "lib/armeabi-v7a/libmagisk32.so" -d .

echo "[*] Renaming and setting permissions for binaries..."
mv -f libmagiskboot.so magiskboot
mv -f libmagiskinit.so magiskinit
mv -f libmagisk64.so magisk64
mv -f libmagisk32.so magisk32
chmod +x boot_patch.sh magiskboot magiskinit magisk64 magisk32

cp -f "$ORIG_DIR/$MAGISK_APK" magisk.apk

# Hard-patch util_functions.sh to force standard output (1) instead of the broken O33 variable
sed -i 's/>&${O33}/>\&1/g' util_functions.sh
sed -i 's/>& $O33/>\&1/g' util_functions.sh

# ==========================================
# Phase 4: Create getprop Stub (necessary for magisk tools used outside of a phone)
# ==========================================
echo "[*] Generating dynamic getprop stub..."
cat << EOF > getprop
#!/bin/bash
case "\$1" in
    ro.build.version.sdk) echo "$SDK_VER" ;;
    ro.product.cpu.abi) echo "$CPU_ABI" ;;
    *) echo "" ;;
esac
EOF
chmod +x getprop

# ==========================================
# Phase 5: Execute Magisk Patch
# ==========================================
echo "[*] Copying boot image to temp workspace..."
cp "$ORIG_DIR/$BOOT_IMG" .

echo "[*] Patching $BOOT_IMG with Magisk..."
export KEEPVERITY=true
export KEEPFORCEENCRYPT=true
export RECOVERYMODE=false
export LEGACYSAR=false
export PATCHVBMETAFLAG=false
export PATH="$PATH:$PWD"

bash boot_patch.sh "$BOOT_IMG"

# ==========================================
# Phase 6: Inject Payload (ADB, Launcher, Bypass)
# ==========================================
if [ ! -f "new-boot.img" ]; then
    echo "[!] Error: new-boot.img was not generated. The Magisk patch failed."
    exit 1
fi

echo "[*] Unpacking patched image to inject payload..."
./magiskboot unpack new-boot.img >/dev/null

echo "[*] Extracting ramdisk..."
mkdir ramdisk_root && cd ramdisk_root
cpio -idm < ../ramdisk.cpio 2>/dev/null

echo "[*] Creating Magisk overlay.d structure..."
mkdir -p overlay.d/sbin

echo "[*] Injecting Permanent Golden ADB Public Key into Native Root..."
# Android 6 adbd natively looks at /adb_keys on boot.
cp "$ADB_PUB_KEY" overlay.d/adb_keys
chmod 0640 overlay.d/adb_keys

echo "[*] Staging Launcher Payload into /sbin..."
cp "$ORIG_DIR/$TEXT_LAUNCHER_APK" overlay.d/sbin/textlauncher.apk
chmod 0644 overlay.d/sbin/textlauncher.apk

echo "[*] Generating Native Init Service Script..."
cat << 'EOF' > overlay.d/sbin/bypass_kiosk.sh
#!/system/bin/sh

# 0. EXPORT ENVIRONMENT (CRITICAL FIX)
# Native init scripts have no PATH. We must define the environment so am/pm/settings commands work.
export PATH=/sbin:/system/sbin:/system/bin:/system/xbin
export ANDROID_ROOT=/system
export ANDROID_DATA=/data

# SELINUX OVERRIDE (CRITICAL FIX)
# Force the runtime state if kernel allows it
setenforce 0
# Inject broad Magisk policies live just in case
/sbin/magiskpolicy --live "permissive *"

# 1. Wait for Android Framework (ActivityManager) to wake up (with safety timeout)
ATTEMPTS=0
MAX_ATTEMPTS=600
until dumpsys activity >/dev/null 2>&1; do
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
        echo "[!] Warning: Framework did not wake up in time. Continuing boot anyway..."
        break
    fi
    sleep 2
done

# 2. Push ADB settings and force-restart adbd just in case
mkdir -p /data/misc/adb
cat /adb_keys >> /data/misc/adb/adb_keys
chmod 0640 /data/misc/adb/adb_keys
chown system:shell /data/misc/adb/adb_keys
settings put secure development_settings_enabled 1
settings put secure adb_enabled 1
setprop ctl.restart adbd

# 3. Install TextLauncher ONLY if it is missing (using fast, safe pm path check)
if [ -z "$(pm path ademar.textlauncher 2>/dev/null)" ]; then
    pm install -r /sbin/textlauncher.apk
fi

# 4. Force-stop and disable the Tonal kiosk apps
am force-stop com.tonal.tonallauncher
am force-stop com.tonal.apps.machineclient2
pm disable com.tonal.tonallauncher

# 5. Force open standard Android Settings and Developer Options
am start -a android.settings.SETTINGS
am start -a com.android.settings.APPLICATION_DEVELOPMENT_SETTINGS

# 6. Force the notification panel to drop down (using raw binder call)
service call statusbar 1

# 7. Wake up the screen and launch the new home environment
am start -a android.intent.action.MAIN -c android.intent.category.HOME
EOF

chmod 0755 overlay.d/sbin/bypass_kiosk.sh

echo "[*] Injecting overlay.d custom.rc..."
cat << EOF > overlay.d/custom.rc
on early-init
    # SeLinux Permissive via sysfs
    write /sys/fs/selinux/enforce 0
    
    setprop ro.debuggable 1
    setprop ro.secure 0
    setprop ro.adb.secure 0
    setprop persist.sys.usb.config adb
    setprop sys.usb.config adb
    setprop service.adb.root 1

# Automatically destroy all Device Administrator policies before Android boots
on post-fs-data
    rm /data/system/device_policies.xml
    rm /data/system/device_owner.xml
    rm /data/system/device_owner_2.xml
    rm /data/system/profile_owner.xml

# Start our script natively via the Android init system
on boot
    start bypass_kiosk

service bypass_kiosk /system/bin/sh /sbin/bypass_kiosk.sh
    class late_start
    user root
    group root
    seclabel u:r:su:s0
    oneshot
EOF

echo "[*] Repacking ramdisk..."
find . | cpio -o -H newc > ../ramdisk.cpio 2>/dev/null
cd ..

echo "[*] Repacking final boot image..."
./magiskboot repack new-boot.img "$FINAL_OUT" >/dev/null

# ==========================================
# Phase 7: Automated Verification Checks
# ==========================================
echo "[*] Running post-build integrity and safety checks..."

if ! ./magiskboot verify "$FINAL_OUT"; then
    echo "[!] FATAL: magiskboot structural verification failed! The image is corrupted."
    exit 1
else
    echo "    -> Header and Signature Check: PASS"
fi

mkdir verify_perms && cd verify_perms
../magiskboot unpack "../$FINAL_OUT" >/dev/null 2>&1
INIT_PERMS=$(cpio -tv < ramdisk.cpio 2>/dev/null | grep -E "[[:blank:]]init$" | awk '{print $3, $4}')

if [[ "$INIT_PERMS" == *"root root"* || "$INIT_PERMS" == *"0 0"* ]]; then
    echo "    -> Internal Root Ownership: PASS ($INIT_PERMS)"
else
    echo "[!] FATAL: Internal file permissions are stripped or corrupted!"
    echo "[!] The core init binary is owned by: $INIT_PERMS (Expected: root root)"
    echo "[!] Aborting deployment."
    cd ..
    exit 1
fi
cd ..

# ==========================================
# Phase 8: Final Outputs & Helper Generation
# ==========================================
if [ -f "$FINAL_OUT" ]; then
    mv "$FINAL_OUT" "$ORIG_DIR/$FINAL_OUT"
    
    cat << EOF > "$ORIG_DIR/start.adb.sh"
#!/bin/bash
export ADB_VENDOR_KEYS="$ADB_PRIV_KEY"
echo "[*] ADB_VENDOR_KEYS set to permanent vault key."
adb kill-server
adb start-server
echo "[*] ADB server restarted. Ready for connection."
EOF
    chmod +x "$ORIG_DIR/start.adb.sh"

    chown -R "$TARGET_USER:$TARGET_USER" "$ORIG_DIR/$FINAL_OUT" "$ORIG_DIR/start.adb.sh"
    
    echo "=========================================="
    echo "[*] SUCCESS! Image verified and ready:"
    echo "[*] Output Image: $ORIG_DIR/$FINAL_OUT"
    echo "[*] ADB Helper Script: $ORIG_DIR/start.adb.sh"
    echo "=========================================="
else
    echo "[!] Error: $FINAL_OUT was not generated."
fi
