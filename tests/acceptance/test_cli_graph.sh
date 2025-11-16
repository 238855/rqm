#!/usr/bin/env bash
# RQM-014: CLI Graph Command Acceptance Test
# Tests that the graph command displays dependency relationships

set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

function test_passed() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((TESTS_PASSED++))
    ((TESTS_RUN++))
}

function test_failed() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    echo -e "  ${YELLOW}$2${NC}"
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
}

function test_header() {
    echo ""
    echo "==================================================="
    echo "$1"
    echo "==================================================="
}

# Build the CLI if needed
if [ ! -f "$PROJECT_ROOT/go-cli/rqm" ]; then
    echo "Building CLI..."
    cd "$PROJECT_ROOT/go-cli"
    go build -o rqm
    cd "$PROJECT_ROOT"
fi

RQM_CMD="$PROJECT_ROOT/go-cli/rqm"

test_header "RQM-014: CLI Graph Command"

# Test 1: Graph command displays dependency information
test_header "Test 1: Graph displays dependencies"
OUTPUT=$($RQM_CMD graph "$PROJECT_ROOT/examples/sample-requirements.yml" 2>&1)
if echo "$OUTPUT" | grep -q "Requirements Dependency Graph" && echo "$OUTPUT" | grep -q "→"; then
    test_passed "Graph displays dependency relationships"
else
    test_failed "Graph should display dependencies" "Output: $OUTPUT"
fi

# Test 2: Graph shows acyclic confirmation for valid DAG
test_header "Test 2: Graph confirms acyclic structure"
OUTPUT=$($RQM_CMD graph "$PROJECT_ROOT/examples/sample-requirements.yml" 2>&1)
if echo "$OUTPUT" | grep -q "✓.*acyclic.*DAG"; then
    test_passed "Graph confirms acyclic structure"
else
    test_failed "Graph should confirm DAG" "Output: $OUTPUT"
fi

# Test 3: Graph shows parent-child relationships
test_header "Test 3: Graph shows nested requirements"
OUTPUT=$($RQM_CMD graph "$PROJECT_ROOT/examples/sample-requirements.yml" 2>&1)
if echo "$OUTPUT" | grep -q "User Authentication System.*→.*Password Hashing"; then
    test_passed "Graph shows parent-child relationships"
else
    test_failed "Graph should show nested requirements" "Output: $OUTPUT"
fi

# Test 4: Graph handles requirements with no dependencies
test_header "Test 4: Graph shows requirements with no dependencies"
OUTPUT=$($RQM_CMD graph "$PROJECT_ROOT/examples/sample-requirements.yml" 2>&1)
if echo "$OUTPUT" | grep -q "→ (no dependencies)"; then
    test_passed "Graph shows requirements without dependencies"
else
    test_failed "Graph should show 'no dependencies' message" "Output: $OUTPUT"
fi

# Summary
test_header "Test Summary"
echo "Tests run: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
