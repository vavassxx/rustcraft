package com.rustcraft;

import com.rustcraft.mod.RustMod;
import com.rustcraft.mod.RustModWrapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Handles loading and management of Rust mods via their Java wrappers.
 * Fabric discovers wrappers through fabric.mod.json entrypoints,
 * then calls registerMod() for each one.
 */
public class RustModLoader {
    private static final Logger LOGGER = LoggerFactory.getLogger("RustCraft/Loader");

    private final Map<String, RustMod> loadedMods = new HashMap<>();
    private final RustNativeBridge nativeBridge;

    public RustModLoader() {
        this.nativeBridge = new RustNativeBridge();
    }

    /**
     * Initialize the native bridge.
     */
    public void initialize() {
        LOGGER.info("Initializing Rust mod loader...");

        if (!nativeBridge.initialize()) {
            LOGGER.error("Failed to initialize native bridge. Rust mods will not be loaded.");
            return;
        }

        LOGGER.info("Rust mod loader ready. Waiting for mod registrations.");
    }

    /**
     * Called by a Rust mod's Java wrapper to register itself with the loader.
     * Extracts the native library from the wrapper's JAR and loads it.
     *
     * @param wrapper the Java wrapper implementing RustModWrapper
     * @return true if the mod was loaded successfully
     */
    public boolean registerMod(RustModWrapper wrapper) {
        if (!nativeBridge.isInitialized()) {
            LOGGER.error("Cannot register mod {}: native bridge not initialized", wrapper.getModId());
            return false;
        }

        if (loadedMods.containsKey(wrapper.getModId())) {
            LOGGER.warn("Mod {} is already registered", wrapper.getModId());
            return false;
        }

        String libPath = wrapper.getNativeLibraryPath();
        if (libPath == null || libPath.isEmpty()) {
            LOGGER.error("Mod {} returned null/empty native library path", wrapper.getModId());
            return false;
        }

        LOGGER.info("Registering Rust mod: {} (native: {})", wrapper.getModId(), libPath);

        long handle = nativeBridge.loadMod(libPath, wrapper.getModId());
        if (handle == 0) {
            LOGGER.error("Failed to load native library for mod {}", wrapper.getModId());
            return false;
        }

        RustMod mod = new RustMod(wrapper.getModId(), handle, nativeBridge);
        mod.initialize();
        if (!mod.isInitialized()) {
            LOGGER.error("Failed to initialize mod {}, unloading native library", wrapper.getModId());
            nativeBridge.unloadMod(handle);
            return false;
        }
        loadedMods.put(wrapper.getModId(), mod);

        LOGGER.info("Successfully registered mod: {}", wrapper.getModId());
        return true;
    }

    /**
     * Shutdown a specific mod.
     */
    public void unregisterMod(String modId) {
        RustMod mod = loadedMods.remove(modId);
        if (mod != null) {
            mod.shutdown();
        }
    }

    public RustMod getMod(String id) {
        return loadedMods.get(id);
    }

    public boolean isModLoaded(String id) {
        return loadedMods.containsKey(id);
    }

    public List<RustMod> getLoadedMods() {
        return new ArrayList<>(loadedMods.values());
    }

    /**
     * Shutdown all loaded mods and the native bridge.
     */
    public void shutdown() {
        LOGGER.info("Shutting down Rust mod loader...");

        for (RustMod mod : loadedMods.values()) {
            try {
                mod.shutdown();
            } catch (Exception e) {
                LOGGER.error("Error shutting down mod: {}", mod.getModId(), e);
            }
        }

        loadedMods.clear();
        nativeBridge.shutdown();

        LOGGER.info("Rust mod loader shutdown complete");
    }
}
