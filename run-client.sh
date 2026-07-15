#!/usr/bin/env bash
# =============================================================================
# RustCraft Build System — run-client.sh
# Builds RustCraft components and launches the Minecraft client.
# Supports interactive version selection, clean builds, and multi-version builds.
# =============================================================================
set -euo pipefail

# ------------------------------------
# Resolve script directory (symlink-safe)
# ------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# ------------------------------------
# Version table
# Format: MC_VERSION : YARN_MAPPINGS : FABRIC_LOADER : JAVA_TARGET
# ------------------------------------
declare -a MC_VERSIONS=(
    "1.18.2"
    "1.19.4"
    "1.20.1"
    "1.20.4"
    "1.20.6"
    "1.21"
    "1.21.1"
    "1.21.3"
    "1.21.4"
    "1.21.5"
)

declare -A YARN_MAPPINGS=(
    ["1.18.2"]="1.18.2+build.4"
    ["1.19.4"]="1.19.4+build.2"
    ["1.20.1"]="1.20.1+build.10"
    ["1.20.4"]="1.20.4+build.3"
    ["1.20.6"]="1.20.6+build.1"
    ["1.21"]="1.21+build.1"
    ["1.21.1"]="1.21.1+build.3"
    ["1.21.3"]="1.21.3+build.5"
    ["1.21.4"]="1.21.4+build.13"
    ["1.21.5"]="1.21.5+build.1"
)

declare -A FABRIC_LOADERS=(
    ["1.18.2"]="0.14.21"
    ["1.19.4"]="0.14.21"
    ["1.20.1"]="0.14.21"
    ["1.20.4"]="0.15.11"
    ["1.20.6"]="0.15.11"
    ["1.21"]="0.16.0"
    ["1.21.1"]="0.16.1"
    ["1.21.3"]="0.16.7"
    ["1.21.4"]="0.16.9"
    ["1.21.5"]="0.16.10"
)

declare -A JAVA_TARGETS=(
    ["1.18.2"]="17"
    ["1.19.4"]="17"
    ["1.20.1"]="17"
    ["1.20.4"]="17"
    ["1.20.6"]="21"
    ["1.21"]="21"
    ["1.21.1"]="21"
    ["1.21.3"]="21"
    ["1.21.4"]="21"
    ["1.21.5"]="21"
)

# ------------------------------------
# Colors and formatting
# ------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ------------------------------------
# Utility functions
# ------------------------------------
info()    { echo -e "${BLUE}[INFO]${NC}    $*"; }
success() { echo -e "${GREEN}[OK]${NC}      $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; }
error()   { echo -e "${RED}[ERROR]${NC}   $*"; }
step()    { echo -e "\n${CYAN}${BOLD}>>> $*${NC}"; }

die() {
    error "$*"
    exit 1
}

usage() {
    cat <<'EOF'
RustCraft Build System

Usage:
  ./run-client.sh [OPTIONS]

Options:
  -v, --version <MC_VERSION>   Select Minecraft version (e.g. 1.21.4)
  -c, --clean                  Clean build (cargo clean + gradlew clean)
  -n, --no-run                 Build only, don't launch client
  -a, --build-all              Build for ALL versions (output to build-versions/<mc_version>/)
  -h, --help                   Show this help message

Examples:
  ./run-client.sh                        # Interactive menu
  ./run-client.sh -v 1.21.4              # Build and run for 1.21.4
  ./run-client.sh -v 1.21.4 --clean      # Clean build for 1.21.4
  ./run-client.sh --build-all            # Build all versions
  ./run-client.sh -a -n                  # Build all versions, don't run
EOF
}

# ------------------------------------
# Platform detection
# ------------------------------------
detect_platform() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    case "$OS" in
        Linux*)  PLATFORM="linux"  ;;
        Darwin*) PLATFORM="macos"  ;;
        *)       die "Unsupported OS: $OS" ;;
    esac

    case "$ARCH" in
        x86_64|amd64)  PLATFORM_ARCH="x86_64"  ;;
        aarch64|arm64)  PLATFORM_ARCH="aarch64"  ;;
        *)              die "Unsupported architecture: $ARCH" ;;
    esac

    # Determine native library extension and prefix
    case "$PLATFORM" in
        linux)
            NATIVE_LIB_EXT="so"
            NATIVE_LIB_PREFIX="lib"
            ;;
        macos)
            NATIVE_LIB_EXT="dylib"
            NATIVE_LIB_PREFIX="lib"
            ;;
    esac

    info "Platform: ${PLATFORM} (${PLATFORM_ARCH})"
    info "Native lib: ${NATIVE_LIB_PREFIX}rustcraft_core.${NATIVE_LIB_EXT}"
}

