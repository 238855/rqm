# RQM Testing Guide

## Overview

RQM uses **Requirement-Driven Development (RDD)** where every requirement has corresponding acceptance tests. This document describes our testing philosophy, infrastructure, and current coverage.

## Test Philosophy

1. **Requirements as Tests**: Every requirement in `.rqm/requirements.yml` should have an `acceptance_test_link`
2. **100% Coverage Goal**: All requirements must have acceptance tests
3. **Test-Driven**: Tests are written before or alongside implementation
4. **Multiple Layers**: Unit tests, integration tests, and acceptance tests

## Test Infrastructure

### Test Runner

Location: `tests/acceptance/run_all_tests.sh`

Features:
- **Automatic Test Discovery**: Finds all `test_*.sh` files
- **Timeout Protection**: 60-second timeout per test with countdown timer
- **Full Output Visibility**: No piping/grep that obscures hanging tests
- **Recursion Prevention**: `RQM_TEST_RUNNER_ACTIVE` environment variable
- **Coverage Tracking**: Links tests to requirements, shows coverage percentage
- **Pass/Fail Statistics**: Detailed summary with color-coded output

Usage:
```bash
cd tests/acceptance
./run_all_tests.sh
```

### Coverage Collection

Location: `tests/acceptance/collect_coverage.sh`

Collects code coverage from:
- **Go CLI**: Uses `go test -coverprofile`
- **Rust Core**: Uses `cargo-llvm-cov` (requires `llvm-tools-preview`)

Usage:
```bash
cd tests/acceptance
./collect_coverage.sh
```

Output:
- `.coverage/go-coverage.out` - Go coverage profile
- `.coverage/go-coverage.html` - Go coverage HTML report
- `.coverage/rust-coverage.json` - Rust coverage JSON (if llvm-tools installed)
- `.coverage/rust-coverage.txt` - Rust coverage summary

## Test Structure

### Acceptance Tests

Location: `tests/acceptance/`

Test files follow the pattern `test_*.sh`:

| Test File | Requirements | Tests | Description |
|-----------|-------------|-------|-------------|
| `test_validation.sh` | RQM-001 | 6 | YAML validation basics |
| `test_rqm001_subrequirements.sh` | RQM-001.x | 13 | Schema loading, unique summaries, owner validation |
| `test_circular_references.sh` | RQM-002 | 8 | Cycle detection in requirement graphs |
| `test_rqm002_subrequirements.sh` | RQM-002.x | 10 | Cycle algorithm, visited tracking, depth limits |
| `test_cli_validate.sh` | RQM-003 | 10 | CLI validation command integration |
| `test_rqm003_subrequirements.sh` | RQM-003.x | 14 | File checks, Rust validator integration |
| `test_rdd_workflow.sh` | RQM-004 | 10 | RDD workflow and test links |
| `test_rqm004_subrequirements.sh` | RQM-004.x | 17 | Acceptance test links, test execution |
| `test_cli_check.sh` | General | 3 | CLI check command |
| `test_cli_list.sh` | General | 3 | CLI list command |
| `test_cli_graph.sh` | General | 4 | CLI graph command |

**Total**: 11 test files, 88 test scenarios

### Unit Tests

#### Rust (`rust-core/`)

Run: `cargo test`

Coverage: Requires `cargo-llvm-cov` + `llvm-tools-preview`

24 tests covering:
- YAML parsing (`parser.rs`)
- Schema validation (`validator.rs`)
- Graph operations (`graph.rs`)
- Type conversions (`types.rs`)
- Metadata management (`metadata.rs`)

#### Go (`go-cli/`)

Run: `go test -v ./...`

Coverage: 24.1% (7 tests)

Tests:
- `cmd/validate_test.go`: Validation command integration
- Core CLI command functionality

## Current Coverage

### Requirements Coverage

```
Total requirements:       14
With acceptance tests:    14
Without tests:            0
Test coverage:            100.0% ✓
```

All 14 requirements have acceptance tests!

### Test Results

```
Total tests run:          88
Tests passed:             88
Tests failed:             0
Pass rate:                100.0% ✓
```

