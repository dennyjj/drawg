PRODUCT_NAME = Drawg
BUNDLE_NAME = $(PRODUCT_NAME).app
BUILD_DIR = .build/release
APP_DIR = $(BUILD_DIR)/$(BUNDLE_NAME)
INSTALL_DIR = /Applications

.PHONY: build bundle install clean

build:
	swift build -c release

bundle: build
	@echo "Creating app bundle..."
	rm -rf "$(APP_DIR)"
	mkdir -p "$(APP_DIR)/Contents/MacOS"
	mkdir -p "$(APP_DIR)/Contents/Resources"
	cp "$(BUILD_DIR)/Drawg" "$(APP_DIR)/Contents/MacOS/$(PRODUCT_NAME)"
	cp "Resources/Info.plist" "$(APP_DIR)/Contents/Info.plist"
	@# Copy SPM resource bundles (KeyboardShortcuts localization, etc.)
	@for bundle in $(BUILD_DIR)/*.bundle; do \
		[ -d "$$bundle" ] && cp -R "$$bundle" "$(APP_DIR)/Contents/Resources/"; \
	done
	@# Ad-hoc codesign for stable identity (screen recording permission persists across installs)
	codesign --force --sign - --identifier com.drawg.app "$(APP_DIR)"
	@echo "App bundle created at $(APP_DIR)"

install: bundle
	@echo "Installing to $(INSTALL_DIR)..."
	rm -rf "$(INSTALL_DIR)/$(BUNDLE_NAME)"
	cp -R "$(APP_DIR)" "$(INSTALL_DIR)/$(BUNDLE_NAME)"
	@echo "Installed $(BUNDLE_NAME) to $(INSTALL_DIR)"

run: bundle
	open "$(APP_DIR)"

dist: bundle
	@echo "Creating distribution archive..."
	cd "$(BUILD_DIR)" && zip -r "Drawg.zip" "$(BUNDLE_NAME)"
	@echo "Archive created at $(BUILD_DIR)/Drawg.zip"
	@shasum -a 256 "$(BUILD_DIR)/Drawg.zip"

clean:
	swift package clean
	rm -rf "$(APP_DIR)" "$(BUILD_DIR)/Drawg.zip"
