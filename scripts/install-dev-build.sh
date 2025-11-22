#!/usr/bin/env bash
# RQM - Install Development Build from GitHub Actions Artifacts
# Copyright (c) 2025
# SPDX-License-Identifier: MIT

set -e

REPO="238855/rqm"
WORKFLOW="build-dev.yml"
ARTIFACT_NAME="rqm-binaries-develop"
INSTALL_DIR="bin/dist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔧 RQM Dev Build Installer"
echo "=========================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
    echo ""
    echo "Install it with:"
    echo "  macOS:   brew install gh"
    echo "  Linux:   See https://github.com/cli/cli#installation"
    echo "  Windows: See https://github.com/cli/cli#installation"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}Not authenticated with GitHub CLI${NC}"
    echo "Please authenticate first:"
    echo "  gh auth login"
    exit 1
fi

# Get the latest successful workflow run
echo "📡 Fetching latest successful build..."
RUN_ID=$(gh run list \
    --workflow="$WORKFLOW" \
    --repo="$REPO" \
    --branch=develop \
    --status=success \
    --limit=1 \
    --json databaseId \
    --jq '.[0].databaseId')

if [ -z "$RUN_ID" ]; then
    echo -e "${RED}Error: No successful builds found${NC}"
    echo ""
    echo "Check workflow status at:"
    echo "  https://github.com/$REPO/actions/workflows/$WORKFLOW"
    exit 1
fi

echo "✓ Found build run ID: $RUN_ID"
echo ""

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Download artifact
echo "⬇️  Downloading artifact..."
cd "$TEMP_DIR"
if ! gh run download "$RUN_ID" --name "$ARTIFACT_NAME" --repo "$REPO"; then
    echo -e "${RED}Error: Failed to download artifact${NC}"
    exit 1
fi

# Go back to project root
cd - > /dev/null

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Copy binaries to install directory
echo "📦 Installing binaries..."
INSTALLED_COUNT=0
for binary in "$TEMP_DIR"/rqm-*; do
    if [ -f "$binary" ]; then
        BASENAME=$(basename "$binary")
        cp "$binary" "$INSTALL_DIR/$BASENAME"
        chmod +x "$INSTALL_DIR/$BASENAME"
        echo "  ✓ Installed $BASENAME"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    fi
done

if [ $INSTALLED_COUNT -eq 0 ]; then
    echo -e "${RED}Error: No binaries found in artifact${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✨ Successfully installed $INSTALLED_COUNT binaries${NC}"
echo ""
echo "Binaries are available in: $INSTALL_DIR/"
echo ""

# Detect platform and show relevant binary
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
        echo -e "${YELLOW}Warning: Unknown platform $OS${NC}"
        PLATFORM=""
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
        echo -e "${YELLOW}Warning: Unknown architecture $ARCH${NC}"
        ARCH_SUFFIX=""
        ;;
esac

if [ -n "$PLATFORM" ] && [ -n "$ARCH_SUFFIX" ]; then
    BINARY_NAME="rqm-$PLATFORM-$ARCH_SUFFIX"
    if [[ "$PLATFORM" == "windows" ]]; then
        BINARY_NAME="${BINARY_NAME}.exe"
    fi
    
    if [ -f "$INSTALL_DIR/$BINARY_NAME" ]; then
        echo "Your platform binary: $INSTALL_DIR/$BINARY_NAME"
        echo ""
        echo "Test it with:"
        echo "  ./$INSTALL_DIR/$BINARY_NAME --version"
        echo "  ./$INSTALL_DIR/$BINARY_NAME validate examples/sample-requirements.yml"
        echo ""
        echo "Or use via npm wrapper:"
        echo "  node bin/rqm.js --version"
    fi
fi

echo ""
echo "To use these binaries with npm install from GitHub:"
echo "  npm install github:$REPO#develop"
