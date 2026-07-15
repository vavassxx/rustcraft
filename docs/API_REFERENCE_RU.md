# Справочник API RustCraft

Полный справочник API для разработки модов RustCraft.

## Crate rustcraft-api

### Трейты

#### RustCraftMod

Основной трейт, который должны реализовать все моды RustCraft.

```rust
pub trait RustCraftMod {
    /// Получить метаданные мода
    fn metadata() -> ModMetadata;
    
    /// Вызывается при инициализации мода
    fn on_init(&mut self, context: &ModContext);
    
    /// Вызывается каждый тик игры
    fn on_tick(&mut self);
    
    /// Вызывается при завершении работы мода
    fn on_shutdown(&mut self);
}
```

**Методы:**

- `metadata()` — Возвращает статические метаданные мода
- `on_init()` — Вызывается один раз при загрузке мода
- `on_tick()` — Вызывается каждый тик игры
- `on_shutdown()` — Вызывается при выгрузке мода

### Структуры

#### ModMetadata

Метаданные, описывающие мод.

```rust
pub struct ModMetadata {
    pub id: String,
    pub name: String,
    pub version: String,
    pub description: String,
    pub authors: Vec<String>,
}
```

**Поля:**

- `id` — Уникальный идентификатор мода (например, "my_mod")
- `name` — Читаемое имя (например, "My Mod")
- `version` — Строка версии (например, "1.0.0")
- `description` — Краткое описание мода
- `authors` — Список имён авторов

#### ModContext

Контекст, предоставляемый модам RustCraft.

```rust
#[repr(C)]
pub struct ModContext {
    pub mod_id: *const c_char,
    pub mod_version: *const c_char,
    pub log_info: Option<extern "C" fn(*const c_char)>,
    pub log_warn: Option<extern "C" fn(*const c_char)>,
    pub log_error: Option<extern "C" fn(*const c_char)>,
}
```

**Поля:**

- `mod_id` — Указатель на строку ID мода, завершающуюся null
- `mod_version` — Указатель на строку версии, завершающуюся null
- `log_info` — Функция для логирования информационных сообщений
- `log_warn` — Функция для логирования предупреждений
- `log_error` — Функция для логирования ошибок

#### ModLogger

Вспомогательная структура для логирования сообщений.

```rust
pub struct ModLogger {
    context: *const ModContext,
}
```

**Методы:**

```rust
impl ModLogger {
    /// Создать новый логгер мода
    pub fn new(context: *const ModContext) -> Self;
    
    /// Логировать информационное сообщение
    pub fn info(&self, message: &str);
    
    /// Логировать предупреждение
    pub fn warn(&self, message: &str);
    
    /// Логировать ошибку
    pub fn error(&self, message: &str);
}
```

### Макросы

#### rustcraft_mod!

Макрос для упрощения регистрации мода.

```rust
rustcraft_mod!(MyModType);
```

Этот макрос генерирует необходимые функции C ABI:
- `rustcraft_mod_init` — Вызывается при загрузке мода
- `rustcraft_mod_shutdown` — Вызывается при выгрузке мода

**Требования:**

- Тип должен реализовывать `RustCraftMod`
- Тип должен иметь конструктор `new()`

## Crate rustcraft-core

### Функции C ABI

Эти функции вызываются из Java через JNI.

#### rustcraft_init

```c
long rustcraft_init();
```

Инициализирует контекст RustCraft.

**Возвращает:** Ненулевой дескриптор контекста при успехе, 0 при ошибке.

#### rustcraft_shutdown

```c
void rustcraft_shutdown(long context);
```

Завершает работу контекста RustCraft и выгружает все моды.

**Параметры:**
- `context` — Дескриптор контекста из `rustcraft_init`

#### rustcraft_load_mod

```c
long rustcraft_load_mod(long context, const char* mod_path, const char* mod_id);
```

Загружает мод на Rust из динамической библиотеки.

**Параметры:**
- `context` — Дескриптор контекста
- `mod_path` — Путь к файлу библиотеки мода
- `mod_id` — Уникальный идентификатор мода

**Возвращает:** Ненулевой дескриптор мода при успехе, 0 при ошибке.

