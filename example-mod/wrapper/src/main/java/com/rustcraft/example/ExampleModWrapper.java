package com.rustcraft.example;

import net.fabricmc.api.ModInitializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.lang.reflect.Method;
import java.nio.file.*;

/**
 * Java wrapper for the RustCraft Example Mod.
 * Extracts the native .so from the JAR and registers with RustModLoader.
 * Uses a background thread to wait for the loader since Fabric doesn't guarantee entrypoint init order.
 */
public class ExampleModWrapper implements ModInitializer {
    private static final Logger LOGGER = LoggerFactory.getLogger("rustcraft_example");

    private static final String MOD_ID = "rustcraft_example";
    private static final String NATIVE_RESOURCE_DIR = "/native/";

    private String nativeLibraryPath;

    @Override
    public void onInitialize() {
        LOGGER.info("Example mod wrapper initializing...");

        try {
            nativeLibraryPath = extractNativeLibrary();
            LOGGER.info("Native library extracted to: {}", nativeLibraryPath);
        } catch (IOException e) {
            LOGGER.error("Failed to extract native library", e);
            return;
        }

        Thread registrationThread = new Thread(() -> {
            try {
                while (true) {
                    Class<?> clazz = Class.forName("com.rustcraft.RustCraftMod");
                    Method getModLoader = clazz.getMethod("getModLoader");
                    Object loader = getModLoader.invoke(null);
                    if (loader != null) {
                        registerWithLoader(loader);
                        return;
                    }
                    Thread.sleep(50);
                }
            } catch (Exception e) {
                LOGGER.error("Failed to register with RustModLoader", e);
            }
        }, "rustcraft-example-registration");
        registrationThread.setDaemon(true);
        registrationThread.start();
    }

    private void registerWithLoader(Object loader) throws Exception {
        Class<?> wrapperInterface = Class.forName("com.rustcraft.mod.RustModWrapper");
        Object proxy = java.lang.reflect.Proxy.newProxyInstance(
            wrapperInterface.getClassLoader(),
            new Class<?>[]{ wrapperInterface },
            (proxyObj, method, args) -> {
                switch (method.getName()) {
                    case "getNativeLibraryPath": return nativeLibraryPath;
                    case "getModId": return MOD_ID;
                    default: throw new UnsupportedOperationException("Unknown method: " + method.getName());
                }
            }
        );

        Method registerMod = loader.getClass().getMethod("registerMod", wrapperInterface);
        boolean result = (boolean) registerMod.invoke(loader, proxy);

        if (result) {
            LOGGER.info("Example mod registered successfully");
        } else {
            LOGGER.error("Failed to register example mod");
        }
    }

    private String extractNativeLibrary() throws IOException {
        String osName = System.getProperty("os.name").toLowerCase();
        String arch = System.getProperty("os.arch").toLowerCase();

        String libName;
        String libExtension;
        String subDir;

        if (osName.contains("win")) {
            libName = "rustcraft_example";
            libExtension = ".dll";
            subDir = "windows/x64";
        } else if (osName.contains("mac")) {
            libName = "librustcraft_example";
            libExtension = ".dylib";
            subDir = "macos/x64";
        } else {
            libName = "librustcraft_example";
            libExtension = ".so";
            subDir = "linux/x64";
        }

        if (arch.contains("aarch64") || arch.contains("arm64")) {
            subDir = subDir.replace("x64", "aarch64");
        }

        String resourcePath = NATIVE_RESOURCE_DIR + subDir + "/" + libName + libExtension;
        LOGGER.info("Looking for native library: {}", resourcePath);

        InputStream in = getClass().getResourceAsStream(resourcePath);
        if (in == null) {
            throw new FileNotFoundException("Native library not found in JAR: " + resourcePath);
        }

        Path tempDir = Files.createTempDirectory("rustcraft-mod-" + MOD_ID);
        Path tempLib = tempDir.resolve(libName + libExtension);

        try (in) {
            Files.copy(in, tempLib);
        }

        tempLib.toFile().deleteOnExit();
        tempDir.toFile().deleteOnExit();

        LOGGER.info("Extracted native library to: {}", tempLib);
        return tempLib.toAbsolutePath().toString();
    }
}
