package com.rustcraft.mod;

import com.rustcraft.RustNativeBridge;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Represents a loaded Rust mod.
 */
public class RustMod {
    private static final Logger LOGGER = LoggerFactory.getLogger("RustCraft/Mod");

    private final String modId;
    private final long nativeHandle;
    private final RustNativeBridge nativeBridge;
    private boolean initialized = false;

    public RustMod(String modId, long nativeHandle, RustNativeBridge nativeBridge) {
        this.modId = modId;
        this.nativeHandle = nativeHandle;
        this.nativeBridge = nativeBridge;
    }

    public void initialize() {
        if (initialized) {
            LOGGER.warn("Mod {} is already initialized", modId);
            return;
        }
        if (nativeHandle == 0) {
            LOGGER.error("Cannot initialize mod {}: invalid native handle", modId);
            return;
        }

        try {
            nativeBridge.callModInit(nativeHandle);
            initialized = true;
            LOGGER.info("Mod {} initialized successfully", modId);
        } catch (Exception e) {
            LOGGER.error("Failed to initialize mod {}", modId, e);
        }
    }

    public void shutdown() {
        if (!initialized) {
            return;
        }
        try {
            nativeBridge.callModShutdown(nativeHandle);
            initialized = false;
            LOGGER.info("Mod {} shutdown successfully", modId);
        } catch (Exception e) {
            LOGGER.error("Failed to shutdown mod {}", modId, e);
        } finally {
            nativeBridge.unloadMod(nativeHandle);
        }
    }

    public String getModId() {
        return modId;
    }

    public long getNativeHandle() {
        return nativeHandle;
    }

    public boolean isInitialized() {
        return initialized;
    }
}
