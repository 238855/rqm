#!/usr/bin/env bash
# RQM Code Coverage Collection Script
# Collects code coverage from Rust and Go tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COVERAGE_DIR="$PROJECT_ROOT/.coverage"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

mkdir -p "$COVERAGE_DIR"

echo "╔════════════════════════════════════════════════════╗"
echo "║          RQM Code Coverage Collection             ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

# Rust Coverage
echo -e "${BLUE}▶ Collecting Rust Coverage${NC}"
echo "──────────────────────────────────────────────────────"

cd "$PROJECT_ROOT/rust-core"

# Check if cargo-llvm-cov is installed
if command -v cargo-llvm-cov > /dev/null 2>&1; then
    echo "Using cargo-llvm-cov..."
    
    # Generate coverage
    cargo llvm-cov --no-report --workspace > /dev/null 2>&1 || true
    
    # Generate JSON report
    if cargo llvm-cov report --json > "$COVERAGE_DIR/rust-coverage.json" 2>/dev/null; then
        # Extract coverage percentage
        if command -v jq > /dev/null 2>&1; then
            RUST_COV=$(jq -r '.data[0].totals.lines.percent' "$COVERAGE_DIR/rust-coverage.json" 2>/dev/null || echo "N/A")
            echo -e "${GREEN}✓${NC} Rust line coverage: ${RUST_COV}%"
        else
            echo -e "${GREEN}✓${NC} Rust coverage collected (install jq for percentage)"
        fi
    fi
    
    # Generate human-readable report
    cargo llvm-cov report --summary-only > "$COVERAGE_DIR/rust-coverage.txt" 2>&1 || echo "Basic Rust coverage complete"
    
else
    echo -e "${YELLOW}⚠${NC} cargo-llvm-cov not installed, using basic test run"
    echo "  Install with: cargo install cargo-llvm-cov"
    
    # Fallback: just run tests
    cargo test > /dev/null 2>&1
    echo "  Rust tests: $(cargo test 2>&1 | grep -c 'test result: ok' || echo '0') suites passed"
fi

echo ""

# Go Coverage
echo -e "${BLUE}▶ Collecting Go Coverage${NC}"
echo "──────────────────────────────────────────────────────"

cd "$PROJECT_ROOT/go-cli"

if [ -f "go.mod" ]; then
    # Run Go tests with coverage
    go test -cover -coverprofile="$COVERAGE_DIR/go-coverage.out" ./... > "$COVERAGE_DIR/go-test-output.txt" 2>&1 || true
    
    # Extract coverage percentage
    if [ -f "$COVERAGE_DIR/go-coverage.out" ]; then
        GO_COV=$(go tool cover -func="$COVERAGE_DIR/go-coverage.out" | grep total | awk '{print $3}')
        echo -e "${GREEN}✓${NC} Go coverage: ${GO_COV}"
        
        # Generate HTML report
        go tool cover -html="$COVERAGE_DIR/go-coverage.out" -o "$COVERAGE_DIR/go-coverage.html" 2>/dev/null
    else
        echo -e "${YELLOW}⚠${NC} Go coverage file not generated"
    fi
else
    echo -e "${YELLOW}⚠${NC} No go.mod found, skipping Go coverage"
fi

echo ""

# Summary
echo -e "${BLUE}▶ Coverage Summary${NC}"
echo "──────────────────────────────────────────────────────"

if [ -f "$COVERAGE_DIR/rust-coverage.json" ]; then
    echo "Rust coverage report: .coverage/rust-coverage.json"
    echo "Rust summary: .coverage/rust-coverage.txt"
fi

if [ -f "$COVERAGE_DIR/go-coverage.html" ]; then
    echo "Go coverage report: .coverage/go-coverage.html"
    echo "Go profile: .coverage/go-coverage.out"
fi

echo ""
echo -e "${GREEN}✓ Coverage collection complete${NC}"
echo ""

# Return to project root
cd "$PROJECT_ROOT"
