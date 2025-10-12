# Enhanced Task Executor for Reflaxe.Elixir

## Purpose
Professional task execution framework designed specifically for **Reflaxe compiler development** with snapshot-first testing, three-layer validation, and compiler-specific quality gates.

## Core Execution Principles

### 0. Memory and Rules Review (CRITICAL FIRST STEP)
**BEFORE ANY TASK EXECUTION**:
1. **Review AGENTS.md**: Always check `/AGENTS.md` for critical development rules
2. **Review Memory Files**: Check `.llm-memory/` directory for relevant context
3. **Apply Context7 Rule**: When user requests code examples, setup/configuration, or library/API documentation, use Context7 tools:
   - Use `resolve-library-id` to find the library
   - Use `get-library-docs` to fetch documentation
4. **Review Project Rules**: Check `.claude/rules/` directory if it exists
5. **Review Task Context**: Understand task requirements fully before execution

### 0.1 Project Context and Documentation References

**CRITICAL: Always reference these resources during task execution:**

1. **Current PRD Location**: 
   - Active PRD: `documentation/plans/staging/[current-prd].md`
   - Check `documentation/plans/staging/README.md` for current active plan
   - Agent instructions: `documentation/plans/AGENT_INSTRUCTIONS.md`

2. **Documentation Index**:
   - Main index: `documentation/DOCUMENTATION_INDEX.md`
   - Quick navigation to find any documentation needed
   - Organized by purpose, audience, and task type

3. **Reference Implementations**:
   - Location: `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/`
   - Contains: Reflaxe examples (CPP, CSharp, GDScript, Go), Phoenix patterns, Haxe source, compiler implementations
   - Use for: Pattern reference, API checking, implementation examples
   - Key folders: `reflaxe.CPP/` (mature reference), `haxe/std/` (standard library), `phoenix_live_view/` (LiveView patterns)

4. **Key Documentation by Task Type**:
   - **Compiler Features**: `documentation/architecture/`, `documentation/reference/ANNOTATIONS.md`
   - **Testing**: `documentation/TESTING_OVERVIEW.md`, `documentation/TESTING_PRINCIPLES.md`
   - **Phoenix/LiveView**: `documentation/phoenix/`, examples in reference folder
   - **Paradigm Issues**: `documentation/paradigms/PARADIGM_BRIDGE.md`, `documentation/guides/DEVELOPER_PATTERNS.md`
   - **Examples**: `documentation/guides/EXAMPLES.md`, `documentation/guides/COOKBOOK.md`

### 1. Task Execution Framework
You are a professional task execution expert following these guidelines:

1. **Task Selection**: When a user specifies a task to execute, use "execute_task" to execute the task
2. **Auto-Discovery**: If no task is specified, use "list_tasks" to find unexecuted tasks and execute them
3. **Completion Summary**: When execution is completed, provide a comprehensive summary
4. **Sequential Processing**: Execute only one task at a time, automatically proceeding to next task
5. **Continuous Mode**: Default behavior - automatically execute all available tasks in sequence
6. **🚨 CRITICAL: Automatic Task Progression Protocol**: IMMEDIATELY after ANY `verify_task` completion, you MUST:
   - **AUTOMATICALLY** execute: `mcp__shrimp-task-manager-global__list_tasks status="pending"`
   - **AUTOMATICALLY** announce: "✅ [task] VERIFIED ✅ | 🔄 Next: [next-task] | ▶️ STARTING NOW..."
   - **IMMEDIATELY** execute: `mcp__shrimp-task-manager-global__execute_task taskId="[next-task-id]"`
   - **NO user permission required - continuous execution is DEFAULT behavior**
7. **🚨 CRITICAL: Full Regression Testing Protocol**: A task is NOT complete unless ALL tests in the project are passing, not just tests related to the new feature

### 2. Reflaxe Compiler Testing Strategy

We follow the **three-layer testing architecture** proven by mature Reflaxe compilers like CPP, CSharp, and GDScript:

