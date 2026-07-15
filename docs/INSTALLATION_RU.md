# Руководство по установке RustCraft

Это руководство описывает установку RustCraft для игроков и разработчиков.

## Для игроков

### Предварительные требования

- Minecraft Java Edition
- Fabric Loader (совместимый с вашей версией Minecraft)
- Java 17 или новее

### Шаги установки

1. **Установите Fabric Loader**
   - Скачайте Fabric Installer с [fabricmc.net](https://fabricmc.net/)
   - Запустите установщик и выберите версию Minecraft
   - Создайте новый профиль Fabric или установите в существующий профиль

2. **Скачайте RustCraft**
   - Скачайте последний JAR загрузчика RustCraft для вашей версии Minecraft
   - Поместите файл `.jar` в каталог `.minecraft/mods`

3. **Установите моды на Rust**
   - Скачайте JAR-обёртки модов на Rust
   - Поместите их в каталог `.minecraft/mods`
   - RustCraft автоматически обнаружит и загрузит их
   - Нативные библиотеки (.so/.dll/.dylib) извлекаются из JAR автоматически

4. **Запустите Minecraft**
   - Запустите Minecraft с профилем Fabric
   - Проверьте логи, чтобы убедиться, что RustCraft загрузился успешно

### Проверка установки

Откройте логи Minecraft (`.minecraft/logs/latest.log`) и найдите:

```
[RustCraft] Initializing RustCraft...
[RustCraft/Loader] Initializing Rust mod loader...
[RustCraft/Native] Native bridge initialized successfully
[RustCraft] RustCraft initialized successfully!
```

## Для разработчиков

### Предварительные требования

- Java 17 или новее
- Rust 1.70 или новее
- Git
- Gradle 8.5+ (включён в проект)

### Настройка среды разработки

1. **Клонируйте репозиторий**
   ```bash
   git clone https://github.com/vavassxx/rustcraft.git
   cd rustcraft
   ```

2. **Соберите всё**
   ```bash
   make mods
   ```
   Это соберёт Rust SDK, example-mod и скопирует все артефакты в нужные места.

3. **Запустите клиент**
   ```bash
   make run
   ```

#### Команды Makefile

| Команда | Описание |
|---------|----------|
| `make` / `make mods` | Собрать Rust SDK, wrapper example-mod и скопировать библиотеки |
| `make run` | Собрать всё и запустить клиент Minecraft |
| `make rust` | Собрать только Rust-крейты (rust-sdk + example-mod) |
| `make wrapper` | Собрать wrapper example-mod и скопировать в mods/ |
| `make clean` | Очистить все артефакты сборки |

#### Ручная сборка (без Make)

Если предпочитаете собирать вручную:

```bash
# Сборка Rust SDK
cd rust-sdk && cargo build --release

# Сборка example-mod
cd ../example-mod && cargo build --release
cd wrapper && ./gradlew build
cp build/libs/rustcraft-example-*.jar ../../fabric-loader/run/mods/

# Сборка и запуск fabric-loader
cd ../../fabric-loader && ./gradlew runClient
```

### Настройка IDE

#### IntelliJ IDEA

1. Откройте каталог `fabric-loader` как Gradle-проект
2. Позвольте IntelliJ импортировать Gradle-проект
3. Для разработки на Rust установите плагин Rust
4. Откройте каталог `rust-sdk` как отдельный Rust-проект

#### VS Code

1. Установите Java Extension Pack
2. Установите расширение Rust Analyzer
3. Откройте корень проекта
4. Рабочее пространство обнаружит как Java-, так и Rust-проекты

## Сборка из исходников

### Быстрая сборка

```bash
make mods
```

### Сборка Fabric Loader

```bash
cd fabric-loader
./gradlew clean build
```

Собранный JAR будет位于 `fabric-loader/build/libs/`.

### Сборка нативной библиотеки

```bash
cd rust-sdk && cargo build --release -p rustcraft-core
```

Собранная библиотека будет位于 `rust-sdk/rustcraft-core/target/release/`.

### Сборка для всех версий Minecraft

```bash
./run-client.sh --build-all
```

Это соберёт JAR для всех поддерживаемых версий Minecraft в `build-versions/`.

## Устранение неполадок

### Нативная библиотека не найдена

**Ошибка:** `Failed to load native library`

**Решение:**
- Убедитесь, что нативная библиотека собрана для вашей платформы
- Проверьте, что библиотека находится в правильном каталоге ресурсов
- Убедитесь, что архитектура библиотеки совпадает с вашей JVM (x64 vs x86)

### Мод не загружается

**Ошибка:** Мод появляется в папке mods, но не загружается

**Решение:**
- Убедитесь, что установлена последняя версия RustCraft
- Проверьте, что JAR-обёртка мода совместима с вашей версией Minecraft
- Проверьте логи на наличие конкретных сообщений об ошибках
- Убедитесь, что нативная библиотека внутри JAR собрана для вашей платформы

### Несовместимость версий

**Ошибка:** `Unsupported Minecraft version`

**Решение:**
- Используйте правильную версию RustCraft для вашей версии Minecraft
- Проверьте матрицу совместимости версий в документации

### Ошибки JNI

**Ошибка:** `JNI error occurred`

**Решение:**
- Убедитесь, что вы используете Java 17 или новее
- Проверьте, что нативная библиотека скомпилирована правильным тулчейном
- Проверьте совместимость версии JNI

## Заметки для конкретных платформ

### Windows

- Используйте MSVC тулчейн для Rust: `rustup default stable-x86_64-pc-windows-msvc`
- Установите Visual Studio Build Tools
- Нативные библиотеки используют расширение `.dll`

### Linux

- Используйте GNU тулчейн для Rust (по умолчанию)
- Установите необходимые инструменты сборки: `sudo apt install build-essential`
- Нативные библиотеки используют расширение `.so`

### macOS

- Установите Xcode Command Line Tools: `xcode-select --install`
- Нативные библиотеки используют расширение `.dylib`
- Может потребоваться отключение проверки библиотек для тестирования

## Удаление

### Удаление RustCraft

1. Удалите `rustcraft-loader-x.x.x.x.jar` из папки mods
2. Удалите JAR-обёртки модов на Rust из папки mods
3. Удалите каталог конфигурации RustCraft (опционально)

### Очистка среды разработки

```bash
make clean
```

Или вручную:

```bash
cd fabric-loader
./gradlew clean

cd ../rust-sdk
cargo clean
```
