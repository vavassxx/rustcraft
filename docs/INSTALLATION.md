# RustCraft Installation Guide

This guide covers the installation of RustCraft for both players and developers.

## For Players

### Prerequisites

- Minecraft Java Edition
- Fabric Loader (compatible with your Minecraft version)
- Java 17 or later

### Installation Steps

1. **Install Fabric Loader**
   - Download the Fabric Installer from [fabricmc.net](https://fabricmc.net/)
   - Run the installer and select your Minecraft version
   - Create a new Fabric profile or install to an existing profile

2. **Download RustCraft**
   - Download the latest RustCraft loader mod for your Minecraft version
   - Place the `.jar` file in your `.minecraft/mods` directory

3. **Install Rust Mods**
   - Download Rust mods (`.so`, `.dll`, or `.dylib` files)
   - Place them in your `.minecraft/mods` directory
   - RustCraft will automatically detect and load them

4. **Launch Minecraft**
   - Start Minecraft with the Fabric profile
   - Check the logs to ensure RustCraft loaded successfully

### Verifying Installation

Open the Minecraft logs (`.minecraft/logs/latest.log`) and look for:

```
[RustCraft] Initializing RustCraft...
[RustCraft/Loader] Initializing Rust mod loader...
[RustCraft/Native] Native bridge initialized successfully
[RustCraft] RustCraft initialized successfully!
```

## For Developers

### Prerequisites

- Java 17 or later
- Rust 1.70 or later
- Git
- Gradle 8.5+ (included with the project)

### Setting Up the Development Environment

1. **Clone the Repository**
   ```bash
   git clone https://github.com/vavassxx/rustcraft.git
   cd rustcraft
   ```

2. **Build the Rust SDK**
   ```bash
   cd rust-sdk
   cargo build --release -p rustcraft-core
   ```

3. **Build the Fabric Loader**
   ```bash
   cd ../fabric-loader
   chmod +x gradlew
   ./gradlew build
   ```

4. **Build for Multiple Versions**
   ```bash
   cd ..
   ./run-client.sh --build-all
   ```

### IDE Setup

#### IntelliJ IDEA

1. Open the `fabric-loader` directory as a Gradle project
2. Let IntelliJ import the Gradle project
3. For Rust development, install the Rust plugin
4. Open the `rust-sdk` directory as a separate Rust project

#### VS Code

1. Install the Java Extension Pack
2. Install the Rust Analyzer extension
3. Open the project root
4. The workspace will detect both Java and Rust projects

## Building from Source

### Building the Fabric Loader

```bash
cd fabric-loader
./gradlew clean build
```

The built JAR will be in `fabric-loader/build/libs/`.

### Building the Native Library

```bash
cd rust-sdk && cargo build --release -p rustcraft-core
```

The built library will be in `rust-sdk/rustcraft-core/target/release/`.

### Building for All Minecraft Versions

```bash
./run-client.sh --build-all
```

This will build JARs for all supported Minecraft versions in `build-versions/`.

## Troubleshooting

### Native Library Not Found

**Error:** `Failed to load native library`

**Solution:**
- Ensure the native library is built for your platform
- Check that the library is in the correct resources directory
- Verify the library architecture matches your JVM (x64 vs x86)

### Mod Not Loading

**Error:** Mod appears in mods folder but doesn't load

**Solution:**
- Check the mod filename format (should be `modid-version.ext`)
- Verify the mod implements the required RustCraft functions
- Check the logs for specific error messages

### Version Compatibility

**Error:** `Unsupported Minecraft version`

**Solution:**
- Use the correct RustCraft version for your Minecraft version
- Check the version compatibility matrix in the documentation

### JNI Errors

**Error:** `JNI error occurred`

**Solution:**
- Ensure you're using Java 17 or later
- Check that the native library is compiled with the correct toolchain
- Verify the JNI version compatibility

## Platform-Specific Notes

### Windows

- Use MSVC toolchain for Rust: `rustup default stable-x86_64-pc-windows-msvc`
- Install Visual Studio Build Tools
- Native libraries use `.dll` extension

### Linux

- Use GNU toolchain for Rust (default)
- Install required build tools: `sudo apt install build-essential`
- Native libraries use `.so` extension

### macOS

- Install Xcode Command Line Tools: `xcode-select --install`
- Native libraries use `.dylib` extension
- May need to disable library validation for testing

## Uninstallation

### Removing RustCraft

1. Remove `rustcraft-loader-x.x.x.jar` from the mods folder
2. Remove any Rust mods (`.so`, `.dll`, `.dylib`) from the mods folder
3. Delete the RustCraft configuration directory (optional)

### Cleaning Development Build

```bash
cd fabric-loader
./gradlew clean

cd ../rust-sdk
cargo clean
```
