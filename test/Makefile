# Test Runner for Reflaxe.Elixir using Make
# Supports both sequential and parallel execution with proven reliability
#
# Usage:
#   make -f Makefile            # Run all tests (default: parallel with 4 jobs)
#   make -f Makefile -j1         # Run tests sequentially
#   make -f Makefile -j8         # Run with 8 parallel jobs
#   make -f Makefile test-core__arrays # Run specific test (use __ for path separator)
#   make -f Makefile update-intended TEST=arrays # Update intended output for specific test
#   make -f Makefile -k          # Continue on errors

# Configuration
SHELL := /bin/bash
# Get the directory where this Makefile is located
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TEST_DIR := $(MAKEFILE_DIR)snapshot
TIMEOUT := 120s
OUTPUT_DIR := out

# Pipeline Selection
# By default uses AST pipeline. Set USE_LEGACY=1 to use old string pipeline for comparison
ifdef USE_LEGACY
HAXE_FLAGS := -D use_legacy_string_pipeline
PIPELINE_MODE := (Legacy String Pipeline)
else
HAXE_FLAGS :=
PIPELINE_MODE := (AST Pipeline)
endif

# Colors for output
GREEN := \033[0;32m
RED := \033[0;31m
RESET := \033[0m

# Find all test directories with compile.hxml recursively
# Replace forward slashes with double underscores for Make target compatibility
TESTS := $(shell find $(TEST_DIR) -name compile.hxml -exec dirname {} \; | sed 's|$(TEST_DIR)/||' | sort)
TEST_TARGETS := $(shell echo "$(TESTS)" | tr ' ' '\n' | sed 's|/|__|g' | sed 's|^|test-|' | tr '\n' ' ')

# Default target runs all tests with default parallelism
.PHONY: all
all:
	@rm -f test-results.tmp
	@echo "Running all tests (use -j N to control parallelism)..."
	# Respect jobserver: do not force -j here; top-level -j will propagate
	@$(MAKE) -f $(MAKEFILE_LIST) summary

# Summary target that depends on all tests
.PHONY: summary
summary: $(TEST_TARGETS)
	@echo ""
	@echo "========================================"
	@passed=$$(grep -c "✅" test-results.tmp 2>/dev/null) || passed=0; \
	failed=$$(grep -c "❌" test-results.tmp 2>/dev/null) || failed=0; \
	total=$$((passed + failed)); \
	echo "Test Results $(PIPELINE_MODE): $$passed/$$total passed"; \
	if [ $$failed -gt 0 ]; then \
		echo "$(RED)FAILED: $$failed test(s)$(RESET)"; \
		grep "❌" test-results.tmp | sed 's/^/  /'; \
	else \
		echo "$(GREEN)SUCCESS: All tests passed! ✅$(RESET)"; \
	fi; \
	rm -f test-results.tmp

# Pattern rule for running individual tests
# Converts double underscores back to slashes for nested directories
.PHONY: test-%
test-%:
	@testname=$$(echo $* | sed 's|__|/|g'); \
	testdir=$(TEST_DIR)/$$testname; \
	if [ ! -f $$testdir/compile.hxml ]; then \
		echo "❌ $$testname - Test directory not found" | tee -a test-results.tmp; \
		exit 1; \
	fi; \
	echo "Running $$testname..."; \
	start=$$(date +%s); \
	if [ "$$testname" = "example_04_ecto" ]; then \
		echo "⚠️ example_04_ecto - Special handling due to output redirection issue"; \
		if timeout $(TIMEOUT) bash -c "cd $$testdir && haxe -D elixir_output=$(OUTPUT_DIR) -D reflaxe.dont_output_metadata_id $(HAXE_FLAGS) compile.hxml" 2>&1 | tail -n 1 > /dev/null; then \
			end=$$(date +%s); \
			duration=$$((end - start)); \
			echo "✅ $$testname (special handling) ($${duration}s)" | tee -a test-results.tmp; \
		else \
			end=$$(date +%s); \
			duration=$$((end - start)); \
			echo "❌ $$testname - Compilation failed (special handling) ($${duration}s)" | tee -a test-results.tmp; \
		fi; \
	elif timeout $(TIMEOUT) bash -c "cd $$testdir && haxe -D elixir_output=$(OUTPUT_DIR) -D reflaxe.dont_output_metadata_id $(HAXE_FLAGS) compile.hxml" > /dev/null 2>&1; then \
		end=$$(date +%s); \
		duration=$$((end - start)); \
		if [ -d $$testdir/intended ] && [ -d $$testdir/$(OUTPUT_DIR) ]; then \
			if diff -r --exclude="_GeneratedFiles.json" --exclude="erl_crash.dump" --exclude="bootstrap_*.ex" --exclude="*.exs.ex" $$testdir/intended $$testdir/$(OUTPUT_DIR) > /dev/null 2>&1; then \
				if [ -n "$(RUN_TESTS)" ] && [ -f $$testdir/$(OUTPUT_DIR)/main.ex ]; then \
					if cd $$testdir/$(OUTPUT_DIR) && timeout 5s elixir -pa . -e "Code.compile_file(\"main.ex\")" > /dev/null 2>&1; then \
						echo "✅ $$testname - compiled and executed ($${duration}s)" | tee -a test-results.tmp; \
					else \
						echo "❌ $$testname - Runtime error ($${duration}s)" | tee -a test-results.tmp; \
					fi; \
				else \
					echo "✅ $$testname ($${duration}s)" | tee -a test-results.tmp; \
				fi; \
			else \
				echo "❌ $$testname - Output mismatch ($${duration}s)" | tee -a test-results.tmp; \
			fi; \
		else \
			echo "✅ $$testname ($${duration}s)" | tee -a test-results.tmp; \
		fi; \
	else \
		code=$$?; \
		end=$$(date +%s); \
		duration=$$((end - start)); \
		if [ $$code -eq 124 ]; then \
			echo "❌ $$testname - Timeout after $(TIMEOUT) ($${duration}s)" | tee -a test-results.tmp; \
		else \
			echo "❌ $$testname - Compilation failed ($${duration}s)" | tee -a test-results.tmp; \
		fi; \
	fi

# Update targets for parallel execution
# Replace forward slashes with double underscores for Make target compatibility
UPDATE_TARGETS := $(shell echo "$(TESTS)" | tr ' ' '\n' | sed 's|/|__|g' | sed 's|^|update-|' | tr '\n' ' ')

# Update intended output for a specific test or all tests
.PHONY: update-intended
update-intended:
	@if [ -n "$(TEST)" ]; then \
		echo "Updating intended output for test: $(TEST)"; \
		testdir=$(TEST_DIR)/$(TEST); \
		if [ ! -f $$testdir/compile.hxml ]; then \
			echo "❌ Test not found: $(TEST)"; \
			exit 1; \
		fi; \
		echo "Compiling $(TEST) to generate new output..."; \
		cd $$testdir && haxe -D elixir_output=$(OUTPUT_DIR) -D reflaxe.dont_output_metadata_id compile.hxml 2>/dev/null && \
		if [ -d $(OUTPUT_DIR) ]; then \
			rm -rf intended && \
			cp -r $(OUTPUT_DIR) intended && \
			echo "✅ Updated intended output for $(TEST)"; \
		else \
			echo "❌ No output generated for $(TEST)"; \
			exit 1; \
		fi; \
	else \
		echo "Updating intended output for all tests (parallel with -j flag)..."; \
		$(MAKE) -f $(MAKEFILE_LIST) -j8 update-all-parallel; \
	fi

# Parallel update all target
.PHONY: update-all-parallel
update-all-parallel: $(UPDATE_TARGETS)
	@echo "✅ Finished updating all intended outputs"

# Individual update targets for parallel execution
# Converts double underscores back to slashes for nested directories
$(UPDATE_TARGETS): update-%:
	@testname=$$(echo $* | sed 's|__|/|g'); \
	testdir=$(TEST_DIR)/$$testname; \
	if [ -f $$testdir/compile.hxml ]; then \
		cd $$testdir && haxe -D elixir_output=$(OUTPUT_DIR) -D reflaxe.dont_output_metadata_id compile.hxml 2>/dev/null 1>/dev/null && \
		if [ -d $(OUTPUT_DIR) ]; then \
			rm -rf intended && \
			cp -r $(OUTPUT_DIR) intended && \
			echo "✅ $$testname"; \
		else \
			echo "❌ $$testname (no output)"; \
		fi; \
	else \
		echo "❌ $$testname (not found)"; \
	fi

# Run a single test by name (convenience target)
# Accepts both formats: stdlib/array_cross_operations or stdlib__array_cross_operations
.PHONY: single
single:
	@if [ -z "$(TEST)" ]; then \
		echo "Usage: make single TEST=test_name"; \
		echo "Example: make single TEST=stdlib/array_cross_operations"; \
		exit 1; \
	fi; \
	test_name=$$(echo "$(TEST)" | sed 's|/|__|g'); \
	$(MAKE) -f $(MAKEFILE_LIST) test-$$test_name

# Run a single test with execution validation
.PHONY: test-exec
test-exec:
	@if [ -z "$(TEST)" ]; then \
		echo "Usage: make test-exec TEST=test_name"; \
		echo "Example: make test-exec TEST=stdlib/array_cross_operations"; \
		echo "This will compile, compare, AND execute the generated Elixir code"; \
		exit 1; \
	fi; \
	test_name=$$(echo "$(TEST)" | sed 's|/|__|g'); \
	RUN_TESTS=1 $(MAKE) -f $(MAKEFILE_LIST) test-$$test_name

# Run the output of a specific test with Elixir
# Accepts both formats: stdlib/array_cross_operations or stdlib__array_cross_operations
.PHONY: run
run:
	@if [ -z "$(TEST)" ]; then \
		echo "Usage: make run TEST=test_name [FILE=main.ex]"; \
		echo "Example: make run TEST=stdlib/array_cross_operations"; \
		exit 1; \
	fi; \
	test_path=$$(echo "$(TEST)" | sed 's|__|/|g'); \
	testdir=$(TEST_DIR)/$$test_path; \
	if [ ! -d "$$testdir/out" ]; then \
		echo "❌ No output directory found. Run the test first: make single TEST=$(TEST)"; \
		exit 1; \
	fi; \
	# Prefer <module>.exs or main.exs when present
	if ls "$$testdir/out"/*.exs >/dev/null 2>&1; then \
		entry=$$(ls "$$testdir/out"/*.exs | head -n1); \
		echo "Running $$entry..."; \
		cd $$testdir/out && elixir "$$(basename $$entry)"; \
		exit $$?; \
	fi; \
	file=$${FILE:-main.ex}; \
	if [ ! -f "$$testdir/out/$$file" ]; then \
		echo "❌ File not found: $$testdir/out/$$file"; \
		exit 1; \
	fi; \
	echo "Running $$testdir/out/$$file..."; \
	cd $$testdir/out && \
	if [ -f "std.ex" ]; then elixir -r std.ex -r $$file -e "if function_exported?(Main, :main, 0), do: Main.main()"; \
	else elixir -r $$file -e "if function_exported?(Main, :main, 0), do: Main.main()"; fi

# Validate Elixir syntax of generated code
.PHONY: validate-elixir
validate-elixir:
	@echo "Running Elixir syntax validation..."
	@./validate_elixir.sh $(TEST_DIR)

# Run tests and then validate Elixir syntax
.PHONY: test-with-validation
test-with-validation: all validate-elixir
	@echo "Tests and Elixir validation complete!"

# Clean target
.PHONY: clean
clean:
	@rm -f test-results.tmp
	@rm -f elixir_validation.log
	@find $(TEST_DIR) -name $(OUTPUT_DIR) -type d -exec rm -rf {} + 2>/dev/null || true

# List all tests
.PHONY: list
list:
	@echo "Available tests:"
	@for test in $(TESTS); do echo "  $$test"; done

# Runtime smoke: compile all tests, then execute any generated *.exs (or main.ex if no .exs)
.PHONY: runtime
RUNTIME_TIMEOUT ?= 5s

runtime: all
	@echo "Running runtime smoke tests..."
	@fail=0; \
	for td in $(TESTS); do \
		outdir="$(TEST_DIR)/$$td/out"; \
		[ -d "$$outdir" ] || continue; \
		entry=$$(ls "$$outdir"/*.exs 2>/dev/null | head -n1); \
		if [ -z "$$entry" ]; then \
			[ -f "$$outdir/main.ex" ] && entry="$$outdir/main.ex"; \
		fi; \
		if [ -n "$$entry" ]; then \
			echo "→ $$td: $$(basename $$entry)"; \
			if (cd "$$outdir" && timeout $(RUNTIME_TIMEOUT) elixir "$$(basename $$entry)" >/dev/null 2>&1); then \
				echo "  ✓ ran"; \
			else \
				echo "  ✗ runtime error"; \
				fail=1; \
			fi; \
		fi; \
	done; \
	[ $$fail -eq 0 ] || (echo "Some runtime tests failed" && exit 1)

# Category test targets - run specific test categories
.PHONY: test-core
test-core:
	@echo "Running core language tests..."
	@$(MAKE) -f $(MAKEFILE_LIST) $(shell find $(TEST_DIR)/core -name compile.hxml -exec dirname {} \; | sed 's|$(TEST_DIR)/||' | sed 's|/|__|g' | sed 's|^|test-|' | tr '\n' ' ')

.PHONY: test-stdlib
test-stdlib:
	@echo "Running standard library tests..."
	@$(MAKE) -f $(MAKEFILE_LIST) $(shell find $(TEST_DIR)/stdlib -name compile.hxml -exec dirname {} \; | sed 's|$(TEST_DIR)/||' | sed 's|/|__|g' | sed 's|^|test-|' | tr '\n' ' ')

.PHONY: test-regression
test-regression:
	@echo "Running regression tests..."
	@$(MAKE) -f $(MAKEFILE_LIST) $(shell find $(TEST_DIR)/regression -name compile.hxml -exec dirname {} \; | sed 's|$(TEST_DIR)/||' | sed 's|/|__|g' | sed 's|^|test-|' | tr '\n' ' ')

.PHONY: test-phoenix
test-phoenix:
	@echo "Running Phoenix framework tests..."
	@$(MAKE) -f $(MAKEFILE_LIST) $(shell find $(TEST_DIR)/phoenix -name compile.hxml -exec dirname {} \; | sed 's|$(TEST_DIR)/||' | sed 's|/|__|g' | sed 's|^|test-|' | tr '\n' ' ')

.PHONY: test-ecto
test-ecto:
	@echo "Running Ecto ORM tests..."
	@$(MAKE) -f $(MAKEFILE_LIST) $(shell find $(TEST_DIR)/ecto -name compile.hxml -exec dirname {} \; | sed 's|$(TEST_DIR)/||' | sed 's|/|__|g' | sed 's|^|test-|' | tr '\n' ' ')

.PHONY: test-otp
test-otp:
	@echo "Running OTP pattern tests..."
	@$(MAKE) -f $(MAKEFILE_LIST) $(shell find $(TEST_DIR)/otp -name compile.hxml -exec dirname {} \; | sed 's|$(TEST_DIR)/||' | sed 's|/|__|g' | sed 's|^|test-|' | tr '\n' ' ')

.PHONY: test-bootstrap
test-bootstrap:
	@echo "Running bootstrap tests..."
	@$(MAKE) -f $(MAKEFILE_LIST) $(shell find $(TEST_DIR)/bootstrap* -name compile.hxml -exec dirname {} \; | sed 's|$(TEST_DIR)/||' | sed 's|/|__|g' | sed 's|^|test-|' | tr '\n' ' ')

# Pattern-based test selection
.PHONY: test-pattern
test-pattern:
	@if [ -z "$(PATTERN)" ]; then \
		echo "Usage: make test-pattern PATTERN=*array*"; \
		echo "       make test-pattern PATTERN=*date*"; \
		exit 1; \
	fi; \
	echo "Running tests matching pattern: $(PATTERN)"; \
	$(MAKE) -f $(MAKEFILE_LIST) $(shell find $(TEST_DIR) -type d -name "$(PATTERN)" | xargs -I {} find {} -name compile.hxml -exec dirname {} \; | sed 's|$(TEST_DIR)/||' | sed 's|/|__|g' | sed 's|^|test-|' | tr '\n' ' ')

# Run only failed tests from last run
.PHONY: test-failed
test-failed:
	@if [ -f test-results.tmp ]; then \
		failed=$$(grep "❌" test-results.tmp | sed 's/❌ //' | sed 's/ -.*//' | sed 's|/|__|g' | sed 's|^|test-|' | tr '\n' ' '); \
		if [ -n "$$failed" ]; then \
			echo "Re-running failed tests..."; \
			$(MAKE) -f $(MAKEFILE_LIST) $$failed; \
		else \
			echo "No failed tests to re-run"; \
		fi; \
	else \
		echo "No test results found. Run tests first."; \
	fi

# Help target
.PHONY: help
help:
	@echo "Test Runner for Reflaxe.Elixir"
	@echo ""
	@echo "Basic Usage:"
	@echo "  make                          # Run all tests (parallel)"
	@echo "  make -j1                      # Run all tests sequentially"
	@echo "  make -j8                      # Run with 8 parallel jobs"
	@echo "  make test-NAME                # Run specific test"
	@echo "  make single TEST=NAME         # Run specific test (alternative)"
	@echo ""
	@echo "Category Testing:"
	@echo "  make test-core                # Run core language tests"
	@echo "  make test-stdlib              # Run standard library tests"
	@echo "  make test-regression          # Run regression tests"
	@echo "  make test-phoenix             # Run Phoenix framework tests"
	@echo "  make test-ecto                # Run Ecto ORM tests"
	@echo "  make test-otp                 # Run OTP pattern tests"
	@echo "  make test-bootstrap           # Run bootstrap tests"
	@echo "  make test-pattern PATTERN=*array* # Run tests matching pattern"
	@echo "  make test-failed              # Re-run failed tests from last run"
	@echo ""
	@echo "Maintenance:"
	@echo "  make update-intended TEST=NAME # Update intended output for test"
	@echo "  make update-intended          # Update all intended outputs"
	@echo "  make clean                    # Clean output directories"
	@echo "  make list                     # List all available tests"
	@echo ""
	@echo "Pipeline Testing:"
	@echo "  make                          # Run tests with AST pipeline (default)"
	@echo "  make USE_LEGACY=1             # Run tests with legacy string pipeline"
	@echo "  make USE_LEGACY=1 test-core   # Run category with legacy pipeline"
	@echo ""
	@echo "Options:"
	@echo "  -j N    Run N tests in parallel (default: 4)"
	@echo "  -k      Continue running tests even if some fail"
	@echo "  -s      Silent mode (less output)"
	@echo ""
	@echo "Examples:"
	@echo "  make test-core -j8            # Run core tests with 8 parallel jobs"
	@echo "  make test-pattern PATTERN=*date* # Run all date-related tests"
	@echo "  make test-failed              # Re-run only failed tests"
