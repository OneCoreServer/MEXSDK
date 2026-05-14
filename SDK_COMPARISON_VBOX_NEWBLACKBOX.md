# NewBlackbox me kya missing hai (Vbox ke comparison me)

Ye document specifically aapke request ke liye hai: **Vbox me jo feature/code hai aur NewBlackbox me nahi hai**, uski actionable list taaki aap one-by-one add kar sako.

## A) High-Priority Missing Items (P1) — Pehle ye add karo

### 1) AIDL Contracts (important for loader/process callbacks)
- `android/Meta/IRemoteManager.aidl`
- `android/Meta/IVboxProcessCallback.aidl`
- `top/niunaijun/blackbox/core/system/pm/IBXposedManagerService.aidl`

**Kyun important:** process communication + callback contracts ke bina Vbox-style loader integrations break ho sakte hain.

### 2) MetaCore Java/Kotlin API Surface
- `android/MetaCore/PermissionManager.kt`
- `android/MetaCore/RemoteManager.kt`
- `android/MetaCore/AdvancedPopupHelper.kt`
- `android/MetaCore/Service/MetaActivationService.java`
- `android/MetaCore/db.kt`
- `android/MetaCore/nk.kt`
- `net_62v/external/MetaActivationManager.java`
- `net_62v/external/MetaStorageManager.java`
- `top/niunaijun/blackbox/core/system/api/MetaActivationManager.java`

**Kyun important:** agar aapke loader ya old modules in classes ko directly call karte hain to binary/API parity ke liye ye mandatory ho sakte hain.

### 3) Xposed/Module Management Surface
- `top/niunaijun/blackbox/core/system/pm/BXposedManagerService.java`
- `top/niunaijun/blackbox/fake/frameworks/BXposedManager.java`
- `top/niunaijun/blackbox/entity/pm/InstalledModule.java`
- `top/niunaijun/blackbox/entity/pm/XposedConfig.java`
- `top/niunaijun/blackbox/utils/compat/XposedParserCompat.java`
- `top/niunaijun/blackbox/fake/hook/ReplacePackageNameMethodHook.java`

**Kyun important:** module lifecycle and xposed-related config/import path ke liye.

---

## B) Medium-Priority Missing Items (P2) — Compatibility expansions

### 4) Additional Service Proxies / Vendor / Newer Android wrappers
- `black/android/app/ILocaleManager.java`
- `black/android/bluetooth/IBluetooth.java`
- `black/android/content/integrity/IAppIntegrityManager.java`
- `black/android/content/pm/FrameworkPackageUserState.java`
- `black/android/content/pm/ICrossProfileApps.java`
- `black/android/content/pm/PackageParserTiramisu.java`
- `black/android/os/IDeviceIdleController.java`
- `black/model/vivo/IVivoPermissionService.java`
- `top/niunaijun/blackbox/fake/service/ILocaleManagerProxy.java`
- `top/niunaijun/blackbox/fake/service/vivo/IVivoPermissionServiceProxy.java`

**Kyun important:** ROM/vendor specific behavior aur newer Android service compatibility improve hoti hai.

### 5) Utility Layer Differences
- `top/niunaijun/blackbox/utils/Domen.java`
- `top/niunaijun/blackbox/utils/Qlog.java`

---

## C) Native Hook/Injection Stack Missing (P2/P3)

### 6) Native libraries/components present in Vbox but absent in NewBlackbox
- `And64InlineHook/*`
- `KittyMemory/*`
- `SandHook/*`
- `Substrate/*`
- `esp/*`
- `oxorany*`
- `Utils/PointerCheck.*`, `Utils/fake_dlfcn.*`
- `CMakeLists.txt` (Vbox side native build entry)
- Multi-arch `Dobby/libraries` (includes x86/x86_64 variants)

**Kyun important:** advanced inline/memory hooks, x86/x86_64 support roadmap, and low-level patching flexibility ke liye.

---

## D) One-by-One Add Order (Recommended)

1. **AIDL parity first** (IRemoteManager, IVboxProcessCallback, IBXposedManagerService).
2. **MetaCore API stubs + adapters** add karo (behavior-compatible).
3. **Xposed/module management classes** migrate/adapt karo.
4. **Service proxies/wrappers** (ILocaleManager, Integrity, CrossProfile, vendor services).
5. **Utility layer** (Qlog, Domen) add + map to existing logging/config.
6. **Native stack enhancements** phased flags ke saath (no big-bang merge).

---

## E) Detailed Execution Checklist (per feature)
Har feature add karte time ye template follow karo:
1. Source file parity check (class name, package name, method signatures)
2. Dependency check (kisko call karta hai?)
3. Runtime risk level (Low/Medium/High)
4. Add as adapter or direct port?
5. Unit/instrumentation smoke test
6. Loader integration test
7. Crash/log observation 24h

---

## F) Quick Reality Note
- “Feature file exists” ≠ “feature production ready”.
- Isliye har migrated feature ko **contract test + device matrix test** ke saath validate karna padega.

Agar aap chaho to next step me main is list ko `Phase-1 implementation tickets` me tod dunga (each ticket = file list + dependencies + test case + done criteria).
