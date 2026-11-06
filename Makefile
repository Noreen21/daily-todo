APP_NAME := DailyTodo
APP_DIR := build/$(APP_NAME).app
CONTENTS_DIR := $(APP_DIR)/Contents
MACOS_DIR := $(CONTENTS_DIR)/MacOS
RESOURCES_DIR := $(CONTENTS_DIR)/Resources
SWIFT_ENV := HOME=$(CURDIR)/.build/home XDG_CACHE_HOME=$(CURDIR)/.build/cache CLANG_MODULE_CACHE_PATH=$(CURDIR)/.build/module-cache
SWIFT_FLAGS ?= --scratch-path .build
ARM64_BINARY := .build/arm64-apple-macosx/release/$(APP_NAME)
X86_64_BINARY := .build/x86_64-apple-macosx/release/$(APP_NAME)

.PHONY: all app test clean

all: app

app:
	mkdir -p .build/home .build/cache .build/module-cache
	$(SWIFT_ENV) swift build -c release $(SWIFT_FLAGS) --triple arm64-apple-macosx14.0
	$(SWIFT_ENV) swift build -c release $(SWIFT_FLAGS) --triple x86_64-apple-macosx14.0
	rm -rf "$(APP_DIR)"
	mkdir -p "$(MACOS_DIR)" "$(RESOURCES_DIR)"
	lipo -create -output "$(MACOS_DIR)/$(APP_NAME)" "$(ARM64_BINARY)" "$(X86_64_BINARY)"
	cp Resources/Info.plist "$(CONTENTS_DIR)/Info.plist"
	cp Resources/PrivacyInfo.xcprivacy "$(RESOURCES_DIR)/PrivacyInfo.xcprivacy"
	cp LICENSE "$(RESOURCES_DIR)/LICENSE"
	codesign --force --sign - --entitlements Resources/DailyTodo.entitlements "$(APP_DIR)"

test:
	mkdir -p .build/home .build/cache .build/module-cache
	$(SWIFT_ENV) swift run $(SWIFT_FLAGS) DailyTodoChecks

clean:
	swift package clean
	rm -rf build
