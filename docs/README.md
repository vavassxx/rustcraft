# RustCraft Documentation

Welcome to the RustCraft documentation. RustCraft is a utility mod for Minecraft Fabric that allows loading mods written in Rust.

## Documentation Index

- [Installation Guide](INSTALLATION.md) - How to install RustCraft for players and developers
- [Development Guide](DEVELOPMENT.md) - How to develop Rust mods with RustCraft
- [API Reference](API_REFERENCE.md) - Complete API documentation
- [Compatibility Guide](COMPATIBILITY.md) - Compatibility information for Minecraft versions and mods

## Quick Start

### For Players

1. Install Fabric Loader for your Minecraft version
2. Download the RustCraft loader JAR for your version
3. Place it in your `.minecraft/mods` folder
4. Download Rust mods and place them in the mods folder
5. Launch Minecraft

### For Developers

1. Clone the repository
2. Build the Rust SDK: `cd rust-sdk && cargo build --release -p rustcraft-core`
3. Build the loader: `cd fabric-loader && ./gradlew build`
4. Create your mod using the example as a template
5. Build and install your mod

## Project Structure

```
rustcraft/
├── fabric-loader/          # Java Fabric mod (loader)
│   ├── src/main/java/com/rustcraft/
│   │   ├── RustCraftMod.java
│   │   ├── RustModLoader.java
│   │   ├── RustNativeBridge.java
│   │   └── mod/
│   └── src/main/resources/
├── rust-sdk/              # Rust SDK
│   ├── rustcraft-core/    # Core native library
│   └── rustcraft-api/     # API for mod developers
├── example-mod/           # Example Rust mod
│   ├── src/lib.rs         # Rust mod source code
│   └── wrapper/           # Java wrapper for Fabric loading
└── docs/                  # Documentation
```

## Key Features

- **Rust Support**: Write Minecraft mods in Rust
- **Multi-Version**: Supports Minecraft 1.18.2-1.21.5
- **Cross-Platform**: Works on Windows, Linux, and macOS
- **Safe**: Rust's memory safety prevents common bugs
- **Performant**: Native code for performance-critical operations
- **Compatible**: Works with popular Fabric mods

## Architecture

RustCraft consists of two main components:

1. **Java Fabric Mod**: Handles Fabric integration and mod discovery
2. **Rust Native Library**: Provides the runtime for Rust mods

Rust mods are loaded through Java wrappers. Each Rust mod ships with a Java class implementing the `RustModWrapper` interface. Fabric discovers wrappers via `fabric.mod.json`, calls their `onInitialize()`, which extracts the native library from the wrapper's JAR and registers it with `RustModLoader`.

## Getting Help

- **Issues**: Report bugs on GitHub
- **Discussions**: Ask questions on GitHub Discussions
- **Documentation**: Check the docs in this folder

## Contributing

Contributions are welcome! See the [Development Guide](DEVELOPMENT.md) for details.

## License

MIT License - See LICENSE file for details