# ------------------------------------
# JAVA_HOME detection
# ------------------------------------
detect_java_home() {
    step "Detecting JAVA_HOME"

    # 1. Check $JAVA_HOME env var
    if [[ -n "${JAVA_HOME:-}" ]] && [[ -d "$JAVA_HOME" ]]; then
        success "Using JAVA_HOME from environment: $JAVA_HOME"
        return 0
    fi

    # 2. Try to find java in PATH
    if command -v java &>/dev/null; then
        local java_path
        java_path="$(command -v java)"
        local detected_home
        detected_home="$(java -XshowSettings:properties 2>&1 | grep 'java.home' | awk '{print $NF}' | sed 's|/jre$||')"

        if [[ -n "$detected_home" ]] && [[ -d "$detected_home" ]]; then
            export JAVA_HOME="$detected_home"
            success "Detected JAVA_HOME from java binary: $JAVA_HOME"
            return 0
        fi

        # Fallback: resolve from java binary location
        local bin_dir
        bin_dir="$(dirname "$(readlink -f "$java_path")")"
        local detected_home2
        detected_home2="$(dirname "$bin_dir")"

        if [[ -d "$detected_home2" ]]; then
            export JAVA_HOME="$detected_home2"
            success "Detected JAVA_HOME from java binary path: $JAVA_HOME"
            return 0
        fi
    fi

    # 3. Check common paths
    local common_paths=(
        "$HOME/.local/share/PrismLauncher/java/java-runtime-gamma"
        "$HOME/.local/share/PrismLauncher/java/java-runtime-quilt"
        "/usr/lib/jvm/java-21-openjdk"
        "/usr/lib/jvm/java-17-openjdk"
        "/usr/lib/jvm/java-21-openjdk-amd64"
        "/usr/lib/jvm/java-17-openjdk-amd64"
        "/usr/lib/jvm/java-21"
        "/usr/lib/jvm/java-17"
        "/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home"
        "/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home"
    )

    for p in "${common_paths[@]}"; do
        if [[ -d "$p" ]]; then
            export JAVA_HOME="$p"
            success "Detected JAVA_HOME from common path: $JAVA_HOME"
            return 0
        fi
    done

    warn "JAVA_HOME not found. Gradle will attempt to auto-detect."
    warn "Set JAVA_HOME manually if builds fail."
    return 0
}

# ------------------------------------
# gradle.properties patching
# ------------------------------------
patch_gradle_properties() {
    local mc_version="$1"
    local yarn_mappings="$2"
    local fabric_loader="$3"
    local target_file="$4"

    if [[ ! -f "$target_file" ]]; then
        warn "gradle.properties not found: $target_file — skipping"
        return 0
    fi

    info "Patching $target_file"

    # Use sed to update or append each property
    local props=(
        "minecraft_version=$mc_version"
        "yarn_mappings=$yarn_mappings"
        "loader_version=$fabric_loader"
    )

    for prop in "${props[@]}"; do
        local key="${prop%%=*}"
        local value="${prop#*=}"

        if grep -q "^${key}=" "$target_file" 2>/dev/null; then
            sed -i "s|^${key}=.*|${key}=${value}|" "$target_file"
        else
            echo "${key}=${value}" >> "$target_file"
        fi
    done

    success "Patched: minecraft_version=$mc_version, yarn_mappings=$yarn_mappings, loader_version=$fabric_loader"
}

