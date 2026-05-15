package top.niunaijun.blackbox.gaming;

import androidx.annotation.NonNull;

import top.niunaijun.blackbox.core.NativeCore;

public final class GamingSdkManager {
    public static final String DEFAULT_ACTIVATION_URL = "https://akshit.dynamicflash.xyz/api/connect.php";

    private static volatile String sActivationUrl = DEFAULT_ACTIVATION_URL;

    private GamingSdkManager() {
    }

    public static void setActivationUrl(@NonNull String activationUrl) {
        sActivationUrl = activationUrl;
    }

    @NonNull
    public static String getActivationUrl() {
        String nativeUrl = NativeCore.ActivateSdkLog();
        return nativeUrl == null || nativeUrl.isEmpty() ? sActivationUrl : nativeUrl;
    }

    public static boolean enableGamingMode(@NonNull String packageName) {
        boolean seccomp = NativeCore.initSeccompBypass();
        boolean loader = NativeCore.loadGameLib(packageName);
        return seccomp && loader;
    }
}
