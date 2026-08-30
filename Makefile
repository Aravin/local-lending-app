.DEFAULT_GOAL := help

FLAVOR ?= localLendingHub
ENTRYPOINT := lib/main_$(FLAVOR).dart

.PHONY: help setup run build-apk build-aab build-android test coverage gen lint format clean docs set-admin

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Install lefthook + pub dependencies
	@echo "🔧 Installing lefthook..."
	brew install lefthook || true
	lefthook install
	@echo "📦 Getting pub dependencies..."
	flutter pub get
	@echo "✅ Setup complete!"

run-hub: ## Run Local Lending Hub flavor
	flutter run --flavor localLendingHub -t lib/main_local_lending_hub.dart

run-cape: ## Run Cape Finance flavor
	flutter run --flavor capeFinance -t lib/main_cape_finance.dart

build-apk-hub: ## Build debug APK for Local Lending Hub
	flutter build apk --flavor localLendingHub -t lib/main_local_lending_hub.dart

build-apk-cape: ## Build debug APK for Cape Finance
	flutter build apk --flavor capeFinance -t lib/main_cape_finance.dart

build-release-cape: ## Build release APK for Cape Finance
	flutter build apk --release --flavor capeFinance -t lib/main_cape_finance.dart

build-aab-cape: ## Build production App Bundle for Cape Finance
	flutter build appbundle --release --flavor capeFinance -t lib/main_cape_finance.dart

build-android: ## Interactive Android APK/AAB build (bumps minor + build)
	@bash scripts/build_android.sh


test: ## Run all tests
	flutter test --no-pub

test-unit: ## Run unit tests only
	flutter test test/unit/ --no-pub

test-widget: ## Run widget tests only
	flutter test test/widget/ --no-pub

test-integration: ## Run integration tests
	flutter test test/integration/ --no-pub

coverage: ## Run tests with coverage and open report
	flutter test --coverage --no-pub
	genhtml coverage/lcov.info -o coverage/html
	open coverage/html/index.html

gen: ## Run build_runner (code generation for freezed/json)
	dart run build_runner build --delete-conflicting-outputs

watch: ## Watch and auto-generate code
	dart run build_runner watch --delete-conflicting-outputs

lint: ## Run flutter analyze
	flutter analyze --no-pub

format: ## Format all Dart files
	dart format lib/ test/

format-check: ## Check formatting without modifying files
	dart format --set-exit-if-changed lib/ test/

clean: ## Clean build artifacts
	flutter clean
	rm -rf coverage/

docs: ## Serve docs locally (requires python3)
	python3 -m http.server 8080 --directory docs/

set-admin: ## Grant Firebase admin claim (prompts for UID)
	@cd functions && npm install --silent && node set-admin.js
