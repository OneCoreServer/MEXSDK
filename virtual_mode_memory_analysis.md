# Virtual Mode Memory Architecture Notes

Key locations:
- `reference_sdk/Open-Sdk-Zcore/Zcore-sdk/src/main/cpp/KittyMemory/KittyMemory.h/.cpp`
- `reference_sdk/Open-Sdk-Zcore/Zcore-sdk/src/main/cpp/oxorany/Tools.h/.cpp`
- `NewBlackbox/Bcore/src/main/java/top/niunaijun/blackbox/core/NativeCore.java`

Summary:
- Address translation is implemented as **module-relative offset -> absolute process address** using `/proc/self/maps`.
- No explicit functions named `VirtualAddressToNativeAddress` / `NativeAddressToVirtualAddress` were found.
- Memory read/write is done through custom wrappers over `memcpy`, `mprotect`, and Linux `process_vm_readv` / `process_vm_writev` syscalls.
- Module base is resolved by parsing `/proc/self/maps` (equivalent role to `GetModuleHandle(NULL)` style base lookup).
