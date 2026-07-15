<div align="center">

# RustCraft

**Пишите моды для Minecraft на Rust.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Rust](https://img.shields.io/badge/Rust-1.70+-orange.svg)](https://www.rust-lang.org/)
[![Fabric](https://img.shields.io/badge/Fabric-Loader-blue.svg)](https://fabricmc.net/)
[![Minecraft](https://img.shields.io/badge/Minecraft-1.18+-darkgreen.svg)](https://www.minecraft.net/)

[English Documentation](README.md) · [API Reference](docs/API_REFERENCE.md) · [Development Guide](docs/DEVELOPMENT.md)

</div>

---

## Что такое RustCraft?

RustCraft — это мод для Fabric, который позволяет писать моды для Minecraft на языке Rust. Он обеспечивает JNI-мост между Java и Rust, позволяя модам на Rust работать вместе с традиционными модами Fabric с минимальными накладными расходами.

### Почему Rust для Minecraft?

- **Безопасность памяти** — отсутствие разыменования нулевых указателей, переполнения буферов и гонок данных
- **Без сборщика мусора** — отсутствие пауз GC, стабильное время кадров
- **Безопасная конкуррентность** — параллелизм без блокировок и contention
- **Нативная производительность** — компиляция в машинный код, нет накладных расходов JVM
- **Малый объём** — каждый мод добавляет ~2-5 МБ против 10-100+ МБ для Java-модов

## Архитектура

```
┌─────────────────────────────────────────────┐
│                 Minecraft                    │
│  ┌──────────────────────────────────────┐   │
│  │           Fabric Loader               │   │
│  │  ┌────────────────────────────────┐  │   │
│  │  │     RustCraft (Java Fabric Mod) │  │   │
│  │  │  ┌──────────────────────────┐   │  │   │
│  │  │  │    JNI Bridge (core)     │   │  │   │
│  │  │  └──────┬───────────┬──────┘   │  │   │
│  │  │         │           │           │  │   │
│  │  │  ┌──────┴───┐ ┌────┴──────┐   │  │   │
│  │  │  │ Rust Mod │ │ Rust Mod  │   │  │   │
│  │  │  │   (A)    │ │   (B)     │   │  │   │
│  │  │  └──────────┘ └───────────┘   │  │   │
│  │  └────────────────────────────────┘  │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

| Компонент | Язык | Назначение |
|-----------|------|------------|
| `fabric-loader` | Java | Интеграция с Fabric, обнаружение модов, управление жизненным циклом |
| `rustcraft-core` | Rust | JNI-мост, загрузка нативных модов, управление контекстом |
| `rustcraft-api` | Rust | Трейты, макросы и утилиты для разработчиков модов |
| `example-mod` | Rust | Эталонная реализация и шаблон |

## Быстрый старт

### Предварительные требования

- **Rust** 1.70+ ([rustup.rs](https://rustup.rs/))
- **Java** 17+ ([Adoptium](https://adoptium.net/) или [PrismLauncher](https://prismlauncher.org/))
- **Git**

### Сборка из исходников

```bash
git clone https://github.com/vavassxx/rustcraft.git
cd rustcraft
```

**Вариант А: Интерактивная сборка (рекомендуется)**

```bash
./run-client.sh          # Linux / macOS
run-client.bat           # Windows
```

Скрипт предложит выбрать версию Minecraft, соберёт всё и запустит клиент.

**Вариант Б: Одноразовая сборка**

```bash
./run-client.sh --version 1.20.1 --no-run    # Собрать для 1.20.1, не запускать
./run-client.sh --build-all                   # Собрать все поддерживаемые версии
```

**Вариант В: Ручная сборка**

```bash
# 1. Сборка ядра Rust
cd rust-sdk && cargo build --release

# 2. Сборка примера мода
cd ../example-mod && cargo build --release

# 3. Сборка JAR Fabric-загрузчика
cd ../fabric-loader && ./gradlew build

# 4. Сборка JAR обёртки примера мода
cd ../example-mod/wrapper && ./gradlew build
```

## Поддерживаемые версии

| Minecraft | Java | Fabric Loader | Статус |
|-----------|------|---------------|--------|
| 1.18.2    | 17   | 0.14.21       | Стабильная |
| 1.19.4    | 17   | 0.14.21       | Стабильная |
| 1.20.1    | 17   | 0.14.21       | Стабильная |
| 1.20.4    | 17   | 0.15.11       | Стабильная |
| 1.20.6    | 21   | 0.15.11       | Стабильная |
| 1.21      | 21   | 0.16.0        | Стабильная |
| 1.21.1    | 21   | 0.16.1        | Стабильная |
| 1.21.3    | 21   | 0.16.7        | Стабильная |
| 1.21.4    | 21   | 0.16.9        | Стабильная |
| 1.21.5    | 21   | 0.16.10       | Стабильная |

### Поддержка платформ

| Платформа | Архитектуры | Формат библиотеки |
|-----------|-------------|-------------------|
| Linux     | x64, aarch64 | `.so`            |
| Windows   | x64          | `.dll`           |
| macOS     | x64, aarch64 | `.dylib`         |

## Написание мода на Rust

```rust
use rustcraft_api::{RustCraftMod, ModMetadata, ModContext, ModLogger};

struct MyMod {
    logger: ModLogger,
}

impl RustCraftMod for MyMod {
    fn metadata() -> ModMetadata {
        ModMetadata {
            id: "my_mod".into(),
            name: "My Mod".into(),
            version: "1.0.0".into(),
            description: "Делает что-то крутое".into(),
            authors: vec!["Вы".into()],
        }
    }

    fn on_init(&mut self, ctx: &ModContext) {
        self.logger = ModLogger::new(ctx);
        self.logger.info("My Mod загружен!");
    }

    fn on_tick(&mut self) {
        // Вызывается каждый тик игры (20 раз/сек)
    }

    fn on_shutdown(&mut self) {
        self.logger.info("My Mod выгружен.");
    }
}

rustcraft_mod!(MyMod);
```

Полный рабочий пример: [example-mod/src/lib.rs](example-mod/src/lib.rs).

## Производительность

Сравнение производительности (загружено 100+ модов):

| Метрика | Java-моды | Rust-моды |
|---------|-----------|-----------|
| Потребление памяти на мод | 10-100+ МБ | 2-5 МБ |
| Паузы GC | Каждые 5-10 сек | Отсутствуют |
| Накладные расходы при запуске | Значительные | ~100 мс суммарно |
| Стабильность времени кадров | Переменная | Стабильная |

## Документация

- [Руководство по установке](docs/INSTALLATION.md) — Для игроков
- [Руководство разработчика](docs/DEVELOPMENT.md) — Для разработчиков модов
- [Справочник API](docs/API_REFERENCE.md) — Полная документация API
- [Руководство совместимости](docs/COMPATIBILITY.md) — Совместимость с модами

## Участие в проекте

Приглашаем к участию! Ознакомьтесь с [CONTRIBUTING.md](CONTRIBUTING.md).

## Лицензия

Проект распространяется под лицензией [MIT](LICENSE).
