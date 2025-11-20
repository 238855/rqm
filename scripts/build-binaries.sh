#!/usr/bin/env bash
set -e

# Build binaries for all platforms
# This script creates pre-built binaries for distribution

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$PROJECT_ROOT/bin/dist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building RQM binaries for all platforms...${NC}"

# Create dist directory
mkdir -p "$DIST_DIR"

# Change to go-cli directory
cd "$PROJECT_ROOT/go-cli"

# Platform configurations
# Format: "GOOS GOARCH output-name"
PLATFORMS=(
  "darwin amd64 rqm-macos-amd64"
  "darwin arm64 rqm-macos-arm64"
  "linux amd64 rqm-linux-amd64"
  "linux arm64 rqm-linux-arm64"
  "windows amd64 rqm-windows-amd64.exe"
  "windows arm64 rqm-windows-arm64.exe"
  "windows 386 rqm-windows-386.exe"
)

# Build for each platform
for platform in "${PLATFORMS[@]}"; do
  read -r GOOS GOARCH OUTPUT <<< "$platform"
  
  echo -e "${YELLOW}Building for $GOOS/$GOARCH...${NC}"
  
  GOOS=$GOOS GOARCH=$GOARCH go build -o "$DIST_DIR/$OUTPUT" -ldflags="-s -w" .
  
  if [ $? -eq 0 ]; then
    SIZE=$(du -h "$DIST_DIR/$OUTPUT" | cut -f1)
    echo -e "${GREEN}✓ Built $OUTPUT ($SIZE)${NC}"
  else
    echo -e "${RED}✗ Failed to build $OUTPUT${NC}"
    exit 1
  fi
done

echo ""
echo -e "${GREEN}All binaries built successfully!${NC}"
echo -e "${YELLOW}Location: $DIST_DIR${NC}"
echo ""
echo "Built binaries:"
ls -lh "$DIST_DIR"
