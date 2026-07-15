use jni::objects::{JObject, JString};
use jni::sys::{jlong, jstring};
use jni::JNIEnv;
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};

struct RustCraftContext {
    mods: HashMap<String, jlong>,
    last_error: String,
}

/// Represents a loaded native mod.
///
/// # Safety invariants
/// - Access to a `ModHandle` from different threads is serialized by the
///   Java calling convention (init/shutdown/tick are never concurrent for
///   the same mod). The `valid` flag provides a runtime check.
/// - A `ModHandle` must not be accessed after `unload()` has been called.
struct ModHandle {
    id: String,
    library: Option<libloading::Library>,
    context: Option<*mut ModContext>,
    valid: AtomicBool,
}

// SAFETY: ModHandle is accessed from JNI threads. Access is serialized by
// the Java calling convention (one mod is never initialized/shut down from
// multiple threads simultaneously). The `valid` flag guards against use-after-free.
unsafe impl Send for ModHandle {}
unsafe impl Sync for ModHandle {}

#[repr(C)]
pub struct ModContext {
    pub mod_id: *const std::os::raw::c_char,
    pub mod_version: *const std::os::raw::c_char,
    pub log_info: Option<extern "C" fn(*const std::os::raw::c_char)>,
    pub log_warn: Option<extern "C" fn(*const std::os::raw::c_char)>,
    pub log_error: Option<extern "C" fn(*const std::os::raw::c_char)>,
}

lazy_static::lazy_static! {
    static ref CONTEXT: Arc<Mutex<RustCraftContext>> = Arc::new(Mutex::new(RustCraftContext {
        mods: HashMap::new(),
        last_error: String::new(),
    }));
}

// --- JNI exports ---

#[no_mangle]
pub extern "system" fn Java_com_rustcraft_RustNativeBridge_nativeInit(
    _env: JNIEnv,
    _this: JObject,
) -> jlong {
    log::info!("Initializing RustCraft core");
    let _ = env_logger::try_init();
    1
}

#[no_mangle]
pub extern "system" fn Java_com_rustcraft_RustNativeBridge_nativeShutdown(
    _env: JNIEnv,
    _this: JObject,
    _context: jlong,
) {
    log::info!("Shutting down RustCraft core");

    let mut ctx = CONTEXT.lock().unwrap();

    for (id, handle) in ctx.mods.drain() {
        log::info!("Unloading mod: {}", id);
        let ptr = handle as *mut ModHandle;
        if !ptr.is_null() {
            unsafe {
                let mh = &mut *ptr;
                if let Some(ref library) = mh.library {
                    if let Some(mod_ctx) = mh.context {
                        if let Ok(f) =
                            library.get::<extern "C" fn(*mut ModContext)>(b"rustcraft_mod_shutdown")
                        {
                            f(mod_ctx);
                        }
                    }
                }
                let _ = Box::from_raw(ptr);
            }
        }
    }
}

#[no_mangle]
pub extern "system" fn Java_com_rustcraft_RustNativeBridge_nativeLoadMod(
    mut env: JNIEnv,
    _this: JObject,
    _context: jlong,
    mod_path: JObject,
    mod_id: JObject,
) -> jlong {
    let mod_path_str: String = {
        let jstr: JString = mod_path.into();
        let java_str = match env.get_string(&jstr) {
            Ok(s) => s,
            Err(e) => {
                log::error!("Failed to get mod path: {}", e);
                return 0;
            }
        };
        java_str.into()
    };

    let mod_id_str: String = {
        let jstr: JString = mod_id.into();
        let java_str = match env.get_string(&jstr) {
            Ok(s) => s,
            Err(e) => {
                log::error!("Failed to get mod id: {}", e);
                return 0;
            }
        };
        java_str.into()
    };

    log::info!("Loading mod: {} from {}", mod_id_str, mod_path_str);

    let library = match unsafe { libloading::Library::new(&mod_path_str) } {
        Ok(lib) => lib,
        Err(e) => {
            log::error!("Failed to load library: {}", e);
            let mut ctx = CONTEXT.lock().unwrap();
            ctx.last_error = format!("Failed to load library: {}", e);
            return 0;
        }
    };

    let has_init = unsafe {
        library
            .get::<extern "C" fn() -> *mut ModContext>(b"rustcraft_mod_init")
            .is_ok()
    };
    let has_shutdown = unsafe {
        library
            .get::<extern "C" fn(*mut ModContext)>(b"rustcraft_mod_shutdown")
            .is_ok()
    };

    if !has_init {
        log::warn!("Mod {} does not export rustcraft_mod_init", mod_id_str);
    }
    if !has_shutdown {
        log::warn!("Mod {} does not export rustcraft_mod_shutdown", mod_id_str);
    }

    let mh = Box::new(ModHandle {
        id: mod_id_str.clone(),
        library: Some(library),
        context: None,
        valid: AtomicBool::new(true),
    });

    let handle_ptr = Box::into_raw(mh) as jlong;

    let mut ctx = CONTEXT.lock().unwrap();
    ctx.mods.insert(mod_id_str, handle_ptr);

    log::info!("Mod loaded successfully");
    handle_ptr
}

