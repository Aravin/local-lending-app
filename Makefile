.DEFAULT_GOAL := help

FLAVOR ?= localLendingHub
ENTRYPOINT := lib/main_$(FLAVOR).dart

.PHONY: help setup run build-apk build-aab test coverage gen lint format clean docs

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Install lefthook + pub dependencies
	@echo "🔧 Installing lefthook..."
	brew install lefthook || true
	lefthook install
	@echo "📦 Getting pub dependencies..."
	flutter pub get
	@echo "✅ Setup complete!"

run: ## Run app for a flavor (default: localLendingHub)
	flutter run --flavor $(FLAVOR) -t $(ENTRYPOINT)

build-apk: ## Build debug APK for a flavor
	flutter build apk --flavor $(FLAVOR) -t $(ENTRYPOINT)

build-apk-release: ## Build release APK for a flavor
	flutter build apk --release --flavor $(FLAVOR) -t $(ENTRYPOINT)

build-aab: ## Build App Bundle for Play Store upload
	flutter build appbundle --release --flavor $(FLAVOR) -t $(ENTRYPOINT)

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
