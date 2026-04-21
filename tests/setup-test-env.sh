#!/bin/bash
set -e

# My Ez CLI - Test Environment Setup
# Auto-installs test dependencies for local development

BASEDIR="$(cd "$(dirname "${0}")/.." && pwd)"

echo "=================================="
echo "  Test Environment Setup"
echo "=================================="
echo ""
echo "This script will install test dependencies:"
echo "  • bats-core (test framework)"
echo "  • Docker (if not installed)"
echo ""

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
fi

echo "Detected OS: $OS"
echo ""

# Install bats-core
echo "Installing bats-core..."
if command -v bats >/dev/null 2>&1; then
    echo "  ✓ bats-core is already installed ($(bats --version))"
else
    if [ "$OS" = "macos" ]; then
        if command -v brew >/dev/null 2>&1; then
            echo "  Installing via Homebrew..."
            brew install bats-core
            echo "  ✓ bats-core installed successfully"
        else
            echo "  ✗ Homebrew not found. Please install Homebrew first:"
            echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    elif [ "$OS" = "linux" ]; then
        # Detect Linux distribution
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case $ID in
                ubuntu|debian)
                    echo "  Installing via apt..."
                    sudo apt-get update
                    sudo apt-get install -y bats
                    echo "  ✓ bats-core installed successfully"
                    ;;
                fedora|rhel|centos)
                    echo "  Installing via dnf/yum..."
                    if command -v dnf >/dev/null 2>&1; then
                        sudo dnf install -y bats
                    else
                        sudo yum install -y bats
                    fi
                    echo "  ✓ bats-core installed successfully"
                    ;;
                *)
                    echo "  ⚠ Unsupported distribution: $ID"
                    echo "  Please install bats-core manually:"
                    echo "    https://github.com/bats-core/bats-core#installation"
                    ;;
            esac
        else
            echo "  ⚠ Cannot detect Linux distribution"
            echo "  Please install bats-core manually:"
            echo "    https://github.com/bats-core/bats-core#installation"
        fi
    else
        echo "  ⚠ Unsupported OS: $OS"
        echo "  Please install bats-core manually:"
        echo "    https://github.com/bats-core/bats-core#installation"
    fi
fi

echo ""

# Check Docker
echo "Checking Docker..."
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        echo "  ✓ Docker is installed and running ($(docker --version))"
    else
        echo "  ⚠ Docker is installed but not running"
        echo "  Please start Docker:"
        if [ "$OS" = "macos" ]; then
            echo "    open -a Docker"
        else
            echo "    sudo systemctl start docker"
        fi
    fi
else
    echo "  ✗ Docker is not installed"
    echo "  Docker is required for running the tests"
    echo "  Install Docker from: https://docker.com/get-started"
    echo ""
    if [ "$OS" = "macos" ]; then
        echo "  For macOS:"
        echo "    brew install --cask docker"
        echo "    (or download from https://docker.com/products/docker-desktop)"
    fi
fi

echo ""
echo "=================================="
echo "  Setup Complete!"
echo "=================================="
echo ""

# Run dependency check to verify
echo "Verifying installation..."
echo ""
bash "$BASEDIR/tests/check-dependencies.sh"
