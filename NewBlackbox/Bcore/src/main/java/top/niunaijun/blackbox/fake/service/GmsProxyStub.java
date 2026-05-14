package top.niunaijun.blackbox.fake.service;

import android.content.Context;
import java.lang.reflect.Method;
import top.niunaijun.blackbox.fake.hook.ClassInvocationStub;
import top.niunaijun.blackbox.fake.hook.MethodHook;
import top.niunaijun.blackbox.fake.hook.ProxyMethod;

/**
 * GMS availability को फोर्स करने के लिए Stub
 */
public class GmsProxyStub extends ClassInvocationStub {
    public static final String GMS_PACKAGE = "com.google.android.gms";

    @Override
    protected Object getWho() {
        // यहाँ हम GoogleApiAvailability के इंटरनल क्लास को टारगेट करते हैं
        return null; 
    }

    @Override
    protected void inject(Object base, Object proxy) { }

    @Override
    public boolean isBadEnv() { return false; }

    @ProxyMethod("isGooglePlayServicesAvailable")
    public static class IsGooglePlayServicesAvailable extends MethodHook {
        @Override
        protected Object hook(Object who, Method method, Object[] args) throws Throwable {
            // 0 का मतलब है ConnectionResult.SUCCESS
            return 0; 
        }
    }
}
