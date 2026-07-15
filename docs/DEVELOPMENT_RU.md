# Руководство разработчика RustCraft

Это руководство описывает разработку модов с помощью RustCraft и внесение вклада в проект.

## Разработка модов на Rust

### Начало работы

1. **Настройте RustCraft SDK**
   ```bash
   cd rust-sdk
   cargo build --release -p rustcraft-core
   ```

2. **Создайте новый проект мода**
   ```bash
   cargo new my_mod --lib
   cd my_mod
   ```

3. **Настройте Cargo.toml**
   ```toml
   [package]
   name = "my_mod"
   version = "0.1.0"
   edition = "2021"

   [lib]
   name = "my_mod"
   crate-type = ["cdylib"]

   [dependencies]
   rustcraft-api = { path = "path/to/rust-sdk/rustcraft-api" }
   log = "0.4"
   ```

4. **Реализуйте свой мод**
   Смотрите пример мода как шаблон.

### Справочник API

#### Трейт RustCraftMod

Все моды RustCraft должны реализовывать трейт `RustCraftMod`:

```rust
use rustcraft_api::{RustCraftMod, ModMetadata, ModContext};

struct MyMod {
    // Состояние вашего мода
}

impl RustCraftMod for MyMod {
    fn metadata() -> ModMetadata {
        ModMetadata {
            id: "my_mod".to_string(),
            name: "My Mod".to_string(),
            version: "0.1.0".to_string(),
            description: "Описание".to_string(),
            authors: vec!["Ваше имя".to_string()],
        }
    }

    fn on_init(&mut self, context: &ModContext) {
        // Логика инициализации
    }

    fn on_shutdown(&mut self) {
        // Логика очистки
    }
}

rustcraft_mod!(MyMod);
```

#### ModContext

`ModContext` предоставляет информацию и функции логирования:

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

#### ModLogger

Помощник для логирования:

```rust
use rustcraft_api::ModLogger;

let logger = ModLogger::new(context);
logger.info("Информационное сообщение");
logger.warn("Предупреждение");
logger.error("Сообщение об ошибке");
```

### Сборка мода

```bash
cargo build --release
```

Результат будет位于:
- Linux: `target/release/libmy_mod.so`
- macOS: `target/release/libmy_mod.dylib`
- Windows: `target/release/my_mod.dll`

### Тестирование мода

1. Соберите мод
2. Скопируйте библиотеку в папку модов Minecraft
3. Запустите Minecraft с установленным RustCraft
4. Проверьте логи на наличие вывода вашего мода

## Продвинутые темы

### Зависимости модов

Моды могут объявлять зависимости в своих метаданных:

```rust
fn metadata() -> ModMetadata {
    ModMetadata {
        // ... другие поля
        dependencies: vec![
            "other_mod".to_string(),
        ],
    }
}
```

### Обработка событий

В настоящее время RustCraft поддерживает базовые события жизненного цикла. Будущие версии включат:

- События тиков игры
- События игрока
- События блоков
- События сущностей

### Взаимодействие с Java

Для продвинутого взаимодействия с Java можно использовать JNI напрямую:

```rust
use jni::JNIEnv;
use jni::objects::{JClass, JObject};

#[no_mangle]
pub extern "C" fn Java_com_example_MyClass_nativeMethod(
    env: JNIEnv,
    _class: JClass,
    obj: JObject,
) {
    // Ваш JNI-код здесь
}
```

## Участие в проекте RustCraft

### Настройка среды разработки

1. Форкните репозиторий
2. Клонируйте свой форк
3. Соберите всё: `make mods`
4. Запустите клиент: `make run`

### Стиль кода

- Следуйте соглашениям об именовании Rust
- Используйте `cargo fmt` для форматирования
- Используйте `cargo clippy` для линтинга
- Добавляйте комментарии к публичным API

### Тестирование

```bash
# Запуск тестов Rust
cd rust-sdk
cargo test

# Запуск тестов Java
cd fabric-loader
./gradlew test
```

### Отправка изменений

1. Создайте новую ветку
2. Внесите изменения
3. Добавьте тесты, если применимо
4. Обновите документацию
5. Отправьте pull request

