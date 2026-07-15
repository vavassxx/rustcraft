@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
:: =============================================================================
:: RustCraft Build System — run-client.bat
:: Builds RustCraft components and launches the Minecraft client.
:: Supports interactive version selection, clean builds, and multi-version builds.
:: =============================================================================

:: ------------------------------------
:: Resolve script directory
:: ------------------------------------
set "SCRIPT_DIR=%~dp0"
:: Remove trailing backslash
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ------------------------------------
:: Flags
:: ------------------------------------
set "MC_VERSION="
set "CLEAN=0"
set "NO_RUN=0"
set "BUILD_ALL=0"
set "INTERACTIVE=1"

:: ------------------------------------
:: Parse arguments
:: ------------------------------------
:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="-v" (
    set "MC_VERSION=%~2"
    set "INTERACTIVE=0"
    shift & shift
    goto parse_args
)
if /I "%~1"=="--version" (
    set "MC_VERSION=%~2"
    set "INTERACTIVE=0"
    shift & shift
    goto parse_args
)
if /I "%~1"=="-c" (
    set "CLEAN=1"
    shift
    goto parse_args
)
if /I "%~1"=="--clean" (
    set "CLEAN=1"
    shift
    goto parse_args
)
if /I "%~1"=="-n" (
    set "NO_RUN=1"
    set "INTERACTIVE=0"
    shift
    goto parse_args
)
if /I "%~1"=="--no-run" (
    set "NO_RUN=1"
    set "INTERACTIVE=0"
    shift
    goto parse_args
)
if /I "%~1"=="-a" (
    set "BUILD_ALL=1"
    set "INTERACTIVE=0"
    shift
    goto parse_args
)
if /I "%~1"=="--build-all" (
    set "BUILD_ALL=1"
    set "INTERACTIVE=0"
    shift
    goto parse_args
)
if /I "%~1"=="-h" goto show_help
if /I "%~1"=="--help" goto show_help
echo [ERROR] Unknown option: %~1
echo Use --help for usage information.
exit /b 1

:args_done

:: ------------------------------------
:: Validate version if provided
:: ------------------------------------
if not "%MC_VERSION%"=="" (
    set "VERSION_FOUND=0"
    if "%MC_VERSION%"=="1.18.2" set "VERSION_FOUND=1"
    if "%MC_VERSION%"=="1.19.4" set "VERSION_FOUND=1"
    if "%MC_VERSION%"=="1.20.1" set "VERSION_FOUND=1"
    if "%MC_VERSION%"=="1.20.4" set "VERSION_FOUND=1"
    if "%MC_VERSION%"=="1.20.6" set "VERSION_FOUND=1"
    if "%MC_VERSION%"=="1.21"   set "VERSION_FOUND=1"
    if "%MC_VERSION%"=="1.21.1" set "VERSION_FOUND=1"
    if "%MC_VERSION%"=="1.21.3" set "VERSION_FOUND=1"
    if "%MC_VERSION%"=="1.21.4" set "VERSION_FOUND=1"
    if "%MC_VERSION%"=="1.21.5" set "VERSION_FOUND=1"
    if !VERSION_FOUND!==0 (
        echo [ERROR] Unknown version: %MC_VERSION%
        echo Supported: 1.18.2 1.19.4 1.20.1 1.20.4 1.20.6 1.21 1.21.1 1.21.3 1.21.4 1.21.5
        exit /b 1
    )
)

:: ------------------------------------
:: Detect JAVA_HOME
:: ------------------------------------
call :detect_java_home

:: ------------------------------------
:: Detect platform
:: ------------------------------------
call :detect_platform

:: ------------------------------------
:: Dispatch
:: ------------------------------------
if %INTERACTIVE%==1 goto interactive_menu
if %BUILD_ALL%==1 goto build_all
call :build_version "%MC_VERSION%" %NO_RUN% %CLEAN%
exit /b !ERRORLEVEL!

:: =============================================================================
:: Interactive menu
:: =============================================================================
:interactive_menu
echo.
echo ==========================================
echo        RustCraft Build System
echo ==========================================
echo.
echo Select Minecraft version:
echo.
echo   [ 1] 1.18.2 (Java 17, Yarn 1.18.2+build.4)
echo   [ 2] 1.19.4 (Java 17, Yarn 1.19.4+build.2)
echo   [ 3] 1.20.1 (Java 17, Yarn 1.20.1+build.10)
echo   [ 4] 1.20.4 (Java 17, Yarn 1.20.4+build.3)
echo   [ 5] 1.20.6 (Java 21, Yarn 1.20.6+build.1)
echo   [ 6] 1.21   (Java 21, Yarn 1.21+build.1)
echo   [ 7] 1.21.1 (Java 21, Yarn 1.21.1+build.3)
echo   [ 8] 1.21.3 (Java 21, Yarn 1.21.3+build.5)
echo   [ 9] 1.21.4 (Java 21, Yarn 1.21.4+build.13)
echo   [10] 1.21.5 (Java 21, Yarn 1.21.5+build.1)
echo.
echo   [A]  Build ALL versions
echo.
set /p "CHOICE=> "

