#!/usr/bin/env bash
# RQM-013: CLI List Command Acceptance Test
# Tests that the list command displays requirements in multiple formats

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

# Build the CLI if needed
if [ ! -f "$PROJECT_ROOT/go-cli/rqm" ]; then
    echo "Building CLI..."
    cd "$PROJECT_ROOT/go-cli"
    go build -o rqm
    cd "$PROJECT_ROOT"
fi

RQM_CMD="$PROJECT_ROOT/go-cli/rqm"

test_header "RQM-013: CLI List Command"

# Test 1: List command displays requirements in tree format
test_header "Test 1: Tree format displays requirements"
OUTPUT=$($RQM_CMD list "$PROJECT_ROOT/examples/sample-requirements.yml" 2>&1)
if echo "$OUTPUT" | grep -q "Requirements (v1.0)" && echo "$OUTPUT" | grep -q "User Authentication System"; then
    test_passed "Tree format displays requirements"
else
    test_failed "Tree format should display requirements" "Output: $OUTPUT"
fi

# Test 2: Table format works
test_header "Test 2: Table format displays requirements"
OUTPUT=$($RQM_CMD list "$PROJECT_ROOT/examples/sample-requirements.yml" --format table 2>&1)
if echo "$OUTPUT" | grep -q "ID.*Summary.*Owner" && echo "$OUTPUT" | grep -q "AUTH-001"; then
    test_passed "Table format displays requirements"
else
    test_failed "Table format should work" "Output: $OUTPUT"
fi

# Test 3: JSON format works
test_header "Test 3: JSON format outputs valid JSON"
OUTPUT=$($RQM_CMD list "$PROJECT_ROOT/examples/sample-requirements.yml" --format json 2>&1)
if echo "$OUTPUT" | grep -q '"version"' && echo "$OUTPUT" | grep -q '"requirements"'; then
    test_passed "JSON format outputs valid JSON"
else
    test_failed "JSON format should output valid JSON" "Output: $OUTPUT"
fi

# Test 4: Details flag shows additional information
test_header "Test 4: Details flag shows descriptions"
OUTPUT=$($RQM_CMD list "$PROJECT_ROOT/examples/sample-requirements.yml" --details 2>&1)
if echo "$OUTPUT" | grep -q "Owner:" && echo "$OUTPUT" | grep -q "Description:"; then
    test_passed "Details flag shows additional information"
else
    test_failed "Details flag should show descriptions" "Output: $OUTPUT"
fi

# Test 5: Status symbols are displayed
test_header "Test 5: Status symbols displayed correctly"
OUTPUT=$($RQM_CMD list "$PROJECT_ROOT/examples/sample-requirements.yml" 2>&1)
if echo "$OUTPUT" | grep -q "✓\|○\|◐\|◯"; then
    test_passed "Status symbols displayed"
else
    test_failed "Status symbols should be displayed" "Output: $OUTPUT"
fi

# Test 6: Priority indicators are displayed
test_header "Test 6: Priority indicators displayed correctly"
OUTPUT=$($RQM_CMD list "$PROJECT_ROOT/examples/sample-requirements.yml" 2>&1)
if echo "$OUTPUT" | grep -q "🔴\|🟠\|🟡\|🟢"; then
    test_passed "Priority indicators displayed"
else
    test_failed "Priority indicators should be displayed" "Output: $OUTPUT"
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
