#!/usr/bin/env bash
# RQM-001: YAML File Validation Acceptance Test
# Tests that the validation system correctly validates YAML files

set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="$PROJECT_ROOT/tests/acceptance/fixtures"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

mkdir -p "$TEST_DIR"

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

test_header "RQM-001: YAML File Validation"

# Test 1: Valid YAML file should pass validation
test_header "Test 1: Valid YAML file passes validation"
cat > "$TEST_DIR/valid.yml" << 'YAML'
version: "1.0"
requirements:
  - summary: Test Requirement
    description: A valid test requirement
YAML

if $RQM_CMD validate "$TEST_DIR/valid.yml" > /dev/null 2>&1; then
    test_passed "Valid YAML file passes validation"
else
    test_failed "Valid YAML file should pass" "Exit code: $?"
fi

# Test 2: File with duplicate summaries should fail
test_header "Test 2: Duplicate summaries detected"
cat > "$TEST_DIR/duplicate.yml" << 'YAML'
version: "1.0"
requirements:
  - summary: Duplicate
    description: First one
  - summary: Duplicate
    description: Second one with same summary
YAML

if $RQM_CMD validate "$TEST_DIR/duplicate.yml" > /dev/null 2>&1; then
    test_failed "Duplicate summaries should fail validation" "Validation passed when it should have failed"
else
    # TODO: When Rust integration is complete, check error message contains "Duplicate"
    test_passed "Duplicate summaries correctly rejected (placeholder)"
fi

# Test 3: Non-existent file should fail
test_header "Test 3: Non-existent file handling"
if $RQM_CMD validate "$TEST_DIR/nonexistent.yml" > /dev/null 2>&1; then
    test_failed "Non-existent file should fail" "Validation passed for non-existent file"
else
    test_passed "Non-existent file correctly rejected"
fi

# Test 4: Invalid owner reference
test_header "Test 4: Invalid owner reference detection"
cat > "$TEST_DIR/invalid_owner.yml" << 'YAML'
version: "1.0"
requirements:
  - summary: Test
    owner: nonexistent_alias
YAML

if $RQM_CMD validate "$TEST_DIR/invalid_owner.yml" > /dev/null 2>&1; then
    test_failed "Invalid owner should fail validation (pending Rust integration)" "Currently passes"
else
    test_passed "Invalid owner reference rejected"
fi

# Test 5: Valid owner references (email, GitHub, alias)
test_header "Test 5: Valid owner references"
cat > "$TEST_DIR/valid_owners.yml" << 'YAML'
version: "1.0"
aliases:
  - alias: bob
    email: bob@example.com
requirements:
  - summary: Email Owner
    owner: alice@example.com
  - summary: GitHub Owner
    owner: "@githubuser"
  - summary: Alias Owner
    owner: bob
YAML

if $RQM_CMD validate "$TEST_DIR/valid_owners.yml" > /dev/null 2>&1; then
    test_passed "Valid owner references accepted"
else
    test_failed "Valid owners should pass" "Exit code: $?"
fi

# Test 6: Validate RQM's own requirements file
test_header "Test 6: Self-validation - RQM requirements"
if [ -f "$PROJECT_ROOT/.rqm/requirements.yml" ]; then
    if $RQM_CMD validate "$PROJECT_ROOT/.rqm/requirements.yml" > /dev/null 2>&1; then
        test_passed "RQM's own requirements file is valid"
    else
        test_failed "RQM requirements should be valid" "Our own requirements file failed validation"
    fi
else
    test_failed "RQM requirements file not found" "Expected at .rqm/requirements.yml"
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
