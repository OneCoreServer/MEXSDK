# Import Gap Audit (Newly Imported Vbox Files)

## User question
"Saare imports add hue ya nahi?"

## What I checked
I scanned all Java/Kotlin files added in the last commit and verified whether imported project-local classes exist physically under `NewBlackbox/Bcore/src/main/java`.

## Result
### 1) No hard missing for standard libs/deps
- Android/AndroidX/Java/Kotlin imports are normal.
- `zip4j` usage (`net.lingala.zip4j.ZipFile`) is already declared in `Bcore/build.gradle`.

### 2) Potentially missing project-local imports found
These imports currently do not have matching source files in `Bcore/src/main/java`:

- `black.android.content.BRAttributionSource`
- `black.android.app.BRILocaleManager`
- `black.android.app.BRILocaleManagerStub`
- `black.android.os.BRServiceManager`
- `black.model.vivo.BRIVivoPermissionServiceStub`
- `black.model.vivo.IVivoPermissionServiceContext`
- `top.niunaijun.blackbox.core.system.pm.IBXposedManagerService` *(expected to be generated from AIDL)*

## Important note
Many `BR*` classes in this codebase are usually reflection/generated wrappers. They may be produced during annotation/reflection codegen and therefore may not exist as handwritten sources.

## Next safe step
1. Run full Gradle build with codegen enabled.
2. If unresolved symbols remain, then:
   - import/copy missing generated wrapper sources from the same toolchain output, OR
   - add compatible wrapper declarations in `black/...` packages.

## Why this file
This gives you a concrete checklist of "abhi kya missing lag raha hai" before integrating more features.