# ------------------------------------
# Build: rustcraft-core
# ------------------------------------
build_rustcraft_core() {
    local clean="$1"
    step "Building rustcraft-core (Rust cdylib)"

    local cargo_args=("--release" "-p" "rustcraft-core")
    if [[ "$clean" == "true" ]]; then
        info "Running cargo clean for rust-sdk..."
        cargo clean --release 2>/dev/null || true
    fi

    info "Running: cargo build ${cargo_args[*]}"
    if ! cargo build "${cargo_args[@]}" 2>&1; then
        die "Failed to build rustcraft-core"
    fi

    success "rustcraft-core built successfully"
}

# Check this is in rust-sdk directory
# The cargo build for rustcraft-core runs from rust-sdk/ but cargo.toml is there
build_rustcraft_core_in_dir() {
    local clean="$1"
    local rust_sdk_dir="$SCRIPT_DIR/rust-sdk"

    if [[ ! -d "$rust_sdk_dir" ]]; then
        die "rust-sdk directory not found at $rust_sdk_dir"
    fi

    step "Building rustcraft-core (Rust cdylib)"

    if [[ "$clean" == "true" ]]; then
        info "Running cargo clean for rust-sdk..."
        (cd "$rust_sdk_dir" && cargo clean --release) 2>/dev/null || true
    fi

    info "Running: cargo build --release -p rustcraft-core"
    if ! (cd "$rust_sdk_dir" && cargo build --release -p rustcraft-core) 2>&1; then
        die "Failed to build rustcraft-core"
    fi

    success "rustcraft-core built successfully"
}

# ------------------------------------
# Build: example-mod (Rust cdylib)
# ------------------------------------
build_example_mod() {
    local clean="$1"
    local example_mod_dir="$SCRIPT_DIR/example-mod"

    if [[ ! -d "$example_mod_dir" ]]; then
        die "example-mod directory not found at $example_mod_dir"
    fi

    step "Building example-mod (Rust cdylib)"

    if [[ "$clean" == "true" ]]; then
        info "Running cargo clean for example-mod..."
        (cd "$example_mod_dir" && cargo clean --release) 2>/dev/null || true
    fi

    info "Running: cargo build --release"
    if ! (cd "$example_mod_dir" && cargo build --release) 2>&1; then
        die "Failed to build example-mod"
    fi

    success "example-mod built successfully"
}

# ------------------------------------
# Build: fabric-loader (Gradle/Fabric Loom)
# ------------------------------------
build_fabric_loader() {
    local clean="$1"
    local fabric_loader_dir="$SCRIPT_DIR/fabric-loader"

    if [[ ! -d "$fabric_loader_dir" ]]; then
        die "fabric-loader directory not found at $fabric_loader_dir"
    fi

    step "Building fabric-loader (Gradle/Fabric Loom)"

    local gradle_cmd=("./gradlew" "build")
    if [[ "$clean" == "true" ]]; then
        gradle_cmd=("./gradlew" "clean" "build")
    fi

    info "Running: ${gradle_cmd[*]}"
    if ! (cd "$fabric_loader_dir" && "${gradle_cmd[@]}") 2>&1; then
        die "Failed to build fabric-loader"
    fi

    success "fabric-loader built successfully"
}

# ------------------------------------
# Build: example-mod wrapper (Gradle/Fabric Loom)
# ------------------------------------
build_example_mod_wrapper() {
    local clean="$1"
    local wrapper_dir="$SCRIPT_DIR/example-mod/wrapper"

    if [[ ! -d "$wrapper_dir" ]]; then
        die "example-mod/wrapper directory not found at $wrapper_dir"
    fi

    step "Building example-mod wrapper (Gradle/Fabric Loom)"

    local gradle_cmd=("./gradlew" "build")
    if [[ "$clean" == "true" ]]; then
        gradle_cmd=("./gradlew" "clean" "build")
    fi

    info "Running: ${gradle_cmd[*]}"
    if ! (cd "$wrapper_dir" && "${gradle_cmd[@]}") 2>&1; then
        die "Failed to build example-mod wrapper"
    fi

    success "example-mod wrapper built successfully"
}