#[no_mangle]
pub extern "system" fn Java_com_rustcraft_RustNativeBridge_nativeUnloadMod(
    _env: JNIEnv,
    _this: JObject,
    _context: jlong,
    mod_handle: jlong,
) {
    if mod_handle == 0 {
        return;
    }

    let ptr = mod_handle as *mut ModHandle;
    unsafe {
        let mh = &mut *ptr;
        if !mh.valid.load(Ordering::Acquire) {
            log::warn!("Attempted to unload already-invalid mod: {}", mh.id);
            return;
        }
        log::info!("Unloading mod: {}", mh.id);
        mh.valid.store(false, Ordering::Release);

        let mut ctx = CONTEXT.lock().unwrap();
        ctx.mods.remove(&mh.id);
        let _ = Box::from_raw(ptr);
    }
}

#[no_mangle]
pub extern "system" fn Java_com_rustcraft_RustNativeBridge_nativeCallModInit(
    _env: JNIEnv,
    _this: JObject,
    mod_handle: jlong,
) {
    if mod_handle == 0 {
        return;
    }

    unsafe {
        let mh = &mut *(mod_handle as *mut ModHandle);
        if !mh.valid.load(Ordering::Acquire) {
            log::warn!("Attempted to init invalid mod: {}", mh.id);
            return;
        }
        if let Some(ref library) = mh.library {
            log::info!("Calling init for mod: {}", mh.id);
            if let Ok(f) = library.get::<extern "C" fn() -> *mut ModContext>(b"rustcraft_mod_init")
            {
                let ctx = f();
                mh.context = Some(ctx);
                log::info!("Mod initialized: {}", mh.id);
            } else {
                log::warn!("Mod {} does not have rustcraft_mod_init", mh.id);
            }
        }
    }
}

#[no_mangle]
pub extern "system" fn Java_com_rustcraft_RustNativeBridge_nativeCallModShutdown(
    _env: JNIEnv,
    _this: JObject,
    mod_handle: jlong,
) {
    if mod_handle == 0 {
        return;
    }

    unsafe {
        let mh = &mut *(mod_handle as *mut ModHandle);
        if !mh.valid.load(Ordering::Acquire) {
            log::warn!("Attempted to shutdown invalid mod: {}", mh.id);
            return;
        }
        if let Some(ref library) = mh.library {
            if let Some(mod_ctx) = mh.context {
                log::info!("Calling shutdown for mod: {}", mh.id);
                if let Ok(f) =
                    library.get::<extern "C" fn(*mut ModContext)>(b"rustcraft_mod_shutdown")
                {
                    f(mod_ctx);
                    mh.context = None;
                }
            }
        }
    }
}

#[no_mangle]
pub extern "system" fn Java_com_rustcraft_RustNativeBridge_nativeGetLastError(
    env: JNIEnv,
    _this: JObject,
    _context: jlong,
) -> jstring {
    let ctx = CONTEXT.lock().unwrap();
    if ctx.last_error.is_empty() {
        return std::ptr::null_mut();
    }
    match env.new_string(&ctx.last_error) {
        Ok(s) => s.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}