#### rustcraft_unload_mod

```c
void rustcraft_unload_mod(long context, long mod_handle);
```

Выгружает ранее загруженный мод.

**Параметры:**
- `context` — Дескриптор контекста
- `mod_handle` — Дескриптор из `rustcraft_load_mod`

#### rustcraft_call_mod_init

```c
void rustcraft_call_mod_init(long mod_handle);
```

Вызывает функцию инициализации мода.

**Параметры:**
- `mod_handle` — Дескриптор мода

#### rustcraft_call_mod_shutdown

```c
void rustcraft_call_mod_shutdown(long mod_handle);
```

Вызывает функцию завершения работы мода.

**Параметры:**
- `mod_handle` — Дескриптор мода

#### rustcraft_get_last_error

```c
const char* rustcraft_get_last_error(long context);
```

Получает сообщение последней ошибки.

**Параметры:**
- `context` — Дескриптор контекста

**Возвращает:** Указатель на строку ошибки, завершающуюся null.

## Java API

### RustCraftMod

Основной класс точки входа.

```java
package com.rustcraft;

public class RustCraftMod implements ModInitializer {
    public static final String MOD_ID = "rustcraft";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);
    
    @Override
    public void onInitialize();
    
    public static RustModLoader getModLoader();
}
```

### RustModLoader

Управляет загрузкой и жизненным циклом модов на Rust.

```java
package com.rustcraft;

public class RustModLoader {
    public void initialize();
    public boolean registerMod(RustModWrapper wrapper);
    public void unregisterMod(String modId);
    public List<RustMod> getLoadedMods();
    public RustMod getMod(String id);
    public boolean isModLoaded(String id);
    public void shutdown();
}
```

### RustNativeBridge

JNI-мост для нативной коммуникации.

```java
package com.rustcraft;

public class RustNativeBridge {
    public boolean initialize();
    public void shutdown();
    public long loadMod(String modPath, String modId);
    public void unloadMod(long modHandle);
    public void callModInit(long modHandle);
    public void callModShutdown(long modHandle);
    public String getLastError();
    public boolean isInitialized();
}
```

### RustMod

Представляет загруженный мод на Rust.

```java
package com.rustcraft.mod;

public class RustMod {
    public void initialize();
    public void shutdown();
    public String getModId();
    public long getNativeHandle();
    public boolean isInitialized();
}
```

### RustModWrapper

Интерфейс, который должны реализовать Java-обёртки модов.

```java
package com.rustcraft.mod;

public interface RustModWrapper {
    String getNativeLibraryPath();
    String getModId();
}
```

## Совместимость версий

### Поддержка версий Minecraft

| Версия Minecraft | Версия Loader | Версия API |
|-------------------|---------------|------------|
| 1.18.2            | 0.14.21+      | 1.0        |
| 1.19.4            | 0.14.21+      | 1.0        |
| 1.20.1            | 0.14.21+      | 1.0        |
| 1.20.4            | 0.15.11+      | 1.0        |
| 1.21.5            | 0.16.0+       | 1.0        |

### Поддержка платформ

| Платформа | Архитектуры | Расширение библиотеки |
|-----------|-------------|----------------------|
| Linux     | x64, x86, ARM64 | .so              |
| Windows   | x64, x86      | .dll                |
| macOS     | x64, ARM64    | .dylib              |

## Обработка ошибок

Функции возвращают `0` при ошибке и ненулевой дескриптор при успехе. Используйте `rustcraft_get_last_error()` для получения сообщения об ошибке.

### Java-исключения

| Исключение | Описание |
|------------|----------|
| `IllegalStateException` | Нативный мост не инициализирован |
| `IOException` | Не удалось загрузить нативную библиотеку |
| `RuntimeException` | Нативная операция не удалась |

## Планы по развитию API

Планируемые функции для будущих версий:

- Регистрация команд
- Система конфигурации
- Загрузка ресурсов
- Поддержка сети
- Взаимодействие с сущностями/блоками
- API измерений/мира

## Примеры

Полные примеры смотрите в каталоге `example-mod`:
- Базовая структура мода
- Использование логирования
- Управление состоянием
- Обработка ошибок
