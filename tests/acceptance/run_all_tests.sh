#!/usr/bin/env bash
# RQM - Requirements Management in Code
# Test Runner: Process all requirements and run acceptance tests
# SPDX-License-Identifier: MIT

# Use bash 4+ if available (for associative arrays)
if [ -x /usr/local/bin/bash ] && /usr/local/bin/bash --version | grep -q "version [4-9]"; then
    exec /usr/local/bin/bash "$0" "$@"
fi

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Test statistics
TOTAL_REQUIREMENTS=0
REQUIREMENTS_WITH_TESTS=0
REQUIREMENTS_WITHOUT_TESTS=0
TOTAL_TESTS_PASSED=0
TOTAL_TESTS_FAILED=0
TOTAL_TESTS_RUN=0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REQUIREMENTS_FILE="$PROJECT_ROOT/.rqm/requirements.yml"
ACCEPTANCE_DIR="$SCRIPT_DIR"

# Ensure RQM binary exists
RQM_BINARY="$PROJECT_ROOT/go-cli/rqm"
if [[ ! -x "$RQM_BINARY" ]]; then
    echo -e "${RED}Error: RQM binary not found at $RQM_BINARY${NC}"
    echo "Please build it first: cd go-cli && go build -o rqm"
    exit 1
fi

# Print header
print_header() {
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║          RQM Requirement Test Runner                          ║${NC}"
    echo -e "${BOLD}${CYAN}║          Requirement-Driven Development Validation            ║${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print section header
print_section() {
    echo ""
    echo -e "${BOLD}${BLUE}▶ $1${NC}"
    echo -e "${BLUE}$(printf '─%.0s' {1..70})${NC}"
}

# Extract requirement IDs from requirements file
get_requirement_ids() {
    # Use RQM to get JSON output and extract requirement names
    "$RQM_BINARY" list "$REQUIREMENTS_FILE" --format json 2>/dev/null | \
        jq -r '.requirements | .. | objects | select(.name != null) | .name' | \
        grep -E '^RQM-[0-9]+(\.[0-9]+)*$' | \
        sort -V || true
}

# Find acceptance test for a requirement
find_test_for_requirement() {
    local req_id="$1"
    
    # First, check if requirement has acceptance_test_link field
    local test_link
    test_link=$("$RQM_BINARY" list "$REQUIREMENTS_FILE" --format json 2>/dev/null | \
        jq -r --arg id "$req_id" '
            .requirements | .. | objects | select(.name == $id) | .acceptance_test_link // empty
        ' 2>/dev/null | head -1 || true)
    
    if [[ -n "$test_link" ]]; then
        # Extract filename from GitHub URL
        local test_file=$(basename "$test_link")
        if [[ -f "$ACCEPTANCE_DIR/$test_file" ]]; then
            echo "$ACCEPTANCE_DIR/$test_file"
            return 0
        fi
    fi
    
    # Fallback: Try to match by naming convention
    local req_name=$(echo "$req_id" | tr '[:upper:]' '[:lower:]') # Convert to lowercase
    req_name="${req_name//-/_}"   # Replace hyphens with underscores
    
    # Look for test files matching the pattern
    local test_patterns=(
        "test_${req_name}.sh"
        "test_${req_name}_*.sh"
        "test_*${req_name}*.sh"
    )
    
    for pattern in "${test_patterns[@]}"; do
        local matches=("$ACCEPTANCE_DIR"/$pattern)
        if [[ -f "${matches[0]}" ]]; then
            echo "${matches[0]}"
            return 0
        fi
    done
    
    # Check if requirement description suggests a known test
    local req_summary
    req_summary=$("$RQM_BINARY" list "$REQUIREMENTS_FILE" --format json 2>/dev/null | \
        jq -r --arg id "$req_id" '.[] | select(.name == $id) | .summary' || true)
    
    if [[ "$req_summary" =~ "validation" ]] || [[ "$req_summary" =~ "Validation" ]]; then
        if [[ -f "$ACCEPTANCE_DIR/test_validation.sh" ]]; then
            echo "$ACCEPTANCE_DIR/test_validation.sh"
            return 0
        fi
    fi
    
    if [[ "$req_summary" =~ "CLI List" ]] || [[ "$req_id" == "RQM-013"* ]]; then
        if [[ -f "$ACCEPTANCE_DIR/test_cli_list.sh" ]]; then
            echo "$ACCEPTANCE_DIR/test_cli_list.sh"
            return 0
        fi
    fi
    
    if [[ "$req_summary" =~ "CLI Graph" ]] || [[ "$req_id" == "RQM-014"* ]]; then
        if [[ -f "$ACCEPTANCE_DIR/test_cli_graph.sh" ]]; then
            echo "$ACCEPTANCE_DIR/test_cli_graph.sh"
            return 0
        fi
    fi
    
    if [[ "$req_summary" =~ "CLI Check" ]] || [[ "$req_id" == "RQM-015"* ]]; then
        if [[ -f "$ACCEPTANCE_DIR/test_cli_check.sh" ]]; then
            echo "$ACCEPTANCE_DIR/test_cli_check.sh"
            return 0
        fi
    fi
    
    return 1
}

# Run a test file and capture results
run_test_file() {
    local test_file="$1"
    local output
    local exit_code=0
    
    # Run test and capture output
    output=$(bash "$test_file" 2>&1) || exit_code=$?
    
    # Parse test results from output
    local passed=0
    local failed=0
    
    if echo "$output" | grep -q "All tests passed"; then
        passed=$(echo "$output" | grep -oE '[0-9]+ tests passed' | grep -oE '[0-9]+' || echo "0")
    elif echo "$output" | grep -q "Tests passed:"; then
        passed=$(echo "$output" | grep "Tests passed:" | grep -oE '[0-9]+' | head -1 || echo "0")
        failed=$(echo "$output" | grep "Tests failed:" | grep -oE '[0-9]+' | head -1 || echo "0")
    fi
    
    echo "$passed|$failed|$exit_code"
}

# Get requirement details
get_requirement_details() {
    local req_id="$1"
    "$RQM_BINARY" list "$REQUIREMENTS_FILE" --format json 2>/dev/null | \
        jq -r --arg id "$req_id" '
            .requirements | .. | objects | select(.name == $id) | 
            "\(.summary)|\(.status // "unknown")|\(.priority // "medium")"
        ' 2>/dev/null | head -1 || echo "Unknown|unknown|medium"
}

# Main test runner
main() {
    print_header
    
    # Validate requirements file
    print_section "Validating Requirements File"
    if "$RQM_BINARY" validate "$REQUIREMENTS_FILE" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Requirements file is valid"
    else
        echo -e "${RED}✗${NC} Requirements file validation failed"
        exit 1
    fi
    
    # Get all requirement IDs
    print_section "Discovering Requirements"
    local req_ids=()
    while IFS= read -r line; do
        req_ids+=("$line")
    done < <(get_requirement_ids)
    TOTAL_REQUIREMENTS=${#req_ids[@]}
    echo -e "Found ${BOLD}$TOTAL_REQUIREMENTS${NC} requirements"
    
    # Process each requirement
    print_section "Running Acceptance Tests"
    echo ""
    
    # Track which test files we've already run (to avoid running same test multiple times)
    local tested_files=""
    
    for req_id in "${req_ids[@]}"; do
        # Get requirement details
        local details
        details=$(get_requirement_details "$req_id")
        IFS='|' read -r summary status priority <<< "$details"
        
        # Find acceptance test
        local test_file
        test_file=$(find_test_for_requirement "$req_id") || test_file=""
        
        # Print requirement info
        echo -e "${BOLD}${MAGENTA}$req_id${NC} - $summary"
        echo -e "  Status: ${CYAN}$status${NC} | Priority: ${YELLOW}$priority${NC}"
        
        if [[ -z "$test_file" ]]; then
            echo -e "  ${YELLOW}⚠${NC}  No acceptance test found"
            ((REQUIREMENTS_WITHOUT_TESTS++)) || true
        else
            local test_name
            test_name=$(basename "$test_file")
            
            # Check if we've already run this test file
            if echo "$tested_files" | grep -q "|$test_file|"; then
                echo -e "  ${BLUE}ℹ${NC}  Covered by: $test_name (already run)"
            else
                echo -e "  ${BLUE}▶${NC}  Running: $test_name"
                local results
                results=$(run_test_file "$test_file")
                IFS='|' read -r passed failed exit_code <<< "$results"
                tested_files="${tested_files}|${test_file}|"
                
                if [[ $exit_code -eq 0 ]]; then
                    echo -e "  ${GREEN}✓${NC}  Tests passed: $passed"
                    ((TOTAL_TESTS_PASSED += passed)) || true
                else
                    echo -e "  ${RED}✗${NC}  Tests passed: $passed, failed: $failed"
                    ((TOTAL_TESTS_PASSED += passed)) || true
                    ((TOTAL_TESTS_FAILED += failed)) || true
                fi
                ((TOTAL_TESTS_RUN += passed + failed)) || true
            fi
            ((REQUIREMENTS_WITH_TESTS++)) || true
        fi
        echo ""
    done
    
    # Print summary
    print_section "Test Summary"
    echo ""
    echo -e "${BOLD}Requirements Coverage:${NC}"
    echo -e "  Total requirements:       $TOTAL_REQUIREMENTS"
    echo -e "  With acceptance tests:    ${GREEN}$REQUIREMENTS_WITH_TESTS${NC}"
    echo -e "  Without tests:            ${YELLOW}$REQUIREMENTS_WITHOUT_TESTS${NC}"
    
    if [[ $REQUIREMENTS_WITH_TESTS -gt 0 ]]; then
        local coverage_pct
        coverage_pct=$(awk "BEGIN {printf \"%.1f\", ($REQUIREMENTS_WITH_TESTS / $TOTAL_REQUIREMENTS) * 100}")
        echo -e "  Test coverage:            ${CYAN}${coverage_pct}%${NC}"
    fi
    
    echo ""
    echo -e "${BOLD}Test Results:${NC}"
    echo -e "  Total tests run:          $TOTAL_TESTS_RUN"
    echo -e "  Tests passed:             ${GREEN}$TOTAL_TESTS_PASSED${NC}"
    echo -e "  Tests failed:             ${RED}$TOTAL_TESTS_FAILED${NC}"
    
    if [[ $TOTAL_TESTS_RUN -gt 0 ]]; then
        local pass_rate
        pass_rate=$(awk "BEGIN {printf \"%.1f\", ($TOTAL_TESTS_PASSED / $TOTAL_TESTS_RUN) * 100}")
        echo -e "  Pass rate:                ${CYAN}${pass_rate}%${NC}"
    fi
    
    echo ""
    
    # Exit with appropriate code
    if [[ $TOTAL_TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}${BOLD}Some tests failed!${NC}"
        exit 1
    elif [[ $REQUIREMENTS_WITHOUT_TESTS -gt 0 ]]; then
        echo -e "${YELLOW}${BOLD}Warning: Some requirements lack acceptance tests${NC}"
        exit 0
    else
        echo -e "${GREEN}${BOLD}All tests passed! ✓${NC}"
        exit 0
    fi
}

# Run main function
main "$@"
