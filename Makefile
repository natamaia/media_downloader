# ==============================================================================
# MediaDownloader Mobile - Build & Automation Makefile
# Target: Android APK (Flutter + Embedded Python yt-dlp)
# ==============================================================================

SHELL := /bin/bash
PYTHON ?= $(shell which python3)
VENV_PYTHON := .venv/bin/python3

.PHONY: help apk test test-flutter test-all clean

help:
	@echo "======================================================================"
	@echo "📱 MediaDownloader Mobile - Build System"
	@echo "======================================================================"
	@echo "Comandos disponíveis:"
	@echo "  make apk        - Compila o binário Android APK para build_apk/MediaDownloader.apk"
	@echo "  make test       - Executa os testes automatizados do motor Python"
	@echo "  make clean      - Limpa diretórios temporários e caches de build"
	@echo "======================================================================"

apk:
	@echo "==> Compilando APK do MediaDownloader (Flutter + Python)..."
	@mkdir -p build_apk
	@if [ -d "mobile_app" ]; then \
		cd mobile_app && flutter pub get && flutter build apk --release && \
		cp build/app/outputs/flutter-apk/app-release.apk ../build_apk/MediaDownloader.apk && \
		echo "✅ APK gerado com sucesso em: build_apk/MediaDownloader.apk"; \
	else \
		echo "⚠️  Diretório mobile_app ainda não inicializado. Execute a criação do projeto Flutter primeiro."; \
	fi

test:
	@echo "==> Executando testes com pytest..."
	@if [ -f "$(VENV_PYTHON)" ]; then \
		$(VENV_PYTHON) -m pytest -v; \
	else \
		$(PYTHON) -m pytest -v; \
	fi

test-flutter:
	@echo "==> Executando testes do Flutter..."
	@if [ -d "mobile_app" ]; then \
		cd mobile_app && flutter test; \
	fi

test-all: test test-flutter
	@echo "✅ Todos os testes (Python + Flutter) passaram com sucesso!"

clean:
	@echo "==> Limpando diretórios temporários..."
	@rm -rf .pytest_cache
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@if [ -d "mobile_app" ]; then \
		cd mobile_app && flutter clean; \
	fi
	@echo "✅ Diretório limpo."