# ------------------------------------
# Copy JARs to mods directory
# ------------------------------------
copy_jars_to_mods() {
    local output_dir="$1"
    local mods_dir="${output_dir}/mods"

    step "Copying JARs to ${mods_dir}"

    mkdir -p "$mods_dir"

    # Copy fabric-loader JAR
    local fabric_jar
    fabric_jar="$(find "$SCRIPT_DIR/fabric-loader/build/libs" -maxdepth 1 -name "*.jar" -not -name "*-sources.jar" -not -name "*-javadoc.jar" 2>/dev/null | head -1)"

    if [[ -n "$fabric_jar" ]] && [[ -f "$fabric_jar" ]]; then
        cp "$fabric_jar" "$mods_dir/"
        info "Copied fabric-loader JAR: $(basename "$fabric_jar")"
    else
        warn "No fabric-loader JAR found in fabric-loader/build/libs/"
    fi

    # Copy example-mod wrapper JAR
    local wrapper_jar
    wrapper_jar="$(find "$SCRIPT_DIR/example-mod/wrapper/build/libs" -maxdepth 1 -name "*.jar" -not -name "*-sources.jar" -not -name "*-javadoc.jar" 2>/dev/null | head -1)"

    if [[ -n "$wrapper_jar" ]] && [[ -f "$wrapper_jar" ]]; then
        cp "$wrapper_jar" "$mods_dir/"
        info "Copied example-mod wrapper JAR: $(basename "$wrapper_jar")"
    else
        warn "No example-mod wrapper JAR found in example-mod/wrapper/build/libs/"
    fi

    # Copy modmenu if available
    local modmenu_jar="$SCRIPT_DIR/mods/modmenu-3.2.3.jar"
    if [[ -f "$modmenu_jar" ]]; then
        cp "$modmenu_jar" "$mods_dir/"
        info "Copied modmenu-3.2.3.jar"
    else
        warn "modmenu-3.2.3.jar not found — skipping"
    fi

    success "JARs copied to ${mods_dir}"
}

# ------------------------------------
# Full build pipeline for a single version
# ------------------------------------
build_version() {
    local mc_version="$1"
    local no_run="${2:-false}"
    local clean="${3:-false}"
    local output_base="${4:-$SCRIPT_DIR/fabric-loader/run}"

    local yarn="${YARN_MAPPINGS[$mc_version]}"
    local fabric="${FABRIC_LOADERS[$mc_version]}"
    local java_target="${JAVA_TARGETS[$mc_version]}"

    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║  Building for Minecraft ${mc_version}          ║${NC}"
    echo -e "${BOLD}║  Yarn: ${yarn}                ║${NC}"
    echo -e "${BOLD}║  Fabric Loader: ${fabric}            ║${NC}"
    echo -e "${BOLD}║  Java Target: ${java_target}                       ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"

    # Step 1: Patch gradle.properties
    step "Patching gradle.properties"
    patch_gradle_properties "$mc_version" "$yarn" "$fabric" \
        "$SCRIPT_DIR/fabric-loader/gradle.properties"
    patch_gradle_properties "$mc_version" "$yarn" "$fabric" \
        "$SCRIPT_DIR/example-mod/wrapper/gradle.properties"

    # Step 2: Build rustcraft-core
    build_rustcraft_core_in_dir "$clean"

    # Step 3: Build example-mod
    build_example_mod "$clean"

    # Step 4: Build fabric-loader
    build_fabric_loader "$clean"

    # Step 5: Build example-mod wrapper
    build_example_mod_wrapper "$clean"

    # Step 6: Copy JARs
    local output_dir
    if [[ "$output_base" == *"build-versions"* ]]; then
        output_dir="${output_base}/${mc_version}"
    else
        output_dir="$output_base"
    fi
    copy_jars_to_mods "$output_dir"

    success "Build complete for Minecraft ${mc_version}"

    # Step 7: Run client (unless --no-run)
    if [[ "$no_run" == "false" ]]; then
        step "Launching Minecraft client"
        info "Running: ./gradlew runClient"
        if ! (cd "$SCRIPT_DIR/fabric-loader" && ./gradlew runClient) 2>&1; then
            error "Failed to launch client for Minecraft ${mc_version}"
            return 1
        fi
    fi

    return 0
}

