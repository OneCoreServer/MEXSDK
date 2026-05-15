#include <dlfcn.h>
#include <android/log.h>
#include <string>
#include <sys/stat.h>

#define GLOGE(...) __android_log_print(ANDROID_LOG_ERROR, "GamingLoader", __VA_ARGS__)
#define GLOGI(...) __android_log_print(ANDROID_LOG_INFO, "GamingLoader", __VA_ARGS__)

static bool file_exists(const std::string &path) {
    struct stat st{};
    return stat(path.c_str(), &st) == 0;
}

bool loadGameLib(const std::string &packageName) {
    std::string libPath = "/data/data/" + packageName + "/files/loader/libbgmi.so";
    if (!file_exists(libPath)) {
        GLOGI("Game library not present: %s", libPath.c_str());
        return false;
    }
    void *handle = dlopen(libPath.c_str(), RTLD_NOW);
    if (handle == nullptr) {
        GLOGE("dlopen failed for %s : %s", libPath.c_str(), dlerror());
        return false;
    }
    GLOGI("Loaded game library: %s", libPath.c_str());
    return true;
}