#### **Three-Layer Architecture**
```
Layer 1: Snapshot Tests (70% - Primary Validation)
├── Purpose: Validate Haxe AST→Elixir transformation correctness
├── Method: TestRunner.hx compiles Haxe and compares output with intended files
├── Coverage: All compiler features, annotations, edge cases
└── Command: haxe test/Test.hxml

Layer 2: Mix Integration Tests (25% - Runtime Validation)
├── Purpose: Validate generated Elixir actually compiles and runs in BEAM VM
├── Method: ExUnit tests that compile and execute generated code
├── Coverage: Build system, runtime behavior, Phoenix integration
└── Command: MIX_ENV=test mix test

Layer 3: Example Tests (5% - User Workflow Validation)  
├── Purpose: Real-world usage validation and documentation accuracy
├── Method: Complete example compilation and execution
├── Coverage: Documentation examples, user workflows, complex scenarios
└── Command: Manual verification of examples/ directory
```

#### **Why This Architecture Works for Compilers**
- **No Unit Testing**: Compiler exists only during compilation (macro-time), not at runtime
- **Integration Focus**: Tests entire compilation pipeline, not individual functions
- **Real Output Validation**: Compares actual generated code with expected output
- **No Mocking**: Uses real Haxe compiler and real AST transformation
- **Proven by Reference**: Based on successful Reflaxe.CPP, CSharp, GDScript implementations

#### **Snapshot Testing (Primary Validation)**
```
test/tests/[feature-name]/
├── Main.hx          # Haxe input demonstrating feature
├── compile.hxml     # Compilation configuration  
├── intended/        # Expected Elixir output
└── out/            # Actual output (comparison target)
```

#### **How Snapshot Testing Works**
1. **Write Haxe source** that demonstrates compiler feature
2. **Compile via TestRunner.hx** (invokes real compiler pipeline)
3. **Compare generated .ex files** with intended output
4. **Pass/Fail** based on exact output match
5. **Update intended files** with `haxe test/Test.hxml update-intended` when changes are correct

#### **Running the Test Suite**
```bash
npm test                    # All layers: Snapshot + Mix + Examples
npm run test:haxe          # Layer 1: Snapshot tests only (primary)
npm run test:mix           # Layer 2: Mix tests only (runtime validation)
haxe test/Test.hxml test=name  # Run specific snapshot test
```

### 3. Snapshot-First Development Methodology

#### **Development Cycle for Compiler Features**
```
1. SNAPSHOT: Create test/tests/feature_name/Main.hx with expected behavior
2. INTENDED: Generate expected Elixir output in intended/ directory
3. IMPLEMENT: Build compiler feature to generate expected output  
4. VALIDATE: Ensure TestRunner.hx shows passing snapshot comparison
5. INTEGRATE: Verify Mix tests pass with generated code
6. VERIFY: Confirm all acceptance criteria are met
```

#### **Example: Adding New Annotation Support**
```haxe
// 1. Create test/tests/my_annotation/Main.hx
@:myAnnotation
class TestClass {
    public function new() {}
    
    @:myAnnotation
    public function testMethod(): String {
        return "test";
    }
}

// 2. Create intended/TestClass.ex with expected output
// 3. Implement annotation handling in ClassCompiler.hx
// 4. Run: haxe test/Test.hxml test=my_annotation
// 5. Verify output matches intended
// 6. Run: npm test (full regression check)
```

### 4. Project Context Integration

#### **Always Reference Project Documentation**
- **Primary PRD**: Check `documentation/plans/staging/` for current development plan
- **Documentation Index**: Use `documentation/DOCUMENTATION_INDEX.md` to find relevant docs
- **Architecture Details**: See `documentation/architecture/ARCHITECTURE.md`
- **Testing Strategy**: See `documentation/TESTING_OVERVIEW.md`
- **Performance Targets**: Check current PRD for specific requirements (<15ms compilation, <300ms watch mode)
- **Success Metrics**: Defined in active PRD and `documentation/reference/FEATURES.md`

#### **Context-Aware Implementation**
Before implementing any task:
1. **Review PRD**: Check active plan in `documentation/plans/staging/`
2. **Find Documentation**: Use `documentation/DOCUMENTATION_INDEX.md` for navigation
3. **Check References**: Look for patterns in `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/`
4. **Understand Dependencies**: How this task fits into the overall architecture
5. **Identify Interfaces**: What other components will interact with this code
6. **Performance Considerations**: Apply timing requirements from PRD

