#!/usr/bin/env bash
# RQM - Install binary globally
# Copyright (c) 2025
# SPDX-License-Identifier: MIT

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="$PROJECT_ROOT/bin/dist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 RQM Global Installer${NC}"
echo "======================"
echo ""

# Detect platform and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
    darwin)
        PLATFORM="macos"
        ;;
    linux)
        PLATFORM="linux"
        ;;
    mingw*|msys*|cygwin*)
        PLATFORM="windows"
        ;;
    *)
        echo -e "${RED}Error: Unsupported platform: $OS${NC}"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64|amd64)
        ARCH_SUFFIX="amd64"
        ;;
    arm64|aarch64)
        ARCH_SUFFIX="arm64"
        ;;
    *)
        echo -e "${RED}Error: Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
esac

BINARY_NAME="rqm-$PLATFORM-$ARCH_SUFFIX"
if [[ "$PLATFORM" == "windows" ]]; then
    BINARY_NAME="${BINARY_NAME}.exe"
fi

SOURCE_BINARY="$BIN_DIR/$BINARY_NAME"

# Check if binary exists
if [ ! -f "$SOURCE_BINARY" ]; then
    echo -e "${YELLOW}Binary not found: $SOURCE_BINARY${NC}"
    echo ""
    echo "Building binary for your platform..."
    echo ""
    cd "$PROJECT_ROOT"
    ./scripts/build-rqm.sh --unified
fi

# Check again after build attempt
if [ ! -f "$SOURCE_BINARY" ]; then
    echo -e "${RED}Error: Failed to build binary${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found binary: $BINARY_NAME${NC}"
echo ""

# Determine install location
if [ -n "$PREFIX" ]; then
    INSTALL_DIR="$PREFIX/bin"
elif [ -w "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
elif [ -d "$HOME/.local/bin" ]; then
    INSTALL_DIR="$HOME/.local/bin"
else
    INSTALL_DIR="$HOME/bin"
    mkdir -p "$INSTALL_DIR"
fi

echo "Install location: $INSTALL_DIR"
echo ""

# Check if we need sudo
SUDO=""
if [ ! -w "$INSTALL_DIR" ]; then
    SUDO="sudo"
    echo -e "${YELLOW}Note: Installation requires sudo privileges${NC}"
fi

# Install the binary
echo "Installing rqm..."
$SUDO cp "$SOURCE_BINARY" "$INSTALL_DIR/rqm"
$SUDO chmod +x "$INSTALL_DIR/rqm"

# Create requim symlink
echo "Creating requim alias..."
$SUDO ln -sf "$INSTALL_DIR/rqm" "$INSTALL_DIR/requim"

echo ""
echo -e "${GREEN}✨ Installation successful!${NC}"
echo ""
echo "Installed binaries:"
echo "  - $INSTALL_DIR/rqm"
echo "  - $INSTALL_DIR/requim (alias)"
echo ""

# Check if install dir is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "${YELLOW}⚠️  Warning: $INSTALL_DIR is not in your PATH${NC}"
    echo ""
    echo "Add it to your PATH by adding this to your shell config:"
    echo ""
    if [[ "$SHELL" == *"zsh"* ]]; then
        echo "  echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.zshrc"
        echo "  source ~/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        echo "  echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.bashrc"
        echo "  source ~/.bashrc"
    else
        echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    fi
    echo ""
fi

# Test the installation
echo "Testing installation..."
if command -v rqm &> /dev/null; then
    VERSION=$(rqm --version 2>&1 || echo "unknown")
    echo -e "${GREEN}✓ rqm is available: $VERSION${NC}"
else
    echo -e "${YELLOW}⚠️  rqm command not found in PATH${NC}"
    echo "You may need to restart your shell or update your PATH"
fi

echo ""
echo "Quick start:"
echo "  rqm --help"
echo "  rqm validate examples/sample-requirements.yml"
echo "  rqm serve examples/sample-requirements.yml"
echo ""
echo "To uninstall:"
echo "  $SUDO rm $INSTALL_DIR/rqm $INSTALL_DIR/requim"
