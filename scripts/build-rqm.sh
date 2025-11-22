#!/usr/bin/env bash
set -e

# Build RQM binaries
# Supports two modes:
#   1. Unified: Single binary with embedded Rust validator (requires CGO)
#   2. Separate: Go binary + external Rust validator (no CGO required)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$PROJECT_ROOT/bin/dist"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default mode
MODE="unified"  # or "separate"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --unified)
      MODE="unified"
      shift
      ;;
    --separate)
      MODE="separate"
      shift
      ;;
    --help)
      echo "Usage: $0 [--unified|--separate]"
      echo ""
      echo "Modes:"
      echo "  --unified   Build single binary with embedded Rust (default, requires CGO)"
      echo "  --separate  Build Go binary + external Rust validator (no CGO)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}Building RQM in $MODE mode...${NC}"

# Create dist directory
mkdir -p "$DIST_DIR"

# Step 1: Build Rust library/binary
if [ "$MODE" = "unified" ]; then
  echo -e "${YELLOW}Building Rust static library for current platform...${NC}"
  cd "$PROJECT_ROOT/rust-core"
  cargo build --release --lib
  
  # Build for ARM64 if on macOS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${YELLOW}Building Rust library for ARM64...${NC}"
    rustup target add aarch64-apple-darwin 2>/dev/null || true
    cargo build --release --lib --target aarch64-apple-darwin
    
    echo -e "${YELLOW}Building Rust library for x86_64...${NC}"
    rustup target add x86_64-apple-darwin 2>/dev/null || true
    cargo build --release --lib --target x86_64-apple-darwin
  fi
  
  echo -e "${GREEN}✓ Rust library built${NC}"
else
  echo -e "${YELLOW}Building Rust validator binary...${NC}"
  cd "$PROJECT_ROOT/rust-core"
  cargo build --release --bin rqm-validator
  echo -e "${GREEN}✓ Rust validator built${NC}"
fi

# Step 2: Build Go binaries for all platforms
cd "$PROJECT_ROOT/go-cli"

if [ "$MODE" = "unified" ]; then
  # Unified mode: Build with CGO for single binary
  echo -e "${YELLOW}Building unified binaries (with embedded Rust)...${NC}"
  
  # macOS ARM64 (use aarch64 Rust lib)
  echo "  Building for macOS ARM64..."
  CGO_ENABLED=1 GOOS=darwin GOARCH=arm64 \
    CGO_LDFLAGS="-L$PROJECT_ROOT/rust-core/target/aarch64-apple-darwin/release" \
    go build -o "$DIST_DIR/rqm-macos-arm64" -ldflags="-s -w" .
  
  # macOS AMD64 (use x86_64 Rust lib)
  echo "  Building for macOS AMD64..."
  CGO_ENABLED=1 GOOS=darwin GOARCH=amd64 \
    CGO_LDFLAGS="-L$PROJECT_ROOT/rust-core/target/x86_64-apple-darwin/release" \
    go build -o "$DIST_DIR/rqm-macos-amd64" -ldflags="-s -w" .
  
  echo -e "${GREEN}✓ Unified binaries built${NC}"
  echo -e "${YELLOW}Note: Cross-platform unified builds require platform-specific toolchains${NC}"
  
else
  # Separate mode: Build without CGO (pure Go)
  echo -e "${YELLOW}Building separate Go binaries...${NC}"
  
  PLATFORMS=(
    "darwin amd64 rqm-macos-amd64"
    "darwin arm64 rqm-macos-arm64"
    "linux amd64 rqm-linux-amd64"
    "linux arm64 rqm-linux-arm64"
    "windows amd64 rqm-windows-amd64.exe"
    "windows arm64 rqm-windows-arm64.exe"
    "windows 386 rqm-windows-386.exe"
  )
  
  for platform in "${PLATFORMS[@]}"; do
    read -r GOOS GOARCH OUTPUT <<< "$platform"
    echo "  Building for $GOOS/$GOARCH..."
    CGO_ENABLED=0 GOOS=$GOOS GOARCH=$GOARCH go build -o "$DIST_DIR/$OUTPUT" -ldflags="-s -w" .
  done
  
  echo -e "${GREEN}✓ Separate Go binaries built${NC}"
fi

# Summary
echo ""
echo -e "${GREEN}Build complete!${NC}"
echo -e "${YELLOW}Mode: $MODE${NC}"
echo -e "${YELLOW}Location: $DIST_DIR${NC}"
echo ""
echo "Built binaries:"
ls -lh "$DIST_DIR" | grep rqm-