### 5. Enhanced Task Execution Workflow

#### **Pre-Execution Analysis**
```
1. Parse task requirements and acceptance criteria
2. Check current PRD in `documentation/plans/staging/` for context
3. Reference `documentation/DOCUMENTATION_INDEX.md` for relevant guides
4. Identify test strategy from `documentation/TESTING_OVERVIEW.md`
5. Look for patterns in `/Users/fullofcaffeine/workspace/code/haxe.elixir.reference/`
6. Determine if snapshot-first approach is appropriate
7. Plan implementation phases based on project conventions
```

#### **Snapshot-First Implementation Cycle**
```
1. SNAPSHOT: Create snapshot test with expected Elixir output
2. IMPLEMENT: Build compiler feature to generate expected output  
3. VALIDATE: Ensure snapshot tests pass with TestRunner.hx
4. INTEGRATE: Confirm Mix tests pass with generated code
5. OPTIMIZE: Refactor compiler while keeping tests green
6. VERIFY: Ensure all acceptance criteria are met
```

#### **Quality Gates (Compiler-Focused)**
Before marking any task complete:
- [ ] **Snapshot tests validate compiler output correctness**
- [ ] **Mix tests confirm generated Elixir actually works in BEAM VM**
- [ ] **Generated code follows Elixir idioms and conventions**
- [ ] **No regressions in existing snapshot tests**  
- [ ] **Performance benchmarks satisfied**
- [ ] **🚨 MANDATORY: ALL TESTS IN PROJECT PASS** - Run complete test suite:
  - **Snapshot Tests**: `npx haxe test/Test.hxml` (compiler output validation)
  - **Mix Tests**: `MIX_ENV=test mix test --no-deps-check` (runtime validation)
  - **Full Suite**: `npm test` (all layers combined)
- [ ] **🚨 NO REGRESSIONS ALLOWED** - Every test that was passing before must still pass
- [ ] **🚨 ZERO TOLERANCE FOR BROKEN TESTS** - If any test fails, task is NOT complete
- [ ] **📖 DOCUMENTATION COMPLETE** - Documentation is part of task completion:
  - **User Documentation Updated**: Feature guides, API references, examples
  - **Task History Documented**: TASK_HISTORY.md updated with session summary
  - **Technical Documentation**: Architecture changes and decisions captured
- [ ] **🧠 AUTOMATIC MEMORY UPDATE** - Implementation details captured in AGENTS.md
- [ ] **📊 PERFORMANCE DATA CAPTURED** - Benchmark results and timing data recorded

### 6. Compiler Testing Implementation Strategy

#### **Snapshot Testing (Primary Validation - 70%)**
```bash
# Create snapshot test for new compiler feature
test/tests/my_feature/
├── Main.hx              # Haxe source demonstrating feature
├── compile.hxml         # Compilation configuration
└── intended/            # Expected Elixir output
    ├── Main.ex          # Generated Elixir module
    └── _GeneratedFiles.json  # Metadata about generated files
```

**Example Snapshot Test:**
```haxe
// test/tests/my_feature/Main.hx
@:myfeature
class TestFeature {
    public function new() {}
    
    public function testMethod(): String {
        return "feature working";
    }
}
```

**Running Snapshot Tests:**
```bash
haxe test/Test.hxml test=my_feature           # Run specific test
haxe test/Test.hxml update-intended           # Update all intended outputs
haxe test/Test.hxml test=my_feature update-intended  # Update specific test
```

