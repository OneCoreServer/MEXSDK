# ★彡 [ ↻ ONECORE ENGINE ↺ ] 彡★

🔥 **Android Virtual Injector (Non-Root)** 🔥  
An advanced injector to inject games and apps via Virtual Space without rooting your Android device.

---

## ⚡ What's Special About OneCore Engine?
- 🚀 **Supports Latest Android (9 to 17)**
- 🌟 **Clean, Modular, Easy-to-maintain Code**
- 🎯 **No Root Required**
- 🌐 **Fully Open Source**
- 🎨 **Easy & Stylish User Interface**

---

## 🚀 Features
- [x] **Non-root injection** support.
- [x] Compatibility with **Android 9 to 17**.
- [ ] Upcoming support for **x86 and x86_64** architectures.

---

## 🎯 How to Use?
1. Open the Injector.
2. Select your target App/Game.
3. Choose the `.so` (shared library) file you want to inject.
4. Click on **"Install"** to install inside virtual environment.
5. Click on **"Inject"** to launch the application instantly.

---


## 🗂️ Repository Structure Note
- `NewBlackbox/` contains the active SDK source used by the project.
- `reference_sdk/` is kept only for reference/comparison; do not modify files there during normal development.
- Remaining main source files (outside `reference_sdk`) are primarily for the loader/injector implementation.

---


## 📦 GitHub Build: NewBlackbox AAR + Loader APK
Push your branch to GitHub or run the **Build NewBlackbox AAR + Loader APK** workflow manually from the Actions tab. The workflow does this automatically:

1. Builds `NewBlackbox:Bcore` as an Android AAR.
2. Copies the generated AAR over `app/libs/Bcore-release.aar` so the loader uses the fresh NewBlackbox SDK.
3. Builds the loader APK.
4. Uploads both files in the `newblackbox-aar-loader-apk` artifact.

After the workflow finishes, open the run page, download **Artifacts → newblackbox-aar-loader-apk**, and extract it to get the Loader APK.

For local builds, run:

```bash
SDK_DIR=/path/to/Android/Sdk ALLOW_DEBUG_FALLBACK=true scripts/build-newblackbox-loader.sh
```

The local output is written to `build/newblackbox-loader-artifacts/`.

---

## 🌟 Credits
**Project Owner & Developer:**  
✨『 ↻ **ONECORE ENGINE** ↺ 』✨  
Owner Username (Telegram): **@L359D**

---

## 🤝 Contributions
Contributions and ideas are welcome.  
Please open issues or submit pull requests to contribute.

---

## ❗ Limitations
Not compatible with games/apps protected by advanced anti-cheat mechanisms.

---

## 📲 Connect & Support
- 📢 **Telegram Channel:** [OneCoreEngine](https://t.me/OneCoreEngine)
- 👤 **Telegram Owner:** [@L359D](https://t.me/L359D)

---

## ❤️ Support Development
Consider supporting me on [Patreon](https://www.patreon.com/c/Reveny).

---

## 📜 License
Licensed under [GPLv3](LICENSE).

---

## 🖼️ Preview
![Preview](https://github.com/jagdishvip/Android-Virtual-Inject/blob/main/preview.jpg)

---

**✨彡 ↻ ONECORE ENGINE ↺ 彡✨ © 2026**
