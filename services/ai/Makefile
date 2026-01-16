.PHONY: help install install-dev lint format typecheck test check clean pre-commit

# Default target
help:
	@echo "My Ez CLI AI Service - Development Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make install         Install runtime dependencies"
	@echo "  make install-dev     Install dev dependencies + pre-commit hooks"
	@echo ""
	@echo "Code Quality:"
	@echo "  make check           Run all checks (lint + typecheck + test)"
	@echo "  make lint            Run ruff linter"
	@echo "  make format          Run ruff formatter"
	@echo "  make typecheck       Run mypy type checker"
	@echo "  make test            Run pytest tests"
	@echo ""
	@echo "Git Hooks:"
	@echo "  make pre-commit      Setup and run pre-commit hooks"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean           Remove cache and build files"

# Installation
install:
	@echo "Installing production dependencies with Poetry..."
	poetry install --only main

install-dev:
	@echo "Installing all dependencies with Poetry..."
	poetry install
	@echo ""
	@echo "Installing pre-commit hooks..."
	poetry run pre-commit install
	@echo ""
	@echo "✓ Development environment ready!"
	@echo "  Run 'make check' to verify everything works"
	@echo "  Use 'poetry shell' to activate the virtual environment"
	@echo "  Or prefix commands with 'poetry run'"

# Code quality checks
lint:
	@echo "Running ruff linter..."
	poetry run ruff check src tests

lint-fix:
	@echo "Running ruff linter with auto-fix..."
	poetry run ruff check --fix src tests

format:
	@echo "Running ruff formatter..."
	poetry run ruff format src tests

format-check:
	@echo "Checking code formatting..."
	poetry run ruff format --check src tests

typecheck:
	@echo "Running mypy type checker..."
	poetry run mypy src

test:
	@echo "Running pytest..."
	poetry run pytest tests/ -v

# Run all checks
check: format-check lint typecheck test
	@echo ""
	@echo "✓ All checks passed!"

# Pre-commit hooks
pre-commit:
	@echo "Installing pre-commit hooks..."
	poetry run pre-commit install
	@echo "Running pre-commit on all files..."
	poetry run pre-commit run --all-files

# Cleanup
clean:
	@echo "Cleaning up cache and build files..."
	rm -rf .mypy_cache .pytest_cache .ruff_cache
	rm -rf build dist *.egg-info
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	@echo "✓ Cleanup complete"

# Docker targets
docker-build:
	cd ../../docker/ai-service && ./build

docker-test:
	docker-compose up --build --abort-on-container-exit
