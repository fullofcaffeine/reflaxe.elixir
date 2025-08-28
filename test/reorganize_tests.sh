#!/bin/bash

# Test Reorganization Script
# Categorizes and moves tests to appropriate directories

cd /Users/fullofcaffeine/workspace/code/haxe.elixir/test

echo "Starting test reorganization..."

# Core language features
echo "Moving core language tests..."
mv tests/arrays snapshot/core/ 2>/dev/null
mv tests/classes snapshot/core/ 2>/dev/null
mv tests/enums snapshot/core/ 2>/dev/null
mv tests/basic_syntax snapshot/core/ 2>/dev/null
mv tests/abstract_types snapshot/core/ 2>/dev/null
mv tests/dynamic snapshot/core/ 2>/dev/null
mv tests/maps snapshot/core/ 2>/dev/null
mv tests/maps_functional snapshot/core/ 2>/dev/null
mv tests/MapIdiomatic snapshot/core/ 2>/dev/null
mv tests/strings snapshot/core/ 2>/dev/null
mv tests/variables snapshot/core/ 2>/dev/null
mv tests/pattern_matching snapshot/core/ 2>/dev/null
mv tests/enhanced_pattern_matching snapshot/core/ 2>/dev/null
mv tests/enhanced_patterns snapshot/core/ 2>/dev/null
mv tests/advanced_patterns snapshot/core/ 2>/dev/null
mv tests/switch_patterns snapshot/core/ 2>/dev/null
mv tests/AsyncAnonymousFunctions snapshot/core/ 2>/dev/null
mv tests/LambdaVariableScope snapshot/core/ 2>/dev/null
mv tests/js_async_await snapshot/core/ 2>/dev/null

# Loop-related tests
echo "Moving loop tests to core..."
mv tests/loop_patterns snapshot/core/ 2>/dev/null
mv tests/loop_variable_assignment snapshot/core/ 2>/dev/null
mv tests/loop_variable_mapping snapshot/core/ 2>/dev/null
mv tests/enum_with_index_optimization snapshot/core/ 2>/dev/null

# Phoenix framework
echo "Moving Phoenix tests..."
mv tests/hxx_template snapshot/phoenix/ 2>/dev/null
mv tests/liveview_basic snapshot/phoenix/ 2>/dev/null
mv tests/router snapshot/phoenix/ 2>/dev/null
mv tests/phoenix_* snapshot/phoenix/ 2>/dev/null

# Ecto
echo "Moving Ecto tests..."
mv tests/ecto_schema snapshot/ecto/ 2>/dev/null
mv tests/ecto_integration snapshot/ecto/ 2>/dev/null
mv tests/ecto_error_test snapshot/ecto/ 2>/dev/null
mv tests/changeset snapshot/ecto/ 2>/dev/null
mv tests/advanced_ecto snapshot/ecto/ 2>/dev/null
mv tests/migrations* snapshot/ecto/ 2>/dev/null

# OTP
echo "Moving OTP tests..."
mv tests/behavior snapshot/otp/ 2>/dev/null
mv tests/otp_* snapshot/otp/ 2>/dev/null
mv tests/genserver* snapshot/otp/ 2>/dev/null

# Regression tests (bug fixes)
echo "Moving regression tests..."
mv tests/array_push_if_expression snapshot/regression/ 2>/dev/null
mv tests/nested_switch* snapshot/regression/ 2>/dev/null
mv tests/underscore_prefix_consistency snapshot/regression/ 2>/dev/null
mv tests/json_printer_temp_vars snapshot/regression/ 2>/dev/null

# Examples (keep as examples, not tests)
echo "Moving example tests..."
mv tests/example_* snapshot/core/ 2>/dev/null

# Elixir-specific features
echo "Moving Elixir-specific tests..."
mv tests/elixir_idiomatic snapshot/core/ 2>/dev/null
mv tests/elixir_injection_test snapshot/core/ 2>/dev/null
mv tests/ElixirInjection snapshot/core/ 2>/dev/null
mv tests/InjectionDebug snapshot/core/ 2>/dev/null

# Domain abstractions
echo "Moving domain abstraction tests..."
mv tests/domain_abstractions snapshot/core/ 2>/dev/null
mv tests/domain_abstractions_exunit snapshot/core/ 2>/dev/null

# Archive old .hxml files
echo "Archiving old .hxml files..."
mv *.hxml _archive/old_hxml/ 2>/dev/null

# Keep the main Test.hxml and Makefile
mv _archive/old_hxml/Test.hxml . 2>/dev/null

# Archive broken integration tests
echo "Archiving broken integration tests..."
# We'll keep these for now but mark them as needing review
# mv mix_integration_test.exs _archive/broken_integration/ 2>/dev/null

echo "Reorganization complete!"
echo ""
echo "Summary:"
echo "- Core tests moved to: snapshot/core/"
echo "- Phoenix tests moved to: snapshot/phoenix/"
echo "- Ecto tests moved to: snapshot/ecto/"
echo "- OTP tests moved to: snapshot/otp/"
echo "- Regression tests moved to: snapshot/regression/"
echo "- Old .hxml files archived to: _archive/old_hxml/"
echo ""
echo "Remaining tests to categorize:"
ls tests/ 2>/dev/null | head -20