if /I "!CHOICE!"=="A" (
    echo.
    echo [INFO] Building all versions...
    goto build_all
)

:: Map choice to version
set "SEL_VERSION="
if "!CHOICE!"=="1"  set "SEL_VERSION=1.18.2"
if "!CHOICE!"=="2"  set "SEL_VERSION=1.19.4"
if "!CHOICE!"=="3"  set "SEL_VERSION=1.20.1"
if "!CHOICE!"=="4"  set "SEL_VERSION=1.20.4"
if "!CHOICE!"=="5"  set "SEL_VERSION=1.20.6"
if "!CHOICE!"=="6"  set "SEL_VERSION=1.21"
if "!CHOICE!"=="7"  set "SEL_VERSION=1.21.1"
if "!CHOICE!"=="8"  set "SEL_VERSION=1.21.3"
if "!CHOICE!"=="9"  set "SEL_VERSION=1.21.4"
if "!CHOICE!"=="10" set "SEL_VERSION=1.21.5"

if "!SEL_VERSION!"=="" (
    echo [ERROR] Invalid choice: !CHOICE!
    exit /b 1
)

echo [INFO] Selected: Minecraft !SEL_VERSION!
call :build_version "!SEL_VERSION!" 0 0
exit /b !ERRORLEVEL!

:: =============================================================================
:: Build ALL versions
:: =============================================================================
:build_all
set "OUTPUT_BASE=%SCRIPT_DIR%build-versions"
if not exist "%OUTPUT_BASE%" mkdir "%OUTPUT_BASE%"

set "FAIL_COUNT=0"
set "PASS_COUNT=0"
set "FAILED_LIST="

call :build_version "1.18.2" 1 0
if !ERRORLEVEL! neq 0 (set /a FAIL_COUNT+=1 & set "FAILED_LIST=!FAILED_LIST! 1.18.2") else (set /a PASS_COUNT+=1)

call :build_version "1.19.4" 1 0
if !ERRORLEVEL! neq 0 (set /a FAIL_COUNT+=1 & set "FAILED_LIST=!FAILED_LIST! 1.19.4") else (set /a PASS_COUNT+=1)

call :build_version "1.20.1" 1 0
if !ERRORLEVEL! neq 0 (set /a FAIL_COUNT+=1 & set "FAILED_LIST=!FAILED_LIST! 1.20.1") else (set /a PASS_COUNT+=1)

call :build_version "1.20.4" 1 0
if !ERRORLEVEL! neq 0 (set /a FAIL_COUNT+=1 & set "FAILED_LIST=!FAILED_LIST! 1.20.4") else (set /a PASS_COUNT+=1)

call :build_version "1.20.6" 1 0
if !ERRORLEVEL! neq 0 (set /a FAIL_COUNT+=1 & set "FAILED_LIST=!FAILED_LIST! 1.20.6") else (set /a PASS_COUNT+=1)

call :build_version "1.21"   1 0
if !ERRORLEVEL! neq 0 (set /a FAIL_COUNT+=1 & set "FAILED_LIST=!FAILED_LIST! 1.21")   else (set /a PASS_COUNT+=1)

call :build_version "1.21.1" 1 0
if !ERRORLEVEL! neq 0 (set /a FAIL_COUNT+=1 & set "FAILED_LIST=!FAILED_LIST! 1.21.1") else (set /a PASS_COUNT+=1)

call :build_version "1.21.3" 1 0
if !ERRORLEVEL! neq 0 (set /a FAIL_COUNT+=1 & set "FAILED_LIST=!FAILED_LIST! 1.21.3") else (set /a PASS_COUNT+=1)

call :build_version "1.21.4" 1 0
if !ERRORLEVEL! neq 0 (set /a FAIL_COUNT+=1 & set "FAILED_LIST=!FAILED_LIST! 1.21.4") else (set /a PASS_COUNT+=1)

call :build_version "1.21.5" 1 0
if !ERRORLEVEL! neq 0 (set /a FAIL_COUNT+=1 & set "FAILED_LIST=!FAILED_LIST! 1.21.5") else (set /a PASS_COUNT+=1)

