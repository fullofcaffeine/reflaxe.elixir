#!/bin/bash
# test-runner.sh - Advanced test runner for Reflaxe.Elixir
# Provides modern test runner features on top of the Makefile infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_DIR="$PROJECT_ROOT/test"
CACHE_DIR="$TEST_DIR/.test-cache"
RESULTS_FILE="$CACHE_DIR/last-run.json"
MAKEFILE="$TEST_DIR/Makefile"

# Default values
PARALLEL=4
CATEGORY=""
PATTERN=""
UPDATE=false
FAILED_ONLY=false
CHANGED_ONLY=false
VERBOSE=false
WATCH=false
SERVER=false
TIMEOUT=120

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# Help message
show_help() {
    echo "Reflaxe.Elixir Test Runner"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --category <name>      Run tests by category (core, stdlib, regression, phoenix, ecto, otp)"
    echo "  --pattern <pattern>    Run tests matching pattern (e.g., '*array*', '*date*')"
    echo "  --changed              Run only tests affected by git changes"
    echo "  --failed               Re-run only failed tests from last run"
    echo "  --update               Update intended outputs for failing tests"
    echo "  --parallel <n>         Number of parallel jobs (default: 4)"
    echo "  --verbose              Show detailed output"
    echo "  --server               Use Haxe compilation server for faster compilation"
    echo "  --timeout <seconds>    Test timeout in seconds (default: 120)"
    echo "  --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --category core --parallel 8"
    echo "  $0 --pattern '*date*' --update"
    echo "  $0 --changed --verbose"
    echo "  $0 --failed"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --category)
            CATEGORY="$2"
            shift 2
            ;;
        --pattern)
            PATTERN="$2"
            shift 2
            ;;
        --changed)
            CHANGED_ONLY=true
            shift
            ;;
        --failed)
            FAILED_ONLY=true
            shift
            ;;
        --update)
            UPDATE=true
            shift
            ;;
        --parallel)
            PARALLEL="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --server)
            SERVER=true
            shift
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Function to start Haxe compilation server
start_haxe_server() {
    if [ "$SERVER" = true ]; then
        echo -e "${BLUE}Starting Haxe compilation server...${RESET}"
        pkill -f "haxe --wait" 2>/dev/null || true
        haxe --wait 6000 &
        HAXE_SERVER_PID=$!
        sleep 2
        echo -e "${GREEN}Haxe server started (PID: $HAXE_SERVER_PID)${RESET}"
        export HAXE_SERVER_PORT=6000
    fi
}

# Function to stop Haxe compilation server
stop_haxe_server() {
    if [ "$SERVER" = true ] && [ -n "$HAXE_SERVER_PID" ]; then
        echo -e "${BLUE}Stopping Haxe compilation server...${RESET}"
        kill $HAXE_SERVER_PID 2>/dev/null || true
    fi
}

# Trap to ensure server is stopped on exit
trap stop_haxe_server EXIT

# Function to get changed files
get_changed_files() {
    local base_ref="${1:-origin/main}"
    git diff --name-only "$base_ref" | grep -E '\.(hx|hxml)$' || true
}

# Function to find tests affected by changes
find_affected_tests() {
    local changed_files="$(get_changed_files)"
    local affected_tests=""
    
    if [ -z "$changed_files" ]; then
        echo ""
        return
    fi
    
    # Map compiler source files to test categories
    while IFS= read -r file; do
        case "$file" in
            src/reflaxe/elixir/helpers/ArrayCompiler.hx|src/reflaxe/elixir/ast/*Array*)
                affected_tests="$affected_tests stdlib/array_* core/arrays"
                ;;
            src/reflaxe/elixir/*Loop*|src/reflaxe/elixir/*While*|src/reflaxe/elixir/*For*)
                affected_tests="$affected_tests core/loops core/for_* core/while_*"
                ;;
            src/reflaxe/elixir/*Pattern*|src/reflaxe/elixir/*Match*)
                affected_tests="$affected_tests core/pattern_* core/match_*"
                ;;
            src/reflaxe/elixir/*Phoenix*|std/phoenix/*)
                affected_tests="$affected_tests phoenix/*"
                ;;
            src/reflaxe/elixir/*Ecto*|std/ecto/*)
                affected_tests="$affected_tests ecto/*"
                ;;
            src/reflaxe/elixir/*OTP*|std/otp/*)
                affected_tests="$affected_tests otp/*"
                ;;
            std/*)
                affected_tests="$affected_tests stdlib/*"
                ;;
            test/snapshot/*/Main.hx)
                # If a test file changed, run that specific test
                local test_dir=$(dirname "$file" | sed 's|test/snapshot/||')
                affected_tests="$affected_tests $test_dir"
                ;;
        esac
    done <<< "$changed_files"
    
    echo "$affected_tests" | tr ' ' '\n' | sort -u | tr '\n' ' '
}

# Function to get failed tests from last run
get_failed_tests() {
    if [ -f "$TEST_DIR/test-results.tmp" ]; then
        grep "❌" "$TEST_DIR/test-results.tmp" | sed 's/❌ //' | sed 's/ -.*//' | tr '\n' ' '
    else
        echo ""
    fi
}

