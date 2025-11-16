#!/usr/bin/env bash
# RQM-015: CLI Check Command Acceptance Test
# Tests that the check command detects circular references

set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="$PROJECT_ROOT/tests/acceptance/fixtures"

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

mkdir -p "$TEST_DIR"

# Build the CLI if needed
if [ ! -f "$PROJECT_ROOT/go-cli/rqm" ]; then
    echo "Building CLI..."
    cd "$PROJECT_ROOT/go-cli"
    go build -o rqm
    cd "$PROJECT_ROOT"
fi

RQM_CMD="$PROJECT_ROOT/go-cli/rqm"

test_header "RQM-015: CLI Check Command"

# Test 1: Check command confirms no cycles in valid file
test_header "Test 1: Check confirms acyclic graph"
OUTPUT=$($RQM_CMD check "$PROJECT_ROOT/examples/sample-requirements.yml" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ] && echo "$OUTPUT" | grep -q "✓.*No circular references detected"; then
    test_passed "Check confirms acyclic graph with exit code 0"
else
    test_failed "Check should confirm no cycles" "Exit: $EXIT_CODE, Output: $OUTPUT"
fi

# Test 2: Create a file with circular reference and test detection
test_header "Test 2: Check detects circular references"
cat > "$TEST_DIR/circular.yml" << 'YAML'
version: "1.0"
requirements:
  - summary: Requirement A
    name: REQ-A
    requirements:
      - Requirement B
  - summary: Requirement B
    name: REQ-B
    requirements:
      - Requirement A
YAML

OUTPUT=$($RQM_CMD check "$TEST_DIR/circular.yml" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ] && echo "$OUTPUT" | grep -q "✗.*circular reference"; then
    test_passed "Check detects circular references with exit code 1"
else
    test_failed "Check should detect cycles" "Exit: $EXIT_CODE, Output: $OUTPUT"
fi

# Test 3: Check displays cycle paths
test_header "Test 3: Check displays cycle paths"
OUTPUT=$($RQM_CMD check "$TEST_DIR/circular.yml" 2>&1)
if echo "$OUTPUT" | grep -q "Cycle" && echo "$OUTPUT" | grep -q "Requirement A\|Requirement B"; then
    test_passed "Check displays detailed cycle paths"
else
    test_failed "Check should show cycle details" "Output: $OUTPUT"
fi

# Test 4: Check shows DAG confirmation message
test_header "Test 4: Check shows DAG confirmation"
OUTPUT=$($RQM_CMD check "$PROJECT_ROOT/examples/sample-requirements.yml" 2>&1)
if echo "$OUTPUT" | grep -q "acyclic.*DAG"; then
    test_passed "Check shows DAG confirmation message"
else
    test_failed "Check should confirm DAG structure" "Output: $OUTPUT"
fi

# Test 5: Check warns about circular reference issues
test_header "Test 5: Check provides helpful warnings"
OUTPUT=$($RQM_CMD check "$TEST_DIR/circular.yml" 2>&1)
if echo "$OUTPUT" | grep -q "⚠.*infinite loops\|restructuring"; then
    test_passed "Check provides warning about circular references"
else
    test_failed "Check should warn about issues" "Output: $OUTPUT"
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