echo.
echo ==========================================
echo          Build Summary
echo ==========================================
echo   Passed: %PASS_COUNT%
echo   Failed: %FAIL_COUNT%
if not "%FAILED_LIST%"=="" echo   Failed versions:%FAILED_LIST%
echo ==========================================
if %FAIL_COUNT% gtr 0 exit /b 1
exit /b 0

:: =============================================================================
:: Version lookup tables (called as subroutines)
:: =============================================================================
:get_version_info
:: Input: %~1 = MC_VERSION
:: Output: sets YARN_MAP, FAB_LOADER, JAVA_TGT
set "YARN_MAP="
set "FAB_LOADER="
set "JAVA_TGT="

if "%~1"=="1.18.2" (set "YARN_MAP=1.18.2+build.4"    & set "FAB_LOADER=0.14.21" & set "JAVA_TGT=17")
if "%~1"=="1.19.4" (set "YARN_MAP=1.19.4+build.2"    & set "FAB_LOADER=0.14.21" & set "JAVA_TGT=17")
if "%~1"=="1.20.1" (set "YARN_MAP=1.20.1+build.10"   & set "FAB_LOADER=0.14.21" & set "JAVA_TGT=17")
if "%~1"=="1.20.4" (set "YARN_MAP=1.20.4+build.3"    & set "FAB_LOADER=0.15.11" & set "JAVA_TGT=17")
if "%~1"=="1.20.6" (set "YARN_MAP=1.20.6+build.1"    & set "FAB_LOADER=0.15.11" & set "JAVA_TGT=21")
if "%~1"=="1.21"   (set "YARN_MAP=1.21+build.1"      & set "FAB_LOADER=0.16.0"  & set "JAVA_TGT=21")
if "%~1"=="1.21.1" (set "YARN_MAP=1.21.1+build.3"    & set "FAB_LOADER=0.16.1"  & set "JAVA_TGT=21")
if "%~1"=="1.21.3" (set "YARN_MAP=1.21.3+build.5"    & set "FAB_LOADER=0.16.7"  & set "JAVA_TGT=21")
if "%~1"=="1.21.4" (set "YARN_MAP=1.21.4+build.13"   & set "FAB_LOADER=0.16.9"  & set "JAVA_TGT=21")
if "%~1"=="1.21.5" (set "YARN_MAP=1.21.5+build.1"    & set "FAB_LOADER=0.16.10" & set "JAVA_TGT=21")
goto :eof

:: =============================================================================
:: JAVA_HOME detection
:: =============================================================================
:detect_java_home
echo [INFO] Detecting JAVA_HOME...

:: 1. Check %JAVA_HOME%
if defined JAVA_HOME (
    if exist "%JAVA_HOME%" (
        echo [OK]      Using JAVA_HOME from environment: %JAVA_HOME%
        goto :eof
    )
)

:: 2. Try java in PATH
where java >nul 2>&1
if %ERRORLEVEL% equ 0 (
    for /f "tokens=*" %%i in ('java -XshowSettings:properties 2^>^&1 ^| findstr "java.home"') do (
        set "JAVA_LINE=%%i"
    )
    if defined JAVA_LINE (
        for %%j in ("!JAVA_LINE!") do set "JAVA_HOME=%%~nj"
    )
    if not defined JAVA_HOME (
        for /f "tokens=*" %%i in ('where java') do (
            set "JAVA_BIN=%%i"
            goto :found_java_bin
        )
        :found_java_bin
        for %%j in ("!JAVA_BIN!") do (
            set "JAVA_HOME=%%~dpj.."
        )
    )
    if defined JAVA_HOME (
        echo [OK]      Detected JAVA_HOME from java binary: !JAVA_HOME!
        goto :eof
    )
)

