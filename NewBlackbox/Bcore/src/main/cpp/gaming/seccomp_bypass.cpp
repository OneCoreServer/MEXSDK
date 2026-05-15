#include <android/log.h>
#include <errno.h>
#include <sys/prctl.h>

#if __has_include(<linux/seccomp.h>)
#include <linux/seccomp.h>
#endif

#define SLOGI(...) __android_log_print(ANDROID_LOG_INFO, "SeccompBypass", __VA_ARGS__)

#ifndef SECCOMP_MODE_DISABLED
#define SECCOMP_MODE_DISABLED 0
#endif

bool init_seccomp_bypass() {
#ifdef PR_SET_SECCOMP
    errno = 0;
    int ret = prctl(PR_SET_SECCOMP, SECCOMP_MODE_DISABLED, 0, 0, 0);
    if (ret == 0) {
        SLOGI("prctl(PR_SET_SECCOMP, DISABLED) succeeded");
        return true;
    }
    SLOGI("prctl(PR_SET_SECCOMP, DISABLED) failed, errno=%d", errno);
    return false;
#else
    SLOGI("PR_SET_SECCOMP not supported on this build");
    return false;
#endif
}