# Function to run tests
run_tests() {
    local make_target=""
    local make_args="-j$PARALLEL"
    
    # Determine what tests to run
    local aggregate_mode=false
    if [ "$FAILED_ONLY" = true ]; then
        echo -e "${YELLOW}Re-running failed tests from last run...${RESET}"
        local failed_tests=$(get_failed_tests)
        if [ -z "$failed_tests" ]; then
            echo -e "${GREEN}No failed tests to re-run${RESET}"
            exit 0
        fi
        make_target="test-failed"
    elif [ "$CHANGED_ONLY" = true ]; then
        echo -e "${YELLOW}Finding tests affected by changes...${RESET}"
        local affected_tests=$(find_affected_tests)
        if [ -z "$affected_tests" ]; then
            echo -e "${GREEN}No tests affected by changes${RESET}"
            exit 0
        fi
        echo -e "${BLUE}Affected tests: $affected_tests${RESET}"
        # Convert to make targets
        for test in $affected_tests; do
            make_target="$make_target test-$(echo $test | sed 's|/|__|g')"
        done
    elif [ -n "$CATEGORY" ]; then
        echo -e "${YELLOW}Running $CATEGORY tests...${RESET}"
        make_target="test-$CATEGORY"
        aggregate_mode=true
    elif [ -n "$PATTERN" ]; then
        echo -e "${YELLOW}Running tests matching pattern: $PATTERN${RESET}"
        make_target="test-pattern PATTERN=$PATTERN"
    else
        echo -e "${YELLOW}Running all tests...${RESET}"
        make_target="all"
        aggregate_mode=true
    fi
    
    # Add verbose flag if requested
    if [ "$VERBOSE" = true ]; then
        make_args="$make_args -v"
    fi
    
    # Start Haxe server if requested
    start_haxe_server
    
    # Run the tests
    cd "$TEST_DIR"
    echo -e "${BLUE}Executing: make -f Makefile $make_args $make_target${RESET}"
    # Ensure fresh results file for accurate summary
    rm -f test-results*.tmp 2>/dev/null || true
    
    if [ "$UPDATE" = true ]; then
        # If updating, run tests and then update failed ones
        make -f Makefile $make_args $make_target || true
        
        # Find failed tests and update their intended outputs
        local failed_tests=$(get_failed_tests)
        if [ -n "$failed_tests" ]; then
            echo -e "${YELLOW}Updating intended outputs for failed tests...${RESET}"
            for test in $failed_tests; do
                echo -e "${BLUE}Updating: $test${RESET}"
                make -f Makefile update-intended TEST="$test"
            done
            echo -e "${GREEN}Updated intended outputs${RESET}"
        else
            echo -e "${GREEN}No failed tests to update${RESET}"
        fi
    else
        if [ "$aggregate_mode" = true ]; then
            # Aggregated targets (all/categories) return proper exit codes
            if make -f Makefile $make_args $make_target; then
                echo -e "${GREEN}All tests passed! ✅${RESET}"
                exit 0
            else
                echo -e "${RED}Some tests failed ❌${RESET}"
                echo -e "${YELLOW}Run with --failed to re-run only failed tests${RESET}"
                echo -e "${YELLOW}Run with --update to update intended outputs${RESET}"
                exit 1
            fi
        else
            # Non-aggregated targets (pattern/changed/failed): decide based on result files
            make -f Makefile $make_args $make_target || true
            if grep -q "❌" test-results*.tmp 2>/dev/null; then
                echo -e "${RED}Some tests failed ❌${RESET}"
                grep "❌" test-results*.tmp | sed 's/^/  /' || true
                echo -e "${YELLOW}Run with --failed to re-run only failed tests${RESET}"
                echo -e "${YELLOW}Run with --update to update intended outputs${RESET}"
                exit 1
            else
                echo -e "${GREEN}All tests passed! ✅${RESET}"
                exit 0
            fi
        fi
    fi
}

# Function to show test statistics
show_stats() {
    if [ -f "$TEST_DIR/test-results.tmp" ]; then
        local passed=0
        local failed=0
        
        if grep -q "✅" "$TEST_DIR/test-results.tmp" 2>/dev/null; then
            passed=$(grep -c "✅" "$TEST_DIR/test-results.tmp")
        fi
        
        if grep -q "❌" "$TEST_DIR/test-results.tmp" 2>/dev/null; then
            failed=$(grep -c "❌" "$TEST_DIR/test-results.tmp")
        fi
        
        local total=$((passed + failed))
        
        echo ""
        echo -e "${BLUE}Test Results Summary:${RESET}"
        echo -e "  Total:  $total"
        echo -e "  ${GREEN}Passed: $passed${RESET}"
        echo -e "  ${RED}Failed: $failed${RESET}"
        
        if [ "$failed" -gt 0 ]; then
            echo ""
            echo -e "${YELLOW}Failed tests:${RESET}"
            grep "❌" "$TEST_DIR/test-results.tmp" | sed 's/^/  /'
        fi
    fi
}

# Main execution
run_tests
show_stats
