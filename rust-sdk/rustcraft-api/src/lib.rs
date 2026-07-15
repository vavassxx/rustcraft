//! RustCraft API
//!
//! This library provides the API for developing Minecraft mods in Rust
//! that can be loaded via the RustCraft Fabric mod.

use std::ffi::{CString, CStr};
use std::os::raw::c_char;

/// Mod context provided by RustCraft
#[repr(C)]
pub struct ModContext {
    pub mod_id: *const c_char,
    pub mod_version: *const c_char,
    pub log_info: Option<extern "C" fn(*const c_char)>,
    pub log_warn: Option<extern "C" fn(*const c_char)>,
    pub log_error: Option<extern "C" fn(*const c_char)>,
}

/// Mod metadata
#[derive(Debug, Clone)]
pub struct ModMetadata {
    pub id: String,
    pub name: String,
    pub version: String,
    pub description: String,
    pub authors: Vec<String>,
}

/// Trait that all RustCraft mods must implement
pub trait RustCraftMod {
    /// Get the mod metadata
    fn metadata() -> ModMetadata;
    
    /// Called when the mod is initialized
    fn on_init(&mut self, context: &ModContext);
    
    /// Called every game tick
    fn on_tick(&mut self);
    
    /// Called when the mod is shutting down
    fn on_shutdown(&mut self);
}

/// Logger for mods
pub struct ModLogger {
    context: *const ModContext,
}

impl ModLogger {
    /// Create a new mod logger
    pub fn new(context: *const ModContext) -> Self {
        Self { context }
    }
    
    /// Log an info message
    pub fn info(&self, message: &str) {
        if self.context.is_null() {
            return;
        }
        
        unsafe {
            let ctx = &*self.context;
            if let Some(log_fn) = ctx.log_info {
                let c_msg = CString::new(message).unwrap();
                log_fn(c_msg.as_ptr());
            }
        }
    }
    
    /// Log a warning message
    pub fn warn(&self, message: &str) {
        if self.context.is_null() {
            return;
        }
        
        unsafe {
            let ctx = &*self.context;
            if let Some(log_fn) = ctx.log_warn {
                let c_msg = CString::new(message).unwrap();
                log_fn(c_msg.as_ptr());
            }
        }
    }
    
    /// Log an error message
    pub fn error(&self, message: &str) {
        if self.context.is_null() {
            return;
        }
        
        unsafe {
            let ctx = &*self.context;
            if let Some(log_fn) = ctx.log_error {
                let c_msg = CString::new(message).unwrap();
                log_fn(c_msg.as_ptr());
            }
        }
    }
}

/// Macro to simplify mod creation
#[macro_export]
macro_rules! rustcraft_mod {
    ($mod_type:ty) => {
        static mut MOD_INSTANCE: Option<$mod_type> = None;
        static mut MOD_CONTEXT: Option<*const $crate::ModContext> = None;
        
        #[no_mangle]
        pub extern "C" fn rustcraft_mod_init() -> *mut $crate::ModContext {
            use $crate::RustCraftMod;
            
            let metadata = <$mod_type>::metadata();
            
            // Create mod instance
            let mod_instance = <$mod_type>::new();
            unsafe {
                MOD_INSTANCE = Some(mod_instance);
            }
            
            // Create context
            let mod_id = std::ffi::CString::new(metadata.id).unwrap();
            let mod_version = std::ffi::CString::new(metadata.version).unwrap();
            
            let context = Box::new($crate::ModContext {
                mod_id: mod_id.into_raw(),
                mod_version: mod_version.into_raw(),
                log_info: Some($crate::default_log_info),
                log_warn: Some($crate::default_log_warn),
                log_error: Some($crate::default_log_error),
            });
            
            let context_ptr = Box::into_raw(context);
            
            unsafe {
                MOD_CONTEXT = Some(context_ptr);
                
                if let Some(ref mut mod_instance) = MOD_INSTANCE {
                    mod_instance.on_init(&*context_ptr);
                }
            }
            
            context_ptr
        }
        
        #[no_mangle]
        #[allow(clippy::not_unsafe_ptr_arg_deref)]
        pub extern "C" fn rustcraft_mod_shutdown(context: *mut $crate::ModContext) {
            use $crate::RustCraftMod;
            
            unsafe {
                if let Some(ref mut mod_instance) = MOD_INSTANCE {
                    mod_instance.on_shutdown();
                }
                
                MOD_INSTANCE = None;
                MOD_CONTEXT = None;
                
                if !context.is_null() {
                    let _ = Box::from_raw(context);
                }
            }
        }
    };
}

/// Default logging implementations
pub extern "C" fn default_log_info(message: *const c_char) {
    if message.is_null() {
        return;
    }
    unsafe {
        let cstr = CStr::from_ptr(message);
        println!("[RustCraft Mod] INFO: {}", cstr.to_string_lossy());
    }
}

pub extern "C" fn default_log_warn(message: *const c_char) {
    if message.is_null() {
        return;
    }
    unsafe {
        let cstr = CStr::from_ptr(message);
        println!("[RustCraft Mod] WARN: {}", cstr.to_string_lossy());
    }
}

pub extern "C" fn default_log_error(message: *const c_char) {
    if message.is_null() {
        return;
    }
    unsafe {
        let cstr = CStr::from_ptr(message);
        eprintln!("[RustCraft Mod] ERROR: {}", cstr.to_string_lossy());
    }
}
