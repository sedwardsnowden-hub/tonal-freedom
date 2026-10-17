# ⚠️ ADVANCED MODIFICATION GUIDE ⚠️

> **DISCLAIMER:** **IF YOU ARE NOT EXTREMELY TECH-SAVY, DO NOT PROCEED.** You can brick your device if all instructions are not followed properly.
> *This guide is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with this guide or the use or other dealings in the guide.*

---

## Equipment Needed

1. **A Debian-based Linux computer:** A Raspberry Pi 4B or 5 running Raspberry Pi OS is recommended, but any Debian-based distribution (e.g., Ubuntu Linux) will work.
2. **[mtkclient](https://github.com/bkerler/mtkclient):** Fully installed and set up on the Linux computer.
3. **Extended Torx security bit set:** Such as the [LABEAR 10-Piece Metric Tamper Hex Bit Set](https://www.amazon.com/dp/B0C5R5MGDF) (4-Inch S2 Steel Bits, H1.5–H8, 100mm reach, 1/4" shank). <img src="https://m.media-amazon.com/images/I/81E2O5iNeIL._AC_SX679_PIbundle-10,TopRight,0,0_SH20_.jpg" />
4. **A drill**
5. **A 3-foot micro-USB to USB-A cable**
6. **Kapton tape** *(Optional)*

## ⚠️ Safety Disclaimer

Use the provided software and information in this project at your own risk. This project is provided for educational and research purposes. Modifying your device's software or system configuration can cause unexpected behavior, data loss, system instability, or potentially render your device unusable.

Before proceeding, make sure you understand the instructions, back up any important data, and verify that you understand the changes being made to your device. You are solely responsible for any modifications you choose to make and any resulting consequences.

No warranty is provided. This project is distributed "AS IS" and "AS AVAILABLE," without warranties of any kind, whether express or implied, including, but not limited to, warranties of merchantability, fitness for a particular purpose, and non-infringement, to the extent permitted by applicable law.

The author and contributors are not responsible for any damage to devices, data loss, software issues, loss of functionality, or other consequences arising from the use or inability to use this project, to the extent permitted by applicable law.

This project is provided without any guarantee of continued support, maintenance, compatibility, or future updates.

By using this project, you acknowledge that you understand and accept these risks.

---

## Step 1: Getting Inside

1. Turn your device on, rotate the arm **all the way** on the right side inward, and lift the arm upwards. <img src="https://preview.redd.it/diy-spectra-cable-replacement-v0-fw9y1tm5umye1.jpg?width=1080&crop=smart&auto=webp&s=0a194276139d70c40777086b5d11fc6ff4d9931e" />
3. This reveals **4 metric security screws** on the right side behind the inner lip of the screen. Use the **#4 Torx bit** on all 4 screws. Go relatively slowly to avoid stripping them.
4. Your device should open up like a hinged door or cabinet (from right to left) with almost no resistance. <img src="https://preview.redd.it/diy-spectra-cable-replacement-v0-qiuypcfdumye1.png?width=664&format=png&auto=webp&s=a9b0a1dc880809c9dd318195a1d70dcd15501ae0" />

> ⚠️ **HIGH VOLTAGE WARNING:** There are high-voltage components inside this device. If you do not know how to safely work around high voltage, find someone qualified to help you before continuing. The Android Single Board Computer (SBC)—mounted on the hinged door—is likely low voltage and the **only** thing you should be touching. Continue at your own risk.

---

## Step 2: Preparing the Connection

The Android Single Board Computer features a micro-USB port, which serves as your entry point:

1. Attach the micro-USB cable to the Android SBC.
2. **(Optional)** Route the cable through the holes in the top-left corner of the device and close the cabinet using the 4 security screws. Tape the cable down securely using a non-flammable tape like **Kapton tape** to prevent it from getting pinched.
3. Connect the other end of the cable to your Debian/Ubuntu Linux computer.

---

## Step 3: Backing Up Your Device (Critical Step)

1. Ensure you have followed all [mtkclient installation instructions](https://www.google.com/search?q=https%3A%2F%2Fgithub.com%2Fbkerler%2Fmtkclient%2Fblob%2Fmain%2FREADME-INSTALL.md%23for-debianubuntu-here-assuming-fresh-install).
2. Open your terminal and run:
```bash
python mtk_gui.py

```


3. The tool will run a loop asking you to enter **BROM mode** on the device. **Do not do this manually.** Instead, let mtkclient handle it: simply turn off the device and turn it back on while the loop is still running. Mtkclient will automatically catch the BROM entry.
4. **IMPORTANT:** Using the mtkclient GUI, **make a backup of ALL partitions**.
* This is your only safety net if something goes wrong. If you fail to make a backup, you will be completely out of luck (SOL).
* You can back up all images except `user_data` first, and then back up the `user_data` partition separately if preferred.


5. Store these backups somewhere safe. **Never modify these original image instances**—consider them your "virgin" backups.

---

## Step 4: Patching and Flashing

1. Make a copy of your `boot.bin` image from your backups. **This is the only file you will be modifying.**
2. Place the copy of `boot.bin` into the same folder as [patcher.sh](https://github.com/voided404/MagiskScripts/blob/main/patcher.sh).
3. In your terminal, run:
```bash
bash patcher.sh

```


4. If successful, you will now have a `boot.patched.img` file. This is what you will use to unlock your device.
5. **Double-check** that you have verified virgin backups of **EVERY** partition available in mtkclient.
6. Once confirmed, perform the flash: flash `boot.patched.img` using mtkclient in place of your standard boot partition.
> ⚠️ **Point of No Return:** If this goes wrong, you can brick your device (e.g., boot loops). If you are not technically inclined, find someone who is. If you run into issues, don't panic: simply flash back your virgin backups.


7. Once flashing is complete, exit mtkclient and **power cycle** (turn off, then on) your device. It should boot up normally and your device is now unlocked, giving you ADB access.

---

## Step 5: Post-Unlock Setup

1. Use the `start.adb.sh` file generated by `patcher.sh`. This grants authorized access using ADB keys injected at bootup.
2. Using ADB, you can now install apps and perform custom actions. I suggest to start with you install the [Magisk v27 apk](https://github.com/topjohnwu/Magisk/releases/download/v27.0/Magisk-v27.0.apk) with adb.
> 💡 **Tip:** Proceed with caution, as SELinux policy is also set to `0`. It is strongly recommended to change that back as soon as you finish making your desired modifications.

# Donations / Sponsorship 

If this project helped you unlock your device, please consider supporting continued development with a [one-time sponsorship on GitHub](https://github.com/sponsors/voided404?frequency=one-time&sponsor=voided404&amount=100). Your support helps make future projects and improvements possible. Thank you!

I also have a Bitcoin address: `1DW2HGqVp1qrG7AcqMCGEBBHH2EGRYphbw` and an ethereum address: `0x24201Ef392054b464De7c15DF871B93F9509b6E0`  if you'd like to contribute there instead. 

