#!/bin/bash
set -e

# My Ez CLI - Test Dependencies Checker
# Checks if all required dependencies are installed for running tests

BASEDIR="$(cd "$(dirname "${0}")/.." && pwd)"

echo "=================================="
echo "  Checking Test Dependencies"
echo "=================================="
echo ""

# Track if any dependencies are missing
MISSING_DEPS=0

# Check Docker
echo -n "Checking Docker... "
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        echo "✓ Found ($(docker --version))"
    else
        echo "✗ Docker daemon not running"
        echo "  Start Docker:"
        echo "    macOS: open -a Docker"
        echo "    Linux: sudo systemctl start docker"
        MISSING_DEPS=1
    fi
else
    echo "✗ Not installed"
    echo "  Install Docker:"
    echo "    https://docker.com/get-started"
    MISSING_DEPS=1
fi

# Check bats-core
echo -n "Checking bats-core... "
if command -v bats >/dev/null 2>&1; then
    echo "✓ Found ($(bats --version))"
else
    echo "✗ Not installed"
    echo "  Install bats-core:"
    echo "    macOS:   brew install bats-core"
    echo "    Ubuntu:  sudo apt-get install bats"
    echo "    Fedora:  sudo dnf install bats"
    echo "    Manual:  https://github.com/bats-core/bats-core#installation"
    MISSING_DEPS=1
fi

# Check bash (should always be present, but verify version)
echo -n "Checking bash... "
if command -v bash >/dev/null 2>&1; then
    BASH_VERSION=$(bash --version | head -n 1)
    echo "✓ Found ($BASH_VERSION)"
else
    echo "✗ Not found (this should never happen!)"
    MISSING_DEPS=1
fi

# Check git (for version info in tests)
echo -n "Checking git... "
if command -v git >/dev/null 2>&1; then
    echo "✓ Found ($(git --version))"
else
    echo "⚠ Not installed (optional, but recommended)"
fi

echo ""
echo "=================================="

if [ $MISSING_DEPS -eq 0 ]; then
    echo "✓ All required dependencies are installed!"
    echo ""
    echo "You can now run tests:"
    echo "  ./tests/run-all-tests.sh"
    echo ""
    exit 0
else
    echo "✗ Some dependencies are missing"
    echo ""
    echo "To auto-install on macOS, run:"
    echo "  ./tests/setup-test-env.sh"
    echo ""
    echo "Or install manually using the commands above."
    echo ""
    exit 1
fi
