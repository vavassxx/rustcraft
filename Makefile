.PHONY: all clean rust example wrapper mods run

JAVA_HOME ?= $(shell find /home -path "*/PrismLauncher/java/java-runtime-gamma/bin/java" 2>/dev/null | head -1 | sed 's|/bin/java||')
MODS_DIR = fabric-loader/run/mods

all: mods

rust:
	cd rust-sdk && cargo build --release
	cd example-mod && cargo build --release

example: rust
	cd example-mod/wrapper && JAVA_HOME=$(JAVA_HOME) ./gradlew build

wrapper: example
	mkdir -p $(MODS_DIR)
	cp example-mod/wrapper/build/libs/rustcraft-example-*.jar $(MODS_DIR)/

mods: wrapper
	cd fabric-loader && JAVA_HOME=$(JAVA_HOME) ./gradlew copyCoreLib processResources

run: mods
	cd fabric-loader && JAVA_HOME=$(JAVA_HOME) ./gradlew runClient

clean:
	cd rust-sdk && cargo clean
	cd example-mod && cargo clean
	cd example-mod/wrapper && JAVA_HOME=$(JAVA_HOME) ./gradlew clean 2>/dev/null || true
	cd fabric-loader && JAVA_HOME=$(JAVA_HOME) ./gradlew clean 2>/dev/null || true
	rm -rf $(MODS_DIR)
