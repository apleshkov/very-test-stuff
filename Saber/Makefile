PREFIX ?= /usr/local
INST_FOLDER = $(PREFIX)/bin

SWIFT_BUILD_FLAGS=--configuration release

BIN_PATH = $(shell swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)

clean:
	swift package clean

build:
	swift build $(SWIFT_BUILD_FLAGS)

install: clean build
	install -d "$(INST_FOLDER)"
	install "$(BIN_PATH)/SaberCLI" "$(INST_FOLDER)/saber"

uninstall:
	rm -rf "$(INST_FOLDER)/saber"

test:
	swift test
