# RustCraft Example Mod

This is an example mod demonstrating the capabilities of RustCraft.

## Features

- Demonstrates basic mod initialization and shutdown
- Shows logging functionality at different levels
- Tracks mod uptime and tick count
- Serves as a template for creating your own Rust mods

## Building

### Prerequisites

- Rust 1.70 or later
- RustCraft SDK

### Build Steps

1. Build the RustCraft SDK:
```bash
cd ../rust-sdk
./build-native.sh
```

2. Build the example mod:
```bash
cargo build --release
```

3. The compiled library will be in `target/release/`:
   - Linux: `librustcraft_example.so`
   - macOS: `librustcraft_example.dylib`
   - Windows: `rustcraft_example.dll`

## Installation

1. Copy the compiled library to your Minecraft `mods` folder
2. Ensure RustCraft loader mod is installed
3. Launch Minecraft

## Usage

The mod will automatically load when Minecraft starts. Check the logs for output from the example mod.

## Creating Your Own Mod

Use this example as a template:

1. Copy this directory
2. Modify `Cargo.toml` with your mod's information
3. Implement the `RustCraftMod` trait in `src/lib.rs`
4. Use the `rustcraft_mod!` macro to register your mod
5. Build and install

## License

MIT License
