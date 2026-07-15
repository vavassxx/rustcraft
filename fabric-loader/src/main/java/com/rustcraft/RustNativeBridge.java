package com.rustcraft;

import com.rustcraft.mod.RustMod;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * JNI bridge for communicating with Rust native libraries.
 */
public class RustNativeBridge {
    private static final Logger LOGGER = LoggerFactory.getLogger("RustCraft/Native");

    private boolean initialized = false;
    private long nativeContext;

    /**
     * Initialize the native bridge by loading rustcraft_core.
     */
    public boolean initialize() {
        if (initialized) {
            return true;
        }

        try {
            loadCoreLibrary();
            nativeContext = nativeInit();
            if (nativeContext == 0) {
                LOGGER.error("Failed to initialize native context");
                return false;
            }
            initialized = true;
            LOGGER.info("Native bridge initialized successfully");
            return true;
        } catch (Exception e) {
            LOGGER.error("Failed to initialize native bridge", e);
            return false;
        }
    }

    /**
     * Load the rustcraft_core native library from the loader JAR's resources.
     */
    private void loadCoreLibrary() throws IOException {
        String osName = System.getProperty("os.name").toLowerCase();
        String arch = System.getProperty("os.arch").toLowerCase();

        String libName;
        String libExtension;
        String subDir;

        if (osName.contains("win")) {
            libName = "rustcraft_core";
            libExtension = ".dll";
            subDir = "windows/x64";
        } else if (osName.contains("mac")) {
            libName = "librustcraft_core";
            libExtension = ".dylib";
            subDir = "macos/x64";
        } else {
            libName = "librustcraft_core";
            libExtension = ".so";
            subDir = "linux/x64";
        }

        if (arch.contains("aarch64") || arch.contains("arm64")) {
            subDir = subDir.replace("x64", "aarch64");
        }

        String resourcePath = "/native/" + subDir + "/" + libName + libExtension;
        LOGGER.info("Loading core library from: {}", resourcePath);

        try (InputStream in = getClass().getResourceAsStream(resourcePath)) {
            if (in == null) {
                throw new IOException("Core library not found in JAR: " + resourcePath);
            }

            Path tempDir = Files.createTempDirectory("rustcraft-core");
            Path tempLib = tempDir.resolve(libName + libExtension);

            Files.copy(in, tempLib);
            System.load(tempLib.toAbsolutePath().toString());

            tempLib.toFile().deleteOnExit();

            LOGGER.info("Core library loaded successfully");
        }
    }

    /**
     * Load a Rust mod's native library and call its init function.
     *
     * @param libraryPath path to the .so/.dll/.dylib file
     * @param modId       mod identifier
     * @return mod handle, or 0 on failure
     */
    public long loadMod(String libraryPath, String modId) {
        if (!initialized) {
            throw new IllegalStateException("Native bridge not initialized");
        }

        long handle = nativeLoadMod(nativeContext, libraryPath, modId);
        if (handle == 0) {
            String error = nativeGetLastError(nativeContext);
            LOGGER.error("Failed to load mod {}: {}", modId, error);
        }
        return handle;
    }

    /**
     * Initialize a loaded Rust mod.
     */
    public void callModInit(long modHandle) {
        if (!initialized) {
            throw new IllegalStateException("Native bridge not initialized");
        }
        nativeCallModInit(modHandle);
    }

    /**
     * Shutdown a loaded Rust mod.
     */
    public void callModShutdown(long modHandle) {
        if (!initialized) {
            return;
        }
        nativeCallModShutdown(modHandle);
    }

    /**
     * Unload a Rust mod.
     */
    public void unloadMod(long modHandle) {
        if (!initialized || modHandle == 0) {
            return;
        }
        nativeUnloadMod(nativeContext, modHandle);
    }

    /**
     * Shutdown the native bridge.
     */
    public void shutdown() {
        if (!initialized) {
            return;
        }
        if (nativeContext != 0) {
            nativeShutdown(nativeContext);
            nativeContext = 0;
        }
        initialized = false;
        LOGGER.info("Native bridge shutdown complete");
    }

    public boolean isInitialized() {
        return initialized;
    }

    // Native method declarations
    private native long nativeInit();
    private native void nativeShutdown(long context);
    private native long nativeLoadMod(long context, String modPath, String modId);
    private native void nativeUnloadMod(long context, long modHandle);
    private native void nativeCallModInit(long modHandle);
    private native void nativeCallModShutdown(long modHandle);
    private native String nativeGetLastError(long context);
}
