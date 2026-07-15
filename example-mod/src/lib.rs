//! Example RustCraft Mod
//!
//! This is an example mod demonstrating the capabilities of RustCraft.
//! It shows how to create a simple mod using the RustCraft API.

#[macro_use]
extern crate rustcraft_api;

use rustcraft_api::{ModContext, ModLogger, ModMetadata, RustCraftMod};
use std::time::{SystemTime, UNIX_EPOCH};

/// Example mod implementation
struct ExampleMod {
    logger: ModLogger,
    init_time: u64,
    tick_count: u64,
}

impl ExampleMod {
    /// Create a new instance of the example mod
    fn new() -> Self {
        Self {
            logger: ModLogger::new(std::ptr::null()),
            init_time: 0,
            tick_count: 0,
        }
    }
}

impl RustCraftMod for ExampleMod {
    /// Get the mod metadata
    fn metadata() -> ModMetadata {
        ModMetadata {
            id: "rustcraft_example".to_string(),
            name: "RustCraft Example Mod".to_string(),
            version: "1.0.0".to_string(),
            description: "An example mod demonstrating RustCraft capabilities".to_string(),
            authors: vec!["RustCraft Team".to_string()],
        }
    }

    /// Called when the mod is initialized
    fn on_init(&mut self, context: &ModContext) {
        // Initialize logger with the provided context
        self.logger = ModLogger::new(context);

        // Log initialization
        self.logger.info("RustCraft Example Mod is initializing!");
        self.logger
            .info("This mod demonstrates RustCraft capabilities");

        // Store initialization time
        self.init_time = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        self.logger
            .info(&format!("Initialized at timestamp: {}", self.init_time));

        // Demonstrate various log levels
        self.logger.info("This is an info message");
        self.logger.warn("This is a warning message");
        self.logger
            .error("This is an error message (demonstration only)");

        self.logger.info("Example mod initialized successfully!");
    }

    /// Called every game tick
    fn on_tick(&mut self) {
        self.tick_count += 1;

        // Log every 20 ticks (once per second at 20 TPS)
        if self.tick_count.is_multiple_of(20) {
            self.logger
                .info(&format!("Tick count: {}", self.tick_count));
        }
    }

    /// Called when the mod is shutting down
    fn on_shutdown(&mut self) {
        self.logger
            .info("RustCraft Example Mod is shutting down...");

        let shutdown_time = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        let uptime = shutdown_time.saturating_sub(self.init_time);
        self.logger.info(&format!("Mod uptime: {} seconds", uptime));
        self.logger
            .info(&format!("Total ticks: {}", self.tick_count));

        self.logger.info("Example mod shutdown complete!");
    }
}

// Use the rustcraft_mod macro to register the mod
rustcraft_mod!(ExampleMod);

#[cfg(test)]
mod tests {
    use super::*;
    use rustcraft_api::RustCraftMod;

    #[test]
    fn test_metadata() {
        let metadata = ExampleMod::metadata();
        assert_eq!(metadata.id, "rustcraft_example");
        assert_eq!(metadata.name, "RustCraft Example Mod");
        assert_eq!(metadata.version, "1.0.0");
        assert!(!metadata.description.is_empty());
        assert!(!metadata.authors.is_empty());
    }

    #[test]
    fn test_new() {
        let example = ExampleMod::new();
        assert_eq!(example.tick_count, 0);
        assert_eq!(example.init_time, 0);
    }

    #[test]
    fn test_on_tick() {
        let mut example = ExampleMod::new();
        example.on_tick();
        assert_eq!(example.tick_count, 1);
        example.on_tick();
        example.on_tick();
        assert_eq!(example.tick_count, 3);
    }
}
