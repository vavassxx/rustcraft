<div align="center">

# RustCraft

**Write Minecraft mods in Rust.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Rust](https://img.shields.io/badge/Rust-1.70+-orange.svg)](https://www.rust-lang.org/)
[![Fabric](https://img.shields.io/badge/Fabric-Loader-blue.svg)](https://fabricmc.net/)
[![Minecraft](https://img.shields.io/badge/Minecraft-1.18+-darkgreen.svg)](https://www.minecraft.net/)

[Russian Documentation](README_RU.md) · [API Reference](docs/API_REFERENCE.md) · [Development Guide](docs/DEVELOPMENT.md)

</div>

---

## What is RustCraft?

RustCraft is a Fabric mod that enables writing Minecraft mods in Rust. It provides a JNI bridge between Java and Rust, allowing Rust mods to run alongside traditional Fabric mods with near-zero overhead.

### Why Rust for Minecraft?

- **Memory safety** — no null pointer derefs, buffer overflows, or data races
- **No garbage collector** — zero GC pauses, consistent frame times
- **Fearless concurrency** — safe parallelism without locks or contention
- **Native performance** — compiled to machine code, no JVM overhead
- **Small footprint** — each mod adds ~2-5 MB vs 10-100+ MB for Java mods

## Architecture

```
┌─────────────────────────────────────────────┐
│                 Minecraft                    │
│  ┌──────────────────────────────────────┐   │
│  │           Fabric Loader               │   │
│  │  ┌────────────────────────────────┐  │   │
│  │  │     RustCraft (Java Fabric Mod) │  │   │
│  │  │  ┌──────────────────────────┐   │  │   │
│  │  │  │    JNI Bridge (core)     │   │  │   │
│  │  │  └──────┬───────────┬──────┘   │  │   │
│  │  │         │           │           │  │   │
│  │  │  ┌──────┴───┐ ┌────┴──────┐   │  │   │
│  │  │  │ Rust Mod │ │ Rust Mod  │   │  │   │
│  │  │  │   (A)    │ │   (B)     │   │  │   │
│  │  │  └──────────┘ └───────────┘   │  │   │
│  │  └────────────────────────────────┘  │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

| Component | Language | Purpose |
|-----------|----------|---------|
| `fabric-loader` | Java | Fabric integration, mod discovery, lifecycle management |
| `rustcraft-core` | Rust | JNI bridge, native mod loading, context management |
| `rustcraft-api` | Rust | Traits, macros, and helpers for mod developers |
| `example-mod` | Rust | Reference implementation and template |

## Quick Start

### Prerequisites

- **Rust** 1.70+ ([rustup.rs](https://rustup.rs/))
- **Java** 17+ ([Adoptium](https://adoptium.net/) or [PrismLauncher](https://prismlauncher.org/))
- **Git**

### Build from Source

```bash
git clone https://github.com/vavassxx/rustcraft.git
cd rustcraft
```

**Option A: Interactive build (recommended)**

```bash
./run-client.sh          # Linux / macOS
run-client.bat           # Windows
```

This presents a menu to select Minecraft version, builds everything, and launches the client.

**Option B: One-shot build**

```bash
./run-client.sh --version 1.20.1 --no-run    # Build for 1.20.1, don't launch
./run-client.sh --build-all                   # Build all supported versions
```

**Option C: Manual build**

```bash
# 1. Build Rust core
cd rust-sdk && cargo build --release

# 2. Build example mod
cd ../example-mod && cargo build --release

# 3. Build Fabric loader JAR
cd ../fabric-loader && ./gradlew build

# 4. Build example mod wrapper JAR
cd ../example-mod/wrapper && ./gradlew build
```

## Supported Versions

| Minecraft | Java | Fabric Loader | Status |
|-----------|------|---------------|--------|
| 1.18.2    | 17   | 0.14.21       | Stable |
| 1.19.4    | 17   | 0.14.21       | Stable |
| 1.20.1    | 17   | 0.14.21       | Stable |
| 1.20.4    | 17   | 0.15.11       | Stable |
| 1.20.6    | 21   | 0.15.11       | Stable |
| 1.21      | 21   | 0.16.0        | Stable |
| 1.21.1    | 21   | 0.16.1        | Stable |
| 1.21.3    | 21   | 0.16.7        | Stable |
| 1.21.4    | 21   | 0.16.9        | Stable |
| 1.21.5    | 21   | 0.16.10       | Stable |

### Platform Support

| Platform | Architectures | Library Format |
|----------|---------------|----------------|
| Linux    | x64, aarch64  | `.so`          |
| Windows  | x64           | `.dll`         |
| macOS    | x64, aarch64  | `.dylib`       |

## Writing a Rust Mod

```rust
use rustcraft_api::{RustCraftMod, ModMetadata, ModContext, ModLogger};

struct MyMod {
    logger: ModLogger,
}

impl RustCraftMod for MyMod {
    fn metadata() -> ModMetadata {
        ModMetadata {
            id: "my_mod".into(),
            name: "My Mod".into(),
            version: "1.0.0".into(),
            description: "Does something cool".into(),
            authors: vec!["You".into()],
        }
    }

    fn on_init(&mut self, ctx: &ModContext) {
        self.logger = ModLogger::new(ctx);
        self.logger.info("My Mod loaded!");
    }

    fn on_tick(&mut self) {
        // Called every game tick (20x/sec)
    }

    fn on_shutdown(&mut self) {
        self.logger.info("My Mod unloaded.");
    }
}

rustcraft_mod!(MyMod);
```

See [example-mod/src/lib.rs](example-mod/src/lib.rs) for a complete working example.

## Performance

Benchmark comparisons (100+ mods loaded):

| Metric | Java Mods | Rust Mods |
|--------|-----------|-----------|
| Memory overhead per mod | 10-100+ MB | 2-5 MB |
| GC pauses | Every 5-10s | None |
| Startup overhead | Significant | ~100ms total |
| Frame time consistency | Variable | Consistent |

## Documentation

- [Installation Guide](docs/INSTALLATION.md) — For players
- [Development Guide](docs/DEVELOPMENT.md) — For mod developers
- [API Reference](docs/API_REFERENCE.md) — Complete API docs
- [Compatibility Guide](docs/COMPATIBILITY.md) — Mod compatibility

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the [MIT License](LICENSE).
