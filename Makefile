APP_DIR := apps/health_campaign_field_worker_app
APK_OUTPUT_DIR := $(APP_DIR)/build/app/outputs/flutter-apk
APK_SOURCE := $(APK_OUTPUT_DIR)/app-release.apk
KEY_PROPERTIES := $(APP_DIR)/android/key.properties
ifeq ($(OS),Windows_NT)
FLUTTER ?= flutter.bat
else
FLUTTER ?= fvm flutter
endif

.PHONY: help run-dev run-uat run-prod check-signing build-apk build-apk-dev build-apk-uat build-apk-prod

help:
	@echo "Commands:"
	@echo "  make run-dev         Run Android app with .env.dev"
	@echo "  make run-uat         Run Android app with .env.uat"
	@echo "  make run-prod        Run Android app with .env.prod"
	@echo "  make build-apk       Build signed release APK with .env.prod"
	@echo "  make build-apk-dev   Build release APK with .env.dev"
	@echo "  make build-apk-uat   Build release APK with .env.uat"
	@echo "  make build-apk-prod  Build release APK with .env.prod"
	@echo ""
	@echo "All build-apk targets generate SIGNED release APKs."

run-dev:
	cd $(APP_DIR) && $(FLUTTER) run --dart-define=ENV_FILE=.env.dev

run-uat:
	cd $(APP_DIR) && $(FLUTTER) run --dart-define=ENV_FILE=.env.uat

run-prod:
	cd $(APP_DIR) && $(FLUTTER) run --dart-define=ENV_FILE=.env.prod

check-signing:
	@test -f $(KEY_PROPERTIES) || (echo "Missing $(KEY_PROPERTIES)." && exit 1)
	@grep -q '^storePassword=' $(KEY_PROPERTIES) || (echo "storePassword missing in $(KEY_PROPERTIES)." && exit 1)
	@grep -q '^keyPassword=' $(KEY_PROPERTIES) || (echo "keyPassword missing in $(KEY_PROPERTIES)." && exit 1)
	@grep -q '^keyAlias=' $(KEY_PROPERTIES) || (echo "keyAlias missing in $(KEY_PROPERTIES)." && exit 1)
	@grep -q '^storeFile=' $(KEY_PROPERTIES) || (echo "storeFile missing in $(KEY_PROPERTIES)." && exit 1)
	@store_file=$$(grep '^storeFile=' $(KEY_PROPERTIES) | cut -d'=' -f2-); \
	 test -f "$(APP_DIR)/android/$$store_file" || (echo "Keystore not found: $(APP_DIR)/android/$$store_file" && exit 1)

build-apk: build-apk-prod

build-apk-dev: check-signing
	cd $(APP_DIR) && $(FLUTTER) build apk --release --dart-define=ENV_FILE=.env.dev
	@mkdir -p $(APK_OUTPUT_DIR)
	@cp $(APK_SOURCE) $(APK_OUTPUT_DIR)/ITN_DEV.apk
	@echo "Generated signed APK: $(APK_OUTPUT_DIR)/ITN_DEV.apk"

build-apk-uat: check-signing
	cd $(APP_DIR) && $(FLUTTER) build apk --release --dart-define=ENV_FILE=.env.uat
	@mkdir -p $(APK_OUTPUT_DIR)
	@cp $(APK_SOURCE) $(APK_OUTPUT_DIR)/ITN_UAT.apk
	@echo "Generated signed APK: $(APK_OUTPUT_DIR)/ITN_UAT.apk"

build-apk-prod: check-signing
	cd $(APP_DIR) && $(FLUTTER) build apk --release --dart-define=ENV_FILE=.env.prod
	@mkdir -p $(APK_OUTPUT_DIR)
	@cp $(APK_SOURCE) $(APK_OUTPUT_DIR)/ITN_PROD.apk
	@echo "Generated signed APK: $(APK_OUTPUT_DIR)/ITN_PROD.apk"