#### **Mix Integration Testing (Runtime Validation - 25%)**
```elixir
# test/my_feature_test.exs
defmodule MyFeatureTest do
  use ExUnit.Case
  import TestSupport.ProjectHelpers
  
  test "compiler generates valid Elixir that compiles and runs in BEAM" do
    # Create temporary project with Haxe source
    project_dir = create_temp_project()
    
    # Write Haxe source using new feature
    File.write!(Path.join([project_dir, "src_haxe/Test.hx"]), """
    @:myfeature
    class Test {
      public static function main() {
        trace("Feature working");
      }
    }
    """)
    
    # Compile through Mix.Tasks.Compile.Haxe
    {:ok, compiled} = Mix.Tasks.Compile.Haxe.run([])
    
    # Verify generated Elixir compiles in BEAM VM
    assert File.exists?(Path.join([project_dir, "lib/test.ex"]))
    output = File.read!(Path.join([project_dir, "lib/test.ex"]))
    assert output =~ "defmodule Test do"
    
    # Verify Elixir compiler accepts generated code
    assert {:ok, _} = Code.compile_file("lib/test.ex")
  end
end
```

#### **Example Compilation (Documentation Validation - 5%)**
```bash
# examples/my-feature/
├── README.md            # Usage documentation
├── build.hxml           # Real compilation example  
├── Main.hx             # Complete working example
└── lib/                # Generated Elixir code
```

### 7. Implementation Standards

#### **Code Quality Standards**
- **Follow Reflaxe patterns**: Study reference implementations for proven approaches
- **Maintain compiler architecture**: Use helper classes, proper AST handling
- **Generate idiomatic code**: Elixir output should look hand-written
- **Preserve type safety**: Maintain compile-time guarantees through transformation

#### **Compiler Testing Framework Standards**
- **Snapshot Testing**: Primary validation using TestRunner.hx following Reflaxe patterns
- **Three-Layer Architecture**: Snapshot → Mix → Example testing for comprehensive coverage
- **No Unit Testing**: Compiler components don't exist at runtime, can't be unit tested
- **Integration Focus**: Test complete Haxe→Elixir compilation pipeline
- **Real Compilation**: Use actual Haxe compiler and TypedExpr AST, no mocking

#### **Test Quality Standards**
- **Readable snapshot tests**: Clear Haxe examples that demonstrate features
- **Comprehensive intended output**: Expected Elixir that follows language conventions
- **Descriptive test names**: Feature names that explain compiler behavior
- **Test both happy path and error conditions**: Include invalid syntax tests
- **Real-world patterns**: Tests should reflect actual usage scenarios

#### **Documentation Standards**
- **Update user guides**: Feature documentation for end users
- **JavaDoc comments**: Comprehensive documentation for all public compiler methods
- **Architecture updates**: Document changes to compilation pipeline
- **Reference implementations**: Cross-link to patterns in reference directory

### 8. Performance and Monitoring

#### **Performance Testing Integration**
- **Compilation timing**: Measure and validate <15ms compilation targets from PRD
- **Memory usage**: Monitor AST processing and string generation efficiency
- **Watch mode performance**: Ensure <300ms incremental compilation
- **Benchmark against baselines**: Compare with reference Reflaxe implementations

#### **Monitoring and Observability**
- **Compilation metrics**: Track successful vs failed compilations
- **Error categorization**: Classify and track common compilation errors
- **Performance regression detection**: Alert on timing degradation
- **Feature usage tracking**: Monitor which annotations and features are used

## Quality Assurance Checklist

### Before Task Completion (Compiler-Focused)
- [ ] **Snapshot Tests First**: Haxe→Elixir transformation tested and working
- [ ] **Compilation Verification**: Generated code compiles correctly in BEAM VM
- [ ] **Three-Layer Validation**: Snapshot → Mix → Example tests all pass
- [ ] **Real-World Usage**: Tests demonstrate actual compiler features working
- [ ] **PRD Compliance**: Implementation matches specifications in active PRD
- [ ] **Performance Verified**: Timing requirements met with benchmarks
- [ ] **Quality Gates Passed**: Focus on integration confidence over coverage metrics
- [ ] **🚨 FULL TEST SUITE PASSES**: Run `npm test` and verify all layers pass
- [ ] **🚨 NO REGRESSIONS**: All previously passing tests must still pass
- [ ] **📚 END-USER DOCS UPDATED**: User-facing features documented in guides
- [ ] **🎯 DRY COMPLIANCE**: No duplicate content between AGENTS.md and user docs

