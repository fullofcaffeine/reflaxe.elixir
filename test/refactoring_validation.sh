#!/bin/bash

# Refactoring Validation Script
# Purpose: Validate critical functionality during ElixirASTBuilder modularization
# Run this after each module extraction to ensure nothing breaks

set -e  # Exit on first failure

echo "🔍 ElixirASTBuilder Refactoring Validation Suite"
echo "================================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track failures
FAILED_TESTS=""
PASS_COUNT=0
FAIL_COUNT=0

# Function to run a specific test
run_test() {
    local category=$1
    local test_name=$2
    local description=$3
    
    echo -n "Testing $description... "
    
    if ./scripts/test-runner.sh --pattern "$test_name" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASS_COUNT++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        FAILED_TESTS="$FAILED_TESTS\n  - $category/$test_name: $description"
        ((FAIL_COUNT++))
    fi
}

echo ""
echo "1️⃣  Pattern Matching Tests (convertPattern, extractPatternVariableNames)"
echo "------------------------------------------------------------------------"
run_test "core" "pattern_matching" "Basic pattern matching"
run_test "core" "enhanced_pattern_matching" "Advanced patterns"
run_test "core" "switch_variable_extraction" "Variable extraction from switch"
run_test "core" "CaseClauseVariableDeclarations" "Case clause variables"
run_test "core" "enum_pattern_rebinding" "Enum parameter handling"
run_test "core" "SyntheticBindingsInCase" "Synthetic bindings in case"

echo ""
echo "2️⃣  Loop Optimization Tests (tryOptimizeArrayPattern, generateEnum*)"
echo "-------------------------------------------------------------------"
run_test "core" "loop_patterns" "Various loop patterns"
run_test "core" "loop_variable_mapping" "Variable mapping in loops"
run_test "core" "loop_variable_assignment" "Loop variable assignments"
run_test "loop_desugaring" "*" "Array operation desugaring"
run_test "loops" "*" "General loop tests"

echo ""
echo "3️⃣  @:application and @:presence Tests (CRITICAL - Failed Previously)"
echo "--------------------------------------------------------------------"
run_test "otp" "type_safe_child_specs" "@:application handling"
run_test "phoenix" "presence" "Basic presence tests"
run_test "phoenix" "phoenix_presence" "Phoenix presence integration"
run_test "phoenix" "PresenceMacro" "Macro-based presence"
run_test "phoenix" "PhoenixPresenceBehavior" "Behavior transformation"

echo ""
echo "4️⃣  Comprehension Building Tests (tryBuildArrayComprehensionFromBlock)"
echo "---------------------------------------------------------------------"
run_test "core" "array_map_idiomatic" "Array operations"
run_test "stdlib" "Lambda" "Lambda comprehensions"

echo ""
echo "5️⃣  Variable Management Tests (usesVariable, toElixirVarName)"
echo "------------------------------------------------------------"
run_test "core" "parameter_naming" "Parameter naming"
run_test "regression" "underscore_prefix_consistency" "Underscore prefixing"
run_test "regression" "infrastructure_var_naming" "Variable naming"

echo ""
echo "6️⃣  Enum Handling Tests (createEnumBindingPlan, convertIdiomaticEnum*)"
echo "---------------------------------------------------------------------"
run_test "regression" "orphaned_enum_parameters" "Orphaned enum parameters"
run_test "regression" "EnumParameterExtraction" "Enum parameter extraction"

echo ""
echo "================================================"
echo "📊 VALIDATION RESULTS"
echo "================================================"
echo -e "Passed: ${GREEN}$PASS_COUNT${NC}"
echo -e "Failed: ${RED}$FAIL_COUNT${NC}"

if [ $FAIL_COUNT -gt 0 ]; then
    echo ""
    echo -e "${RED}⚠️  VALIDATION FAILED${NC}"
    echo "The following tests failed after refactoring:"
    echo -e "$FAILED_TESTS"
    echo ""
    echo "DO NOT proceed with further extraction until these are fixed!"
    exit 1
else
    echo ""
    echo -e "${GREEN}✅ ALL VALIDATIONS PASSED${NC}"
    echo "Safe to proceed with next extraction phase."
fi

echo ""
echo "💡 Next Steps:"
echo "1. If all tests pass, commit the current extraction"
echo "2. Move to the next module in the extraction plan"
echo "3. Run this script again after each extraction"