### Code Coverage

- **Go (CLI)**: 24.1%
- **Rust (Core)**: Requires `llvm-tools-preview` installation

To improve Go coverage:
```bash
cd go-cli
go test -v -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

## Running Tests

### Quick Test

```bash
# Just the acceptance tests
cd tests/acceptance
./run_all_tests.sh
```

### Full Test Suite

```bash
# Rust unit tests
cd rust-core
cargo test

# Go unit tests
cd go-cli
go test -v ./...

# Acceptance tests + coverage
cd tests/acceptance
./run_all_tests.sh
./collect_coverage.sh
```

### Test a Specific Requirement

```bash
cd tests/acceptance

# Test RQM-001 (YAML Validation)
./test_rqm001_subrequirements.sh

# Test RQM-002 (Circular References)
./test_rqm002_subrequirements.sh

# Test RQM-003 (CLI Validation)
./test_rqm003_subrequirements.sh

# Test RQM-004 (RDD Support)
./test_rqm004_subrequirements.sh
```

## Test Fixtures

Location: `tests/acceptance/fixtures/`

Contains sample YAML files for testing:
- Valid configurations
- Invalid configurations (duplicate summaries, invalid owners, etc.)
- Edge cases (circular references, deep nesting, etc.)
- CLI integration examples

## Writing New Tests

### Acceptance Test Template

```bash
#!/usr/bin/env bash
# RQM-XXX: Requirement Name
# Tests the specific requirement functionality

set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="$PROJECT_ROOT/tests/acceptance/fixtures"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

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
    if [ -n "$2" ]; then
        echo "  $2"
    fi
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
}

# Your tests here...

# Summary
echo "Tests run: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    exit 1
else
    echo "All tests passed!"
    exit 0
fi
```

### Adding Test to Requirements

Update `.rqm/requirements.yml`:

```yaml
- summary: Your Requirement
  name: RQM-XXX
  description: What it does
  owner: your-alias
  acceptance_test_link: https://github.com/238855/rqm/blob/main/tests/acceptance/test_your_feature.sh
```

## Continuous Integration

The test runner is CI/CD-friendly:
- Returns **exit code 0** on success
- Returns **exit code 1** on any test failure
- Provides structured output for parsing
- Timeout protection prevents hanging

## Known Limitations

### Test 8 in `test_cli_validate.sh`

The validator binary path is relative to the current working directory. Tests document this as a known limitation. Future enhancement: make validator path configurable.

### Rust Coverage

Requires installation of:
```bash
rustup component add llvm-tools-preview
cargo install cargo-llvm-cov
```

Without these, Rust coverage metrics won't be displayed.

## Future Enhancements

1. **Increase Go Unit Test Coverage**: Target 50%+ (currently 24.1%)
2. **Rust Coverage Integration**: Install llvm-tools for detailed metrics
3. **Performance Benchmarks**: Add `test_performance.sh` for large files
4. **Web UI Tests**: Add Playwright/Cypress tests for React components
5. **Test Parallelization**: Run independent test files in parallel
6. **Coverage Trend Tracking**: Track coverage changes over time

## Maintenance

### After Adding a Requirement

1. Create acceptance test file: `test_rqm_XXX.sh`
2. Add `acceptance_test_link` to requirement
3. Run `./run_all_tests.sh` to verify
4. Commit both requirement and test together

### After Changing a Requirement

1. Update corresponding acceptance test
2. Ensure test still passes
3. Update test documentation if needed

### Before Merging PRs

1. All acceptance tests must pass (88/88)
2. No decrease in requirements coverage (100%)
3. Run `./collect_coverage.sh` to check code coverage
4. Go coverage should not decrease from 24.1%

## Resources

- [RDD Workflow Guide](RDD.ai.md)
- [Requirements File](.rqm/requirements.yml)
- [Test Runner Source](tests/acceptance/run_all_tests.sh)
- [Coverage Collector](tests/acceptance/collect_coverage.sh)

---

**Last Updated**: 2024-11-16  
**Test Count**: 88 scenarios  
**Requirements Coverage**: 100% (14/14)  
**Pass Rate**: 100%
