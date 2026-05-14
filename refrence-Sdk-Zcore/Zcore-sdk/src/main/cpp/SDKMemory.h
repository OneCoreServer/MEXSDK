#pragma once

#include <cstdint>

namespace SDK {
namespace Memory {

    // ========== MODE DETECTION ==========
    enum class EMode {
        Normal,     // Direct memory access
        Virtual     // Virtual Blackbox isolated mode
    };

    inline EMode& GetMode() {
        static EMode mode = EMode::Normal;
        return mode;
    }

    inline void SetMode(EMode mode) {
        GetMode() = mode;
    }

    inline bool IsVirtualMode() {
        return GetMode() == EMode::Virtual;
    }

    // ========== VIRTUAL API FORWARD DECLARATIONS ==========
    namespace Virtual {
        void* ReadPtr(void* address);
        template<typename T> T Read(void* address);
        template<typename T> void Write(void* address, T value);
        uintptr_t GetModuleBase(const char* moduleName);
    }

    // ========== UNIFIED READ/WRITE ==========
    template<typename T>
    inline T Read(void* address) {
        if (IsVirtualMode()) {
            return Virtual::Read<T>(address);
        }
        return *reinterpret_cast<T*>(address);
    }

    template<typename T>
    inline void Write(void* address, T value) {
        if (IsVirtualMode()) {
            Virtual::Write<T>(address, value);
            return;
        }
        *reinterpret_cast<T*>(address) = value;
    }

    inline void* ReadPtr(void* address) {
        if (IsVirtualMode()) {
            return Virtual::ReadPtr(address);
        }
        return *reinterpret_cast<void**>(address);
    }

    // ========== POINTER ARITHMETIC HELPERS ==========
    template<typename T>
    inline T* Ptr(uintptr_t address) {
        return reinterpret_cast<T*>(address);
    }

    // Safe dereference - returns null if invalid
    template<typename T>
    inline T* SafeDeref(void* address) {
        if (!address) return nullptr;
        if (IsVirtualMode()) {
            // Virtual mode mein validation SDK ki API se
            return Virtual::Read<T*>(address);
        }
        return *reinterpret_cast<T**>(address);
    }

} // namespace Memory
} // namespace SDK