### Success Metrics (Compiler-Focused)
- **Compilation Confidence**: Haxe→Elixir transformation thoroughly validated
- **Test Architecture**: Three-layer validation (Snapshot → Mix → Example)
- **Real-World Validation**: Tests demonstrate actual compiler usage patterns
- **Performance**: All compilation timing requirements satisfied
- **Maintainability**: Snapshot tests provide refactoring safety net

## Integration with Shrimp Task Management

### Shrimp MCP Integration Workflow

#### 1. Task Selection and Execution
```bash
# Get available tasks  
mcp__shrimp-task-manager-global__list_tasks status="pending"

# Execute specific task
mcp__shrimp-task-manager-global__execute_task taskId="[task-id]"
```

#### 2. Follow Embedded Implementation Instructions
Every shrimp task contains implementation guidance:
- Use "Implementation Guide" for technical approach
- Follow "Verification Criteria" for completion requirements
- Reference "Related Files" for code locations

#### 3. Snapshot-First Progress Updates
```bash
# Development Phase Update
mcp__shrimp-task-manager-global__update_task \
  taskId="[task-id]" \
  prompt="Snapshot test created: test/tests/feature_name/Main.hx demonstrates expected behavior. Expected output defined in intended/ directory."

# Implementation Phase Update  
mcp__shrimp-task-manager-global__update_task \
  taskId="[task-id]" \
  prompt="Implementation complete: Compiler generates expected output. Snapshot test passes: X/X tests passing."

# Validation Phase Update
mcp__shrimp-task-manager-global__update_task \
  taskId="[task-id]" \
  prompt="Full validation complete: All tests pass (Snapshot + Mix). Performance: Xms compilation time."
```

#### 4. Integrated Test Verification
```bash
# Verify with automatic test execution
mcp__shrimp-task-manager-global__verify_task \
  taskId="[task-id]" \
  score=90 \
  summary="Snapshot-first development complete. All quality gates verified: X snapshot tests, Y Mix tests passing. Performance targets met."
```

#### 5. 🚨 CRITICAL: Automatic Task Progression Protocol

**TRIGGER**: IMMEDIATELY after `mcp__shrimp-task-manager-global__verify_task` completes

**REQUIRED ACTIONS (AUTOMATIC - NO USER PERMISSION):**

```bash
# === EXECUTE THIS SEQUENCE IMMEDIATELY AFTER verify_task ===

# Step 1: IMMEDIATELY check for next available task
mcp__shrimp-task-manager-global__list_tasks status="pending"

# Step 2: If tasks found - AUTOMATICALLY announce progression
"✅ [current-task-name] VERIFIED ✅ | 🔄 Next: [next-task-name] | ▶️ STARTING NOW..."

# Step 3: IMMEDIATELY execute next task (DO NOT ASK PERMISSION)
mcp__shrimp-task-manager-global__execute_task taskId="[next-task-id]"
```

**🚨 THIS HAPPENS AUTOMATICALLY - NOT OPTIONAL**

## Key Commands Reference

- **`list_tasks`**: Get tasks with implementation guidance
- **`execute_task`**: Start task with embedded methodology  
- **`get_task_detail`**: Get complete task with requirements
- **`update_task`**: Report progress during development phases
- **`verify_task`**: Trigger integrated test verification with automatic progression

## Integration Success Criteria

✅ **Proper Shrimp Usage:**
- All task interactions through MCP tools
- Development progress tracked in shrimp system
- Test verification integrated with verify_task
- Task dependencies managed through shrimp
- Feedback communicated back to planning system

✅ **Quality Assurance:**
- Snapshot tests validate all implementations
- Mix tests ensure generated code works in BEAM
- Performance benchmarks meet PRD requirements
- No regressions allowed in task completion
- **🚨 FULL test suite passes before any task marked complete**

✅ **🚨 CRITICAL: Automatic Task Progression:**
- After every task completion, automatically check for next pending tasks
- **AUTOMATICALLY execute next logical task (no user permission needed)**
- Never end session without checking for more work
- Maintain project momentum through **continuous automatic execution**
- Only stop on user interruption, no tasks available, or critical errors

---

This Enhanced Task Executor framework ensures high-quality, snapshot-tested development while maintaining full integration with the shrimp task management system and preserving the proven Reflaxe compiler testing methodology.