### Структура проекта

```
rustcraft/
├── Makefile               # Сборка одной командой (make mods / make run)
├── fabric-loader/          # Java Fabric мод (загрузчик)
│   ├── src/main/java/
│   │   └── com/rustcraft/
│   │       ├── RustCraftMod.java
│   │       ├── RustModLoader.java
│   │       ├── RustNativeBridge.java
│   │       └── mod/
│   └── src/main/resources/
├── rust-sdk/              # Rust SDK
│   ├── rustcraft-core/    # Ядро нативной библиотеки
│   └── rustcraft-api/     # API для разработчиков модов
├── example-mod/           # Пример мода на Rust
│   ├── src/lib.rs         # Исходный код мода на Rust
│   └── wrapper/           # Java-обёртка для загрузки через Fabric
└── docs/                  # Документация
```

## Архитектура

### Java-сторона

- **RustCraftMod**: Основная точка входа загрузчика
- **RustModLoader**: Управляет жизненным циклом загрузки модов
- **RustNativeBridge**: JNI-мост к нативному коду
- **RustMod**: Представляет загруженный мод
- **RustModWrapper**: Интерфейс для Java-обёрток модов на Rust

### Rust-сторона

- **rustcraft-core**: Ядро нативной библиотеки с функциями JNI
- **rustcraft-api**: Высокоуровневый API для разработчиков модов

### Процесс загрузки

1. Fabric загружает entrypoint `RustCraftMod`
2. `RustCraftMod` создаёт `RustModLoader`, который инициализирует `RustNativeBridge` и загружает ядро нативной библиотеки из ресурсов JAR
3. Fabric обнаруживает Java-обёртки модов через `fabric.mod.json` и вызывает их `onInitialize()`
4. Каждая обёртка извлекает нативную библиотеку (.so/.dll/.dylib) из своего JAR во временную директорию
5. Обёртка опрашивает `RustModLoader` (т.к. порядок инициализации entrypoint'ов не гарантирован)
6. Найдя загрузчик, обёртка создаёт реализацию `RustModWrapper` и вызывает `registerMod()`
7. `RustModLoader` загружает нативную библиотеку через `RustNativeBridge` и вызывает `rustcraft_mod_init`

## Соображения по производительности

### Размер нативной библиотеки

- Используйте LTO (Link Time Optimization) в release-сборках
- Удаляйте отладочные символы: `cargo build --release --strip`
- Рассмотрите использование `panic = "abort"` в Cargo.toml

### Управление памятью

- Система владения Rust предотвращает утечки памяти
- Будьте осторожны на границах FFI
- Используйте подходящие структуры данных для вашей задачи

### Потокобезопасность

- Типизированная система Rust обеспечивает потокобезопасность
- Избегайте разделяемого изменяемого состояния между потоками
- Используйте каналы для коммуникации между потоками

## Отладка

### Java-сторона

Включите отладочное логирование в `fabric.mod.json`:

```json
{
  "custom": {
    "rustcraft:debug": true
  }
}
```

### Rust-сторона

Используйте crate `log` с `env_logger`:

```rust
env_logger::init();
log::info!("Отладочное сообщение");
```

### Нативные краши

Если нативная библиотека падает:

1. Проверьте логи крашей
2. Используйте отладчик (gdb, lldb, Visual Studio Debugger)
3. Включите отладочные символы в нативной сборке

## Лучшие практики

1. **Обработка ошибок**: Используйте типы `Result` для операций, которые могут завершиться ошибкой
2. **Логирование**: Логируйте важные события и ошибки
3. **Тестирование**: Пишите модульные тесты для логики мода
4. **Документация**: Документируйте свой публичный API
5. **Версионирование**: Используйте семантическое версионирование для мода
6. **Совместимость**: Тестируйте на нескольких версиях Minecraft

## Ресурсы

- [The Rust Book](https://doc.rust-lang.org/book/)
- [JNI Specification](https://docs.oracle.com/javase/8/docs/technotes/guides/jni/)
- [Fabric Documentation](https://fabricmc.net/wiki/)
- [Minecraft Wiki](https://minecraft.fandom.com/)
