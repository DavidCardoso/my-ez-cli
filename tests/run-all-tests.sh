#!/bin/bash
set -e

# My Ez CLI - Test Runner
# Runs all tests using bats-core

BASEDIR="$(cd "$(dirname "${0}")/.." && pwd)"
TEST_DIR="$(cd "$(dirname "${0}")" && pwd)"

echo "=================================="
echo "  My Ez CLI - Test Suite"
echo "=================================="
echo ""

# Check dependencies first
if [ "$SKIP_DEPENDENCY_CHECK" != "1" ]; then
    echo "Checking dependencies..."
    if ! bash "$TEST_DIR/check-dependencies.sh" >/dev/null 2>&1; then
        echo ""
        echo "⚠ Some dependencies are missing!"
        echo ""
        echo "Run this to check what's missing:"
        echo "  ./tests/check-dependencies.sh"
        echo ""
        echo "Or auto-install dependencies (macOS/Linux):"
        echo "  ./tests/setup-test-env.sh"
        echo ""
        echo "To skip this check, set: SKIP_DEPENDENCY_CHECK=1"
        echo ""
        exit 1
    fi
    echo "✓ All dependencies installed"
    echo ""
fi

echo "Using bats: $(which bats)"
echo "Bats version: $(bats --version)"
echo ""

# Run unit tests
if [ -d "$BASEDIR/tests/unit" ]; then
    echo "Running unit tests..."
    bats "$BASEDIR/tests/unit"/*.bats
    echo ""
fi

# Run integration tests (if they exist)
if [ -d "$BASEDIR/tests/integration" ] && [ -n "$(ls -A "$BASEDIR/tests/integration"/*.bats 2>/dev/null)" ]; then
    echo "Running integration tests..."
    bats "$BASEDIR/tests/integration"/*.bats
    echo ""
fi

# Run e2e tests (if they exist)
if [ -d "$BASEDIR/tests/e2e" ] && [ -n "$(ls -A "$BASEDIR/tests/e2e"/*.bats 2>/dev/null)" ]; then
    echo "Running end-to-end tests..."
    bats "$BASEDIR/tests/e2e"/*.bats
    echo ""
fi

echo "=================================="
echo "  All tests passed! ✓"
echo "=================================="
