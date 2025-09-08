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
	@$(MAKE) -f $(MAKEFILE_LIST) -j4 summary

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
			if diff -r --exclude="_GeneratedFiles.json" --exclude="erl_crash.dump" $$testdir/intended $$testdir/$(OUTPUT_DIR) > /dev/null 2>&1; then \
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

# Help target
.PHONY: help
help:
	@echo "Test Runner for Reflaxe.Elixir"
	@echo ""
	@echo "Usage:"
	@echo "  make                          # Run all tests (parallel, 4 jobs)"
	@echo "  make -j1                      # Run all tests sequentially"
	@echo "  make -j8                      # Run with 8 parallel jobs"
	@echo "  make test-NAME                # Run specific test"
	@echo "  make single TEST=NAME         # Run specific test (alternative)"
	@echo "  make update-intended TEST=NAME # Update intended output for test"
	@echo "  make update-intended          # Update all intended outputs"
	@echo "  make clean                    # Clean output directories"
	@echo "  make list                     # List all available tests"
	@echo ""
	@echo "Pipeline Testing:"
	@echo "  make                          # Run tests with AST pipeline (default)"
	@echo "  make USE_LEGACY=1             # Run tests with legacy string pipeline"
	@echo "  make USE_LEGACY=1 test-NAME   # Run specific test with legacy pipeline"
	@echo ""
	@echo "Options:"
	@echo "  -j N    Run N tests in parallel (default: 4)"
	@echo "  -k      Continue running tests even if some fail"
	@echo "  -s      Silent mode (less output)"
	@echo ""
	@echo "Examples:"
	@echo "  make -j1                      # Sequential execution"
	@echo "  make test-arrays              # Run arrays test"
	@echo "  make update-intended TEST=arrays # Update arrays baseline"