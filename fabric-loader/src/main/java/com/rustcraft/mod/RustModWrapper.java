package com.rustcraft.mod;

/**
 * Interface that all Rust mod Java wrappers must implement.
 * Each Rust mod provides a JAR with a Java class implementing this interface.
 * Fabric discovers the wrapper via fabric.mod.json and calls its lifecycle methods.
 */
public interface RustModWrapper {
    /**
     * Return the path to the native library (.so/.dll/.dylib) for the current platform.
     * The library is typically extracted from the JAR's resources.
     */
    String getNativeLibraryPath();

    /**
     * Return the mod ID.
     */
    String getModId();
}
