#include <jni.h>
#include <string>

extern bool loadGameLib(const std::string &packageName);
extern bool init_seccomp_bypass();

extern "C" jboolean nativeLoadGameLib(JNIEnv *env, jclass, jstring packageName) {
    const char *pkg = env->GetStringUTFChars(packageName, JNI_FALSE);
    bool ok = loadGameLib(pkg);
    env->ReleaseStringUTFChars(packageName, pkg);
    return ok ? JNI_TRUE : JNI_FALSE;
}

extern "C" jboolean nativeInitSeccompBypass(JNIEnv *, jclass) {
    return init_seccomp_bypass() ? JNI_TRUE : JNI_FALSE;
}

extern "C" jstring Java_com_yoursdk_ActivateSdkLog(JNIEnv *env, jclass) {
    return env->NewStringUTF("https://akshit.dynamicflash.xyz/api/connect.php");
}