# ------------------------------------
# Build ALL versions
# ------------------------------------
build_all_versions() {
    local no_run="${1:-false}"
    local clean="${2:-false}"

    local output_base="$SCRIPT_DIR/build-versions"
    mkdir -p "$output_base"

    local failed_versions=()
    local succeeded_versions=()

    for mc_version in "${MC_VERSIONS[@]}"; do
        if build_version "$mc_version" "$no_run" "$clean" "$output_base"; then
            succeeded_versions+=("$mc_version")
        else
            failed_versions+=("$mc_version")
            warn "Build failed for ${mc_version} — continuing with next version"
        fi
    done

    # Summary
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║          Build Summary                   ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"

    if [[ ${#succeeded_versions[@]} -gt 0 ]]; then
        success "Succeeded (${#succeeded_versions[@]}):"
        for v in "${succeeded_versions[@]}"; do
            echo -e "  ${GREEN}✓${NC} $v"
        done
    fi

    if [[ ${#failed_versions[@]} -gt 0 ]]; then
        error "Failed (${#failed_versions[@]}):"
        for v in "${failed_versions[@]}"; do
            echo -e "  ${RED}✗${NC} $v"
        done
        echo ""
        return 1
    fi

    return 0
}

# ------------------------------------
# Interactive menu
# ------------------------------------
interactive_menu() {
    echo ""
    echo -e "${BOLD}════════════════════════════════════════════${NC}"
    echo -e "${BOLD}         RustCraft Build System             ${NC}"
    echo -e "${BOLD}════════════════════════════════════════════${NC}"
    echo ""
    echo "Select Minecraft version:"
    echo ""

    local i=1
    for mc_version in "${MC_VERSIONS[@]}"; do
        local java_target="${JAVA_TARGETS[$mc_version]}"
        local yarn="${YARN_MAPPINGS[$mc_version]}"
        printf "  ${CYAN}[%2d]${NC} %-8s (Java %s, Yarn %s)\n" "$i" "$mc_version" "$java_target" "$yarn"
        ((i++))
    done

    echo ""
    printf "  ${YELLOW}[A]${NC}  Build ALL versions\n"
    echo ""
    printf "> "

    read -r choice

    case "${choice,,}" in
        a|all)
            echo ""
            info "Building all versions..."
            build_all_versions "false" "false"
            ;;
        *)
            # Validate numeric choice
            if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#MC_VERSIONS[@]} )); then
                die "Invalid choice: $choice"
            fi

            local selected_version="${MC_VERSIONS[$((choice - 1))]}"
            info "Selected: Minecraft $selected_version"
            build_version "$selected_version" "false" "false"
            ;;
    esac
}

# ------------------------------------
# Main
# ------------------------------------
main() {
    local version=""
    local clean="false"
    local no_run="false"
    local build_all="false"
    local interactive="true"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--version)
                [[ -z "${2:-}" ]] && die "Missing version argument for --version"
                version="$2"
                interactive="false"
                shift 2
                ;;
            -c|--clean)
                clean="true"
                shift
                ;;
            -n|--no-run)
                no_run="true"
                shift
                ;;
            -a|--build-all)
                build_all="true"
                interactive="false"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "Unknown option: $1 (use --help for usage)"
                ;;
        esac
    done

    # Validate version if provided
    if [[ -n "$version" ]]; then
        if [[ -z "${YARN_MAPPINGS[$version]+x}" ]]; then
            die "Unknown version: $version. Supported: ${MC_VERSIONS[*]}"
        fi
    fi

    # Detect platform and JAVA_HOME
    detect_platform
    detect_java_home

    if [[ "$interactive" == "true" ]]; then
        interactive_menu
    elif [[ "$build_all" == "true" ]]; then
        info "Building all versions..."
        build_all_versions "$no_run" "$clean"
    else
        build_version "$version" "$no_run" "$clean"
    fi
}

main "$@"
