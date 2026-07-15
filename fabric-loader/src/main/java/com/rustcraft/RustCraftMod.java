package com.rustcraft;

import net.fabricmc.api.ModInitializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Main entry point for RustCraft mod.
 */
public class RustCraftMod implements ModInitializer {
    public static final String MOD_ID = "rustcraft";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    private static RustModLoader modLoader;

    @Override
    public void onInitialize() {
        LOGGER.info("Initializing RustCraft...");
        
        modLoader = new RustModLoader();
        modLoader.initialize();
        
        LOGGER.info("RustCraft initialized successfully!");
    }

    public static RustModLoader getModLoader() {
        return modLoader;
    }
}
