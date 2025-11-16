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

# Display countdown timer
show_countdown() {
    local duration=$1
    local message=$2
    local elapsed=0
    
    while [ $elapsed -lt $duration ]; do
        local remaining=$((duration - elapsed))
        printf "\r  ${CYAN}⏱${NC}  %s [%ds remaining]" "$message" "$remaining"
        sleep 1
        ((elapsed++)) || true
    done
    printf "\r"
}

# Run a test file with timeout and display output
run_test_file() {
    local test_file="$1"
    local timeout="${2:-60}"  # Default 60 second timeout
    local test_name
    test_name=$(basename "$test_file")
    
    echo -e "  ${BLUE}▶${NC}  Running: $test_name (timeout: ${timeout}s)" >&2
    echo "" >&2
    
    # Create temporary files for output and status
    local output_file
    output_file=$(mktemp)
    local status_file
    status_file=$(mktemp)
    
    # Run test in background
    bash "$test_file" > "$output_file" 2>&1 &
    local test_pid=$!
    
    local elapsed=0
    local test_finished=false
    
    # Monitor progress with countdown
    while [ $elapsed -lt $timeout ]; do
        if ! kill -0 "$test_pid" 2>/dev/null; then
            # Test finished
            test_finished=true
            break
        fi
        
        local remaining=$((timeout - elapsed))
        printf "\r  ${CYAN}⏱${NC}  Test running... [${remaining}s remaining]" >&2
        sleep 1
        ((elapsed++)) || true
    done
    printf "\r\033[K" >&2  # Clear the countdown line
    
    local exit_code=0
    
    if [ "$test_finished" = true ]; then
        # Test completed within timeout
        wait "$test_pid" 2>/dev/null || exit_code=$?
        echo "$exit_code" > "$status_file"
    else
        # Test timed out - kill it
        kill -9 "$test_pid" 2>/dev/null || true
        wait "$test_pid" 2>/dev/null || true
        echo "TIMEOUT" > "$status_file"
    fi
    
    # Read the output and status
    local output
    output=$(cat "$output_file")
    local read_exit_code
    read_exit_code=$(cat "$status_file")
    
    # Display the full test output
    echo -e "${BOLD}Test Output:${NC}" >&2
    echo "────────────────────────────────────────────────────────────────────" >&2
    echo "$output" >&2
    echo "────────────────────────────────────────────────────────────────────" >&2
    echo "" >&2
    
    # Parse test results from output
    local passed=0
    local failed=0
    
    if [ "$read_exit_code" = "TIMEOUT" ]; then
        echo -e "  ${RED}✗${NC}  Test TIMED OUT after ${timeout}s" >&2
        rm -f "$output_file" "$status_file"
        echo "0|1|124"
        return
    fi
    
    # Try multiple patterns to parse test results
    # Parse directly from file and use awk to skip ANSI color codes
    if grep -qE "Tests run:|All tests passed" "$output_file"; then
        # Pattern: "Passed: X" - extract number after "Passed:" using awk
        passed=$(grep "Passed:" "$output_file" | tail -1 | awk -F'Passed:' '{print $2}' | grep -oE '[0-9]+' | head -1 || echo "0")
        
        # Pattern: "Failed: X" - extract number after "Failed:" using awk
        failed=$(grep "Failed:" "$output_file" | tail -1 | awk -F'Failed:' '{print $2}' | grep -oE '[0-9]+' | head -1 || echo "0")
        
        # If still 0, try alternate patterns
        if [ "$passed" = "0" ]; then
            # Try: "X tests passed"
            passed=$(grep "tests passed" "$output_file" | head -1 | awk '{print $1}' || echo "0")
        fi
    elif grep -q "Tests passed:" "$output_file"; then
        passed=$(grep "Tests passed:" "$output_file" | awk -F'Tests passed:' '{print $2}' | grep -oE '[0-9]+' | head -1 || echo "0")
        failed=$(grep "Tests failed:" "$output_file" | awk -F'Tests failed:' '{print $2}' | grep -oE '[0-9]+' | head -1 || echo "0")
    fi
    
    # Clean up temp files
    rm -f "$output_file" "$status_file"
    
    printf "%s|%s|%s\n" "$passed" "$failed" "$read_exit_code"
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
    # Set environment variable to prevent recursive calls
    export RQM_TEST_RUNNER_ACTIVE=1
    
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
                # Default timeout of 60 seconds, can be overridden
                local timeout=60
                
                # Run the test with timeout and full output
                local results
                results=$(run_test_file "$test_file" "$timeout")
                IFS='|' read -r passed failed exit_code <<< "$results"
                tested_files="${tested_files}|${test_file}|"
                
                if [[ $exit_code -eq 124 ]]; then
                    echo -e "  ${RED}✗${NC}  Test timed out after ${timeout}s"
                    ((TOTAL_TESTS_FAILED++)) || true
                elif [[ $exit_code -eq 0 ]]; then
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
    
    # Code Coverage
    echo ""
    echo -e "${BOLD}Code Coverage:${NC}"
    
    # Check for Go coverage
    if [[ -f "$PROJECT_ROOT/.coverage/go-coverage.out" ]]; then
        # Need to run from go-cli directory for module path resolution
        local go_cov=$(cd "$PROJECT_ROOT/go-cli" && go tool cover -func=../.coverage/go-coverage.out 2>/dev/null | grep total | awk '{print $3}' || echo "N/A")
        echo -e "  Go (CLI):                 ${CYAN}${go_cov}${NC}"
    elif [[ -f "$PROJECT_ROOT/go-cli/coverage.out" ]]; then
        # Fallback to go-cli directory
        local go_cov=$(cd "$PROJECT_ROOT/go-cli" && go tool cover -func=coverage.out 2>/dev/null | grep total | awk '{print $3}' || echo "N/A")
        echo -e "  Go (CLI):                 ${CYAN}${go_cov}${NC} (run collect_coverage.sh to consolidate)"
    else
        echo -e "  Go (CLI):                 ${YELLOW}Run ./tests/acceptance/collect_coverage.sh${NC}"
    fi
    
    # Check for Rust coverage
    if [[ -f "$PROJECT_ROOT/.coverage/rust-coverage.json" ]] && command -v jq > /dev/null 2>&1; then
        local rust_cov=$(jq -r '.data[0].totals.lines.percent' "$PROJECT_ROOT/.coverage/rust-coverage.json" 2>/dev/null || echo "N/A")
        # Format to 1 decimal place if it's a number
        if [[ "$rust_cov" != "N/A" ]]; then
            rust_cov=$(printf "%.1f" "$rust_cov")
        fi
        echo -e "  Rust (Core):              ${CYAN}${rust_cov}%${NC}"
    elif command -v cargo-llvm-cov > /dev/null 2>&1; then
        echo -e "  Rust (Core):              ${YELLOW}Run ./tests/acceptance/collect_coverage.sh${NC}"
    else
        echo -e "  Rust (Core):              ${YELLOW}Install cargo-llvm-cov for coverage${NC}"
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
