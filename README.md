# Own Your Device Again

You paid almost $5,000 for this machine. It sits in your home, bolted to your wall, and the company that sold it to you can turn it into a paperweight overnight by killing their servers or paywalling basic functionality behind a subscription.

That is not ownership. This project fixes that.

This is a full jailbreak for the **Tonal 1** smart home gym. It roots the device's Android OS using Magisk, breaks out of the locked kiosk app, and gives you ADB access to install whatever you want — including offline workout apps that do not phone home.

> **Credit:** The original jailbreak was developed and open-sourced by [voided404](https://github.com/voided404/MagiskScripts). This repo builds on that work with additional documentation and context.

---

## What This Does

- Roots the Tonal's internal Android 6 single-board computer via Magisk
- Disables the Tonal kiosk launcher and device administrator policies
- Enables ADB access with persistent key injection
- Installs a basic text launcher so you have a usable home screen
- Sets SELinux to permissive so sideloaded apps can run

After this process, the hardware is yours again. Use it with a third-party app, build your own workouts, or just have the peace of mind that your $5K wall-mounted gym will not become e-waste when the company decides to change its terms.

---

## Before You Start

> **⚠️ This is an advanced hardware and software modification. You can brick your device if you skip steps or do not follow the instructions exactly. Proceed at your own risk.**

### Compatibility

| Device | Status |
|--------|--------|
| Tonal 1 (MediaTek SoC, Android 6) | ✅ Confirmed working |
| Tonal 2 | ❓ Unknown — different chipset, untested |

### Equipment

1. **A Debian-based Linux computer** — Raspberry Pi 4B/5 with Raspberry Pi OS, Ubuntu, or similar
2. **[mtkclient](https://github.com/bkerler/mtkclient)** — fully installed and configured
3. **Extended Torx security bit set** — you need a **#4 Torx bit** for the security screws (e.g., [LABEAR 10-Piece Set](https://www.amazon.com/dp/B0C5R5MGDF))
4. **A drill**
5. **A 3-foot micro-USB to USB-A cable**
6. **Kapton tape** *(optional, for routing the cable)*

---

## The Process

### Step 1: Open the Device

1. Turn your Tonal on, rotate the right arm all the way inward, and lift the arm upwards.
2. Behind the inner lip of the screen on the right side, you will find **4 metric security screws**. Remove them with the #4 Torx bit. Go slowly to avoid stripping.
3. The front panel opens like a hinged door, right to left, with almost no resistance.

> **⚠️ HIGH VOLTAGE WARNING:** There are high-voltage components inside. The Android SBC — mounted on the hinged door — is the only thing you should be touching. If you are not comfortable working around high voltage, get someone qualified to help.

### Step 2: Connect to the Android SBC

1. Plug the micro-USB cable into the port on the Android SBC.
2. *(Optional)* Route the cable through the holes in the top-left corner and close the panel back up with the security screws. Use Kapton tape to secure the cable so it does not get pinched.
3. Connect the other end to your Linux computer.

### Step 3: Back Up Every Partition

This is your only safety net. Skip this and you are on your own.

1. Follow the [mtkclient installation instructions](https://github.com/bkerler/mtkclient/blob/main/README-INSTALL.md#for-debianubuntu-here-assuming-fresh-install).
2. Run the GUI:
   ```bash
   python mtk_gui.py
   ```
3. The tool loops waiting for BROM mode. **Do not enter BROM manually.** Just turn the Tonal off and back on while the loop runs — mtkclient catches it automatically.
4. **Back up ALL partitions** using the mtkclient GUI. You can do everything except `user_data` first, then `user_data` separately if preferred.
5. Store these backups somewhere safe. Never modify them. These are your "virgin" backups — your rollback path if anything goes wrong.

### Step 4: Patch and Flash the Boot Image

1. **Copy** your `boot.bin` from the backups. Never touch the original.
2. Place the copy in the same directory as `patcher.sh` (included in this repo).
3. Run the patcher:
   ```bash
   sudo bash patcher.sh
   ```
4. If successful, you now have a `boot.patched.img` file.
5. **Verify** that your virgin backups of every partition are intact and accessible.
6. Flash `boot.patched.img` using mtkclient in place of the original boot partition.

> **⚠️ Point of no return.** If the flash fails or something goes wrong, you can boot-loop or brick the device. Flash your virgin backups back using mtkclient to recover.

7. Exit mtkclient. Power cycle the Tonal (off, then on). It should boot normally — now unlocked with ADB access.

### Step 5: Post-Unlock Setup

1. The patcher generates a `start.adb.sh` helper script. Run it to connect via ADB with the keys injected during the patch.
2. Install the [Magisk v27.0 APK](https://github.com/topjohnwu/Magisk/releases/download/v27.0/Magisk-v27.0.apk) via ADB to manage root access going forward.
3. From here, install any Android apps you want — offline workout trackers, custom launchers, whatever you need.

> **Tip:** The patch sets SELinux to permissive (`setenforce 0`). Change it back once you are done making modifications.

---

## Risks and Limitations

- **Bricking is possible.** If you have good backups, you can recover using mtkclient. Without backups, you cannot.
- **Tonal can ban your account and device ID.** You cannot change the device ID. If you ever resell a jailbroken unit, disclose that.
- **OTA updates could lock you out.** The Android OS security model may allow Tonal to push an update that reverses or blocks this modification.
- **This is not reversible in every scenario.** The partition backups are your insurance — treat them accordingly.

---

## Files in This Repo

| File | Description |
|------|-------------|
| `patcher.sh` | Bash script that patches the boot image with Magisk, injects ADB keys, disables the kiosk, and installs a basic launcher |
| `GUIDE.md` | The full step-by-step jailbreak guide (this README covers the same ground) |
| `README.md` | You are here |

---

## Disclaimer

This project is provided "as is" without warranty of any kind. You are solely responsible for any modifications you make and any consequences that result. The authors are not liable for damage to devices, data loss, bricked hardware, banned accounts, or any other outcome.

This project is for educational and research purposes. Modifying your device may void its warranty and violate the manufacturer's terms of service.

---

## Acknowledgments

- Original jailbreak and patcher script by [voided404](https://github.com/voided404/MagiskScripts)
- [Magisk](https://github.com/topjohnwu/Magisk) by topjohnwu
- [mtkclient](https://github.com/bkerler/mtkclient) by bkerler
- [TextLauncher](https://github.com/ademar111190/TextLauncher) by ademar111190
- The [r/tonalgym](https://www.reddit.com/r/tonalgym/) community
