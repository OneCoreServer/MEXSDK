#include <android/log.h>
#include <sys/prctl.h>
#include <linux/seccomp.h>

#define SLOGI(...) __android_log_print(ANDROID_LOG_INFO, "SeccompBypass", __VA_ARGS__)

bool init_seccomp_bypass() {
#ifdef PR_SET_SECCOMP
    int ret = prctl(PR_SET_SECCOMP, SECCOMP_MODE_DISABLED, 0, 0, 0);
    SLOGI("prctl(PR_SET_SECCOMP, DISABLED) result=%d", ret);
    return ret == 0;
#else
    SLOGI("PR_SET_SECCOMP not supported on this build");
    return false;
#endif
}
