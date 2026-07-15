use std::env;
use std::fs;
use std::path::PathBuf;

fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    
    // Build the core library
    let core_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap())
        .join("rustcraft-core");
    
    println!("cargo:warning=Building rustcraft-core");
    
    // In a real implementation, we would use cargo to build the core library
    // For now, we'll just set the appropriate flags
    
    // Output directory for native libraries
    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());
    
    println!("cargo:warning=Output directory: {:?}", out_dir);
    
    // Copy the built library to the resources directory
    let target_os = env::var("CARGO_CFG_TARGET_OS").unwrap();
    let target_arch = env::var("CARGO_CFG_TARGET_ARCH").unwrap();
    
    let lib_name = match target_os.as_str() {
        "windows" => "rustcraft_core.dll",
        "macos" => "librustcraft_core.dylib",
        _ => "librustcraft_core.so",
    };
    
    println!("cargo:warning=Target library name: {}", lib_name);
}
