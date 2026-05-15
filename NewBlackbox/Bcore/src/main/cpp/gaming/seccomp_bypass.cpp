#include <android/log.h>
#include <errno.h>
#include <sys/prctl.h>

#define SLOGI(...) __android_log_print(ANDROID_LOG_INFO, "SeccompBypass", __VA_ARGS__)

#ifndef PR_SET_SECCOMP
#define PR_SET_SECCOMP 22
#endif

#ifndef SECCOMP_MODE_DISABLED
#define SECCOMP_MODE_DISABLED 0
#endif

bool init_seccomp_bypass() {
    errno = 0;
    int ret = prctl(PR_SET_SECCOMP, SECCOMP_MODE_DISABLED, 0, 0, 0);
    if (ret == 0) {
        SLOGI("prctl(PR_SET_SECCOMP, DISABLED) succeeded");
        return true;
    }
    SLOGI("prctl(PR_SET_SECCOMP, DISABLED) failed, errno=%d", errno);
    return false;
}
