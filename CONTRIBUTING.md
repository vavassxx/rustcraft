# Contributing to RustCraft

Thank you for your interest in contributing to RustCraft!

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch: `git checkout -b feature/my-feature`
4. Make your changes
5. Test your changes
6. Commit with a descriptive message
7. Push and create a Pull Request

## Development Setup

### Prerequisites

- Rust 1.70+
- Java 17+
- Git

### Building

```bash
# Build everything and launch client
./run-client.sh

# Or build manually
cd rust-sdk && cargo build --release
cd ../example-mod && cargo build --release
cd ../fabric-loader && ./gradlew build
```

### Running Tests

```bash
cd rust-sdk && cargo test
cd ../example-mod && cargo test
```

## Code Style

### Rust

- Follow standard Rust formatting (`cargo fmt`)
- Pass all clippy lints (`cargo clippy`)
- Add doc comments for public APIs

### Java

- Follow Fabric mod conventions
- Use SLF4J for logging
- Keep JNI bridge code minimal

## Pull Request Guidelines

- One feature/fix per PR
- Include a description of what changed and why
- Add tests for new functionality
- Update documentation if needed
- Ensure all checks pass

## Reporting Issues

- Use GitHub Issues
- Include Minecraft version, Java version, and OS
- Provide crash logs if applicable
- Describe steps to reproduce

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
