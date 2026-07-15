# RustCraft API Reference

Complete API reference for RustCraft mod development.

## rustcraft-api Crate

### Traits

#### RustCraftMod

Main trait that all RustCraft mods must implement.

```rust
pub trait RustCraftMod {
    /// Get the mod metadata
    fn metadata() -> ModMetadata;
    
    /// Called when the mod is initialized
    fn on_init(&mut self, context: &ModContext);
    
    /// Called every game tick
    fn on_tick(&mut self);
    
    /// Called when the mod is shutting down
    fn on_shutdown(&mut self);
}
```

**Methods:**

- `metadata()` - Returns static metadata about the mod
- `on_init()` - Called once when the mod is loaded
- `on_tick()` - Called every game tick
- `on_shutdown()` - Called when the mod is being unloaded

### Structs

#### ModMetadata

Metadata describing a mod.

```rust
pub struct ModMetadata {
    pub id: String,
    pub name: String,
    pub version: String,
    pub description: String,
    pub authors: Vec<String>,
}
```

**Fields:**

- `id` - Unique identifier for the mod (e.g., "my_mod")
- `name` - Human-readable name (e.g., "My Mod")
- `version` - Version string (e.g., "1.0.0")
- `description` - Short description of the mod
- `authors` - List of author names

#### ModContext

Context provided to mods by RustCraft.

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

**Fields:**

- `mod_id` - Pointer to null-terminated mod ID string
- `mod_version` - Pointer to null-terminated version string
- `log_info` - Function pointer for info logging
- `log_warn` - Function pointer for warning logging
- `log_error` - Function pointer for error logging

#### ModLogger

Helper struct for logging messages.

```rust
pub struct ModLogger {
    context: *const ModContext,
}
```

**Methods:**

```rust
impl ModLogger {
    /// Create a new mod logger
    pub fn new(context: *const ModContext) -> Self;
    
    /// Log an info message
    pub fn info(&self, message: &str);
    
    /// Log a warning message
    pub fn warn(&self, message: &str);
    
    /// Log an error message
    pub fn error(&self, message: &str);
}
```

### Macros

#### rustcraft_mod!

Macro to simplify mod registration.

```rust
rustcraft_mod!(MyModType);
```

This macro generates the necessary C ABI functions:
- `rustcraft_mod_init` - Called when the mod is loaded
- `rustcraft_mod_shutdown` - Called when the mod is unloaded

**Requirements:**

- The type must implement `RustCraftMod`
- The type must have a `new()` constructor

## rustcraft-core Crate

### C ABI Functions

These functions are called from Java via JNI.

#### rustcraft_init

```c
long rustcraft_init();
```

Initialize the RustCraft context.

**Returns:** Non-zero context handle on success, 0 on failure.

#### rustcraft_shutdown

```c
void rustcraft_shutdown(long context);
```

Shutdown the RustCraft context and unload all mods.

**Parameters:**
- `context` - Context handle from `rustcraft_init`

#### rustcraft_load_mod

```c
long rustcraft_load_mod(long context, const char* mod_path, const char* mod_id);
```

Load a Rust mod from a dynamic library.

**Parameters:**
- `context` - Context handle
- `mod_path` - Path to the mod's library file
- `mod_id` - Unique identifier for the mod

**Returns:** Non-zero mod handle on success, 0 on failure.

#### rustcraft_unload_mod

```c
void rustcraft_unload_mod(long context, long mod_handle);
```

Unload a previously loaded mod.

**Parameters:**
- `context` - Context handle
- `mod_handle` - Handle from `rustcraft_load_mod`

#### rustcraft_call_mod_init

```c
void rustcraft_call_mod_init(long mod_handle);
```

Call the mod's initialization function.

**Parameters:**
- `mod_handle` - Handle to the mod

#### rustcraft_call_mod_shutdown

```c
void rustcraft_call_mod_shutdown(long mod_handle);
```

Call the mod's shutdown function.

**Parameters:**
- `mod_handle` - Handle to the mod

#### rustcraft_get_mod_version

```c
const char* rustcraft_get_mod_version(long mod_handle);
```

Get the version string of a mod.

**Parameters:**
- `mod_handle` - Handle to the mod

**Returns:** Pointer to null-terminated version string.

#### rustcraft_get_last_error

```c
const char* rustcraft_get_last_error(long context);
```

Get the last error message.

**Parameters:**
- `context` - Context handle

**Returns:** Pointer to null-terminated error string.

## Java API

### RustCraftMod

Main entry point class.

```java
package com.rustcraft;

public class RustCraftMod implements ModInitializer {
    public static final String MOD_ID = "rustcraft";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);
    
    @Override
    public void onInitialize();
    
    public static RustModLoader getModLoader();
}
```

### RustModLoader

Manages loading and lifecycle of Rust mods.

```java
package com.rustcraft;

public class RustModLoader {
    public void initialize();
    public List<RustMod> getLoadedMods();
    public RustMod getMod(String id);
    public boolean isModLoaded(String id);
    public void shutdown();
}
```

### RustNativeBridge

JNI bridge for native communication.

```java
package com.rustcraft;

public class RustNativeBridge {
    public boolean initialize();
    public void shutdown();
    public long loadMod(String modPath, String modId);
    public void unloadMod(long modHandle);
    public void callModInit(long modHandle);
    public void callModShutdown(long modHandle);
    public String getModVersion(long modHandle);
    public String getLastError();
    public boolean isInitialized();
}
```

### RustMod

Represents a loaded Rust mod.

```java
package com.rustcraft.mod;

public class RustMod {
    public void initialize();
    public void shutdown();
    public RustModMetadata getMetadata();
    public boolean isInitialized();
    public long getNativeHandle();
}
```

### RustModMetadata

Metadata for a Rust mod.

```java
package com.rustcraft.mod;

public class RustModMetadata {
    private String id;
    private String name;
    private String version;
    private String description;
    private String path;
    private String[] authors;
    private String[] dependencies;
    
    // Getters and setters
}
```

## Version Compatibility

### Minecraft Version Support

| Minecraft Version | Loader Version | API Version |
|-------------------|----------------|-------------|
| 1.18.2            | 0.14.21+       | 1.0         |
| 1.19.4            | 0.14.21+       | 1.0         |
| 1.20.1            | 0.14.21+       | 1.0         |
| 1.20.4            | 0.15.11+       | 1.0         |
| 1.21.5            | 0.16.0+        | 1.0         |

### Platform Support

| Platform | Architectures | Library Extension |
|----------|---------------|-------------------|
| Linux    | x64, x86, ARM64 | .so            |
| Windows  | x64, x86      | .dll              |
| macOS    | x64, ARM64    | .dylib            |

## Error Handling

Functions return `0` for failure and a non-zero handle for success. Use `rustcraft_get_last_error()` to retrieve the error message after a failure.

### Java Exceptions

| Exception | Description |
|-----------|-------------|
| `IllegalStateException` | Native bridge not initialized |
| `IOException` | Failed to load native library |
| `RuntimeException` | Native operation failed |

## Future API Additions

Planned features for future versions:

- Command registration
- Configuration system
- Resource loading
- Networking support
- Entity/Block interaction
- Dimension/World API

## Migration Guide

### From 0.1.0 to 0.2.0 (Future)

No breaking changes planned. Migration will be automatic.

## Examples

See the `example-mod` directory for complete examples of:
- Basic mod structure
- Logging usage
- State management
- Error handling
