# RustCraft Development Guide

This guide covers developing mods with RustCraft and contributing to the RustCraft project.

## Developing Rust Mods

### Getting Started

1. **Set up the RustCraft SDK**
   ```bash
   cd rust-sdk
   cargo build --release -p rustcraft-core
   ```

2. **Create a New Mod Project**
   ```bash
   cargo new my_mod --lib
   cd my_mod
   ```

3. **Configure Cargo.toml**
   ```toml
   [package]
   name = "my_mod"
   version = "0.1.0"
   edition = "2021"

   [lib]
   name = "my_mod"
   crate-type = ["cdylib"]

   [dependencies]
   rustcraft-api = { path = "path/to/rust-sdk/rustcraft-api" }
   log = "0.4"
   ```

4. **Implement Your Mod**
   See the example mod for a template.

### API Reference

#### RustCraftMod Trait

All RustCraft mods must implement the `RustCraftMod` trait:

```rust
use rustcraft_api::{RustCraftMod, ModMetadata, ModContext};

struct MyMod {
    // Your mod's state here
}

impl RustCraftMod for MyMod {
    fn metadata() -> ModMetadata {
        ModMetadata {
            id: "my_mod".to_string(),
            name: "My Mod".to_string(),
            version: "0.1.0".to_string(),
            description: "A description".to_string(),
            authors: vec!["Your Name".to_string()],
        }
    }

    fn on_init(&mut self, context: &ModContext) {
        // Initialization logic
    }

    fn on_shutdown(&mut self) {
        // Cleanup logic
    }
}

rustcraft_mod!(MyMod);
```

#### ModContext

The `ModContext` provides information and logging functions:

```rust
#[repr(C)]
pub struct ModContext {
    pub mod_id: *const c_char,
    pub mod_version: *const c_char,
    pub log_info: Option<extern "C" fn(*const c_char)>,
    pub log_warn: Option<extern "C" fn(*const c_char)>,
    pub log_error: Option<extern "C" fn(*const c_char)>,
}
```

#### ModLogger

Helper for logging:

```rust
use rustcraft_api::ModLogger;

let logger = ModLogger::new(context);
logger.info("Info message");
logger.warn("Warning message");
logger.error("Error message");
```

### Building Your Mod

```bash
cargo build --release
```

The output will be:
- Linux: `target/release/libmy_mod.so`
- macOS: `target/release/libmy_mod.dylib`
- Windows: `target/release/my_mod.dll`

### Testing Your Mod

1. Build your mod
2. Copy the library to your Minecraft mods folder
3. Launch Minecraft with RustCraft installed
4. Check the logs for your mod's output

## Advanced Topics

### Mod Dependencies

Mods can declare dependencies in their metadata:

```rust
fn metadata() -> ModMetadata {
    ModMetadata {
        // ... other fields
        dependencies: vec![
            "other_mod".to_string(),
        ],
    }
}
```

### Event Handling

Currently, RustCraft supports basic lifecycle events. Future versions will include:

- Game tick events
- Player events
- Block events
- Entity events

### Java Interop

For advanced Java interop, you can use JNI directly:

```rust
use jni::JNIEnv;
use jni::objects::{JClass, JObject};

#[no_mangle]
pub extern "C" fn Java_com_example_MyClass_nativeMethod(
    env: JNIEnv,
    _class: JClass,
    obj: JObject,
) {
    // Your JNI code here
}
```

## Contributing to RustCraft

### Setting Up Development Environment

1. Fork the repository
2. Clone your fork
3. Set up the development environment as described in [Installation Guide](INSTALLATION.md)

### Code Style

- Follow Rust naming conventions
- Use `cargo fmt` for formatting
- Use `cargo clippy` for linting
- Add comments for public APIs

### Testing

```bash
# Run Rust tests
cd rust-sdk
cargo test

# Run Java tests
cd fabric-loader
./gradlew test
```

### Submitting Changes

1. Create a new branch
2. Make your changes
3. Add tests if applicable
4. Update documentation
5. Submit a pull request

### Project Structure

```
rustcraft/
├── fabric-loader/          # Java Fabric mod (loader)
│   ├── src/main/java/
│   │   └── com/rustcraft/
│   │       ├── RustCraftMod.java
│   │       ├── RustModLoader.java
│   │       ├── RustNativeBridge.java
│   │       └── mod/
│   └── src/main/resources/
├── rust-sdk/              # Rust SDK
│   ├── rustcraft-core/    # Core native library
│   └── rustcraft-api/     # API for mod developers
├── example-mod/           # Example Rust mod
│   ├── src/lib.rs         # Rust mod source code
│   └── wrapper/           # Java wrapper for Fabric loading
└── docs/                  # Documentation
```

## Architecture

### Java Side

- **RustCraftMod**: Main loader entry point
- **RustModLoader**: Manages mod loading lifecycle
- **RustNativeBridge**: JNI bridge to native code
- **RustMod**: Represents a loaded mod
- **RustModWrapper**: Interface for Java wrappers of Rust mods

### Rust Side

- **rustcraft-core**: Core native library with JNI functions
- **rustcraft-api**: High-level API for mod developers

### Loading Process

1. Fabric loads the `RustCraftMod` entrypoint
2. `RustCraftMod` creates `RustModLoader`, which initializes `RustNativeBridge` and loads the core native library from JAR resources
3. Fabric discovers Java mod wrappers via `fabric.mod.json` and calls their `onInitialize()`
4. Each wrapper extracts the native library (.so/.dll/.dylib) from its JAR to a temporary directory
5. The wrapper polls for `RustModLoader` (since entrypoint initialization order is not guaranteed)
6. Once found, the wrapper creates a `RustModWrapper` implementation and calls `registerMod()`
7. `RustModLoader` loads the native library via `RustNativeBridge` and calls `rustcraft_mod_init`

## Performance Considerations

### Native Library Size

- Use LTO (Link Time Optimization) in release builds
- Strip debug symbols: `cargo build --release --strip`
- Consider using `panic = "abort"` in Cargo.toml

### Memory Management

- Rust's ownership system prevents memory leaks
- Be careful with FFI boundaries
- Use appropriate data structures for your use case

### Thread Safety

- Rust's type system ensures thread safety
- Avoid sharing mutable state across threads
- Use channels for communication between threads

## Debugging

### Java Side

Enable debug logging in `fabric.mod.json`:

```json
{
  "custom": {
    "rustcraft:debug": true
  }
}
```

### Rust Side

Use `log` crate with `env_logger`:

```rust
env_logger::init();
log::info!("Debug message");
```

### Native Crashes

If the native library crashes:

1. Check the crash logs
2. Use a debugger (gdb, lldb, Visual Studio Debugger)
3. Enable debug symbols in the native build

## Best Practices

1. **Error Handling**: Use `Result` types for fallible operations
2. **Logging**: Log important events and errors
3. **Testing**: Write unit tests for your mod logic
4. **Documentation**: Document your public API
5. **Versioning**: Use semantic versioning for your mod
6. **Compatibility**: Test on multiple Minecraft versions

## Resources

- [Rust Book](https://doc.rust-lang.org/book/)
- [JNI Specification](https://docs.oracle.com/javase/8/docs/technotes/guides/jni/)
- [Fabric Documentation](https://fabricmc.net/wiki/)
- [Minecraft Wiki](https://minecraft.fandom.com/)