:: 3. Check common Windows paths
if exist "C:\Program Files\Java\jdk-21"    (set "JAVA_HOME=C:\Program Files\Java\jdk-21"    & echo [OK]      Detected JAVA_HOME: C:\Program Files\Java\jdk-21    & goto :eof)
if exist "C:\Program Files\Java\jdk-17"    (set "JAVA_HOME=C:\Program Files\Java\jdk-17"    & echo [OK]      Detected JAVA_HOME: C:\Program Files\Java\jdk-17    & goto :eof)
if exist "C:\Program Files\Eclipse Adoptium\jdk-21" (set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21" & echo [OK]      Detected JAVA_HOME: C:\Program Files\Eclipse Adoptium\jdk-21 & goto :eof)
if exist "C:\Program Files\Eclipse Adoptium\jdk-17" (set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17" & echo [OK]      Detected JAVA_HOME: C:\Program Files\Eclipse Adoptium\jdk-17 & goto :eof)

echo [WARN] JAVA_HOME not found. Gradle will attempt to auto-detect.
goto :eof

:: =============================================================================
:: Platform detection
:: =============================================================================
:detect_platform
echo [INFO] Detecting platform...
set "NATIVE_LIB_EXT=dll"
set "NATIVE_LIB_PREFIX="
echo [OK]      Platform: windows (x86_64)
echo [OK]      Native lib: rustcraft_core.dll
goto :eof

:: =============================================================================
:: gradle.properties patching
:: =============================================================================
:patch_gradle_properties
:: Args: %~1 = file, %~2 = mc_version, %~3 = yarn, %~4 = fabric_loader
set "PROP_FILE=%~1"
set "PROP_MC=%~2"
set "PROP_YARN=%~3"
set "PROP_FAB=%~4"

if not exist "%PROP_FILE%" (
    echo [WARN] gradle.properties not found: %PROP_FILE% — skipping
    goto :eof
)

echo [INFO] Patching %PROP_FILE%

:: Use PowerShell for reliable property patching
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$f='%PROP_FILE%'; $props=@{'minecraft_version'='%PROP_MC%';'yarn_mappings'='%PROP_YARN%';'loader_version'='%PROP_FAB%'}; $content=Get-Content $f -Raw; foreach($k in $props.Keys){if($content -match ('^'+$k+'=.*$')){$content=$content -replace ('^'+$k+'=.*$'),($k+'='+$props[$k])}else{$content=$content+\"`r`n\"+($k+'='+$props[$k])}}; Set-Content $f $content -NoNewline"

if !ERRORLEVEL! neq 0 (
    echo [ERROR] Failed to patch %PROP_FILE%
    exit /b 1
)

echo [OK]      Patched: minecraft_version=%PROP_MC%, yarn_mappings=%PROP_YARN%, loader_version=%PROP_FAB%
goto :eof

:: =============================================================================
:: Full build pipeline for a single version
:: Args: %~1 = MC_VERSION, %~2 = NO_RUN, %~3 = CLEAN
:: =============================================================================
:build_version
set "BV_MC=%~1"
set "BV_NO_RUN=%~2"
set "BV_CLEAN=%~3"

:: Look up version info
call :get_version_info "%BV_MC%"

if "%YARN_MAP%"=="" (
    echo [ERROR] Unknown version: %BV_MC%
    exit /b 1
)

echo.
echo ==========================================
echo   Building for Minecraft %BV_MC%
echo   Yarn: %YARN_MAP%
echo   Fabric Loader: %FAB_LOADER%
echo   Java Target: %JAVA_TGT%
echo ==========================================

:: Step 1: Patch gradle.properties
echo.
echo [INFO] Step 1/6: Patching gradle.properties
call :patch_gradle_properties "%SCRIPT_DIR%\fabric-loader\gradle.properties" "%BV_MC%" "%YARN_MAP%" "%FAB_LOADER%"
if !ERRORLEVEL! neq 0 (echo [ERROR] Failed at step 1: gradle.properties patching & exit /b 1)

call :patch_gradle_properties "%SCRIPT_DIR%\example-mod\wrapper\gradle.properties" "%BV_MC%" "%YARN_MAP%" "%FAB_LOADER%"
if !ERRORLEVEL! neq 0 (echo [ERROR] Failed at step 1: gradle.properties patching & exit /b 1)

:: Step 2: Build rustcraft-core
echo.
echo [INFO] Step 2/6: Building rustcraft-core
if %BV_CLEAN%==1 (
    echo [INFO] Running cargo clean for rust-sdk...
    pushd "%SCRIPT_DIR%\rust-sdk" >nul
    cargo clean --release 2>nul
    popd >nul
)
pushd "%SCRIPT_DIR%\rust-sdk" >nul
cargo build --release -p rustcraft-core
if !ERRORLEVEL! neq 0 (popd >nul & echo [ERROR] Failed at step 2: rustcraft-core build & exit /b 1)
popd >nul
echo [OK]      rustcraft-core built successfully

:: Step 3: Build example-mod
echo.
echo [INFO] Step 3/6: Building example-mod
if %BV_CLEAN%==1 (
    echo [INFO] Running cargo clean for example-mod...
    pushd "%SCRIPT_DIR%\example-mod" >nul
    cargo clean --release 2>nul
    popd >nul
)
pushd "%SCRIPT_DIR%\example-mod" >nul
cargo build --release
if !ERRORLEVEL! neq 0 (popd >nul & echo [ERROR] Failed at step 3: example-mod build & exit /b 1)
popd >nul
echo [OK]      example-mod built successfully

:: Step 4: Build fabric-loader
echo.
echo [INFO] Step 4/6: Building fabric-loader
pushd "%SCRIPT_DIR%\fabric-loader" >nul
if %BV_CLEAN%==1 (
    call .\gradlew clean build
) else (
    call .\gradlew build
)
if !ERRORLEVEL! neq 0 (popd >nul & echo [ERROR] Failed at step 4: fabric-loader build & exit /b 1)
popd >nul
echo [OK]      fabric-loader built successfully

:: Step 5: Build example-mod wrapper
echo.
echo [INFO] Step 5/6: Building example-mod wrapper
pushd "%SCRIPT_DIR%\example-mod\wrapper" >nul
if %BV_CLEAN%==1 (
    call .\gradlew clean build
) else (
    call .\gradlew build
)
if !ERRORLEVEL! neq 0 (popd >nul & echo [ERROR] Failed at step 5: example-mod wrapper build & exit /b 1)
popd >nul
echo [OK]      example-mod wrapper built successfully

:: Step 6: Copy JARs
echo.
echo [INFO] Step 6/6: Copying JARs

set "MODS_DIR=%SCRIPT_DIR%\fabric-loader\run\mods"
if not exist "%MODS_DIR%" mkdir "%MODS_DIR%"

:: Copy fabric-loader JAR
for %%f in ("%SCRIPT_DIR%\fabric-loader\build\libs\*.jar") do (
    set "FJAR_NAME=%%~nxf"
    echo !FJAR_NAME! | findstr /I "sources javadoc" >nul
    if errorlevel 1 (
        copy "%%f" "%MODS_DIR%\" >nul
        echo [OK]      Copied fabric-loader JAR: %%~nxf
        goto :copied_fabric
    )
)
:copied_fabric

:: Copy example-mod wrapper JAR
for %%f in ("%SCRIPT_DIR%\example-mod\wrapper\build\libs\*.jar") do (
    set "WJAR_NAME=%%~nxf"
    echo !WJAR_NAME! | findstr /I "sources javadoc" >nul
    if errorlevel 1 (
        copy "%%f" "%MODS_DIR%\" >nul
        echo [OK]      Copied example-mod wrapper JAR: %%~nxf
        goto :copied_wrapper
    )
)
:copied_wrapper

:: Copy modmenu if available
if exist "%SCRIPT_DIR%\mods\modmenu-3.2.3.jar" (
    copy "%SCRIPT_DIR%\mods\modmenu-3.2.3.jar" "%MODS_DIR%\" >nul
    echo [OK]      Copied modmenu-3.2.3.jar
    goto :copied_modmenu
)
echo [WARN] modmenu-3.2.3.jar not found — skipping
:copied_modmenu

echo [OK]      JARs copied to %MODS_DIR%

:: Step 7: Run client (unless --no-run)
if %BV_NO_RUN%==0 (
    echo.
    echo [INFO] Launching Minecraft client
    echo [INFO] Running: gradlew runClient
    pushd "%SCRIPT_DIR%\fabric-loader" >nul
    call .\gradlew runClient
    if !ERRORLEVEL! neq 0 (
        popd >nul
        echo [ERROR] Failed to launch client for Minecraft %BV_MC%
        exit /b 1
    )
    popd >nul
)

echo.
echo [OK] Build complete for Minecraft %BV_MC%
exit /b 0

:: =============================================================================
:: Help
:: =============================================================================
:show_help
echo RustCraft Build System
echo.
echo Usage:
echo   run-client.bat [OPTIONS]
echo.
echo Options:
echo   -v, --version ^<MC_VERSION^>   Select Minecraft version (e.g. 1.21.4^)
echo   -c, --clean                  Clean build (cargo clean + gradlew clean^)
echo   -n, --no-run                 Build only, don't launch client
echo   -a, --build-all              Build for ALL versions (output to build-versions\^<mc_version^>^)
echo   -h, --help                   Show this help message
echo.
echo Examples:
echo   run-client.bat                        Interactive menu
echo   run-client.bat -v 1.21.4              Build and run for 1.21.4
echo   run-client.bat -v 1.21.4 --clean      Clean build for 1.21.4
echo   run-client.bat --build-all            Build all versions
echo   run-client.bat -a -n                  Build all versions, don't run
exit /b 0
