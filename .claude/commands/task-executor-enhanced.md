# Enhanced Task Executor Mode

## Purpose
Professional task execution with test-first development, BDD principles, and testing trophy strategy integration.

## Core Execution Principles

### 0. Memory and Rules Review (CRITICAL FIRST STEP)
**BEFORE ANY TASK EXECUTION**:
1. **Review CLAUDE.md**: Always check `/CLAUDE.md` for critical development rules
2. **Review Memory Files**: Check `.llm-memory/` directory for relevant context
3. **Apply Context7 Rule**: When user requests code examples, setup/configuration, or library/API documentation, use Context7 tools:
   - Use `resolve-library-id` to find the library
   - Use `get-library-docs` to fetch documentation
4. **Review Project Rules**: Check `.claude/rules/` directory if it exists
5. **Review Task Context**: Understand task requirements fully before execution

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

### 2. Testing Approach (Following Reference Reflaxe Compilers)

We use **integration-level snapshot testing** exactly like Reflaxe.CPP and Reflaxe.CSharp:

#### **How It Works**
1. **Write Haxe code** that uses compiler features
2. **Compile it** through our Haxe→Elixir compiler  
3. **Compare output** with expected Elixir code
4. **Pass/Fail** based on whether output matches expected

#### **Test Structure**
```
test/tests/[feature-name]/
├── Main.hx          # Haxe input
├── compile.hxml     # How to compile it
├── intended/        # Expected Elixir output
└── out/            # Actual output (git-ignored)
```

#### **Integration-Level Testing**
- Tests the **entire compiler pipeline** (not individual functions)
- Each test compiles **complete Haxe programs** into Elixir
- Verifies **real-world transformations** work correctly
- No mocking, no unit tests - just **real compilation**

#### **Running Tests**
```bash
npm test                    # Run everything
npx haxe test/Test.hxml    # Just snapshot tests
```

#### **Current Coverage: 22 Integration Tests**
Each test represents a complete feature transformation:
- Core language constructs (8 tests)
- Phoenix/Ecto annotations (7 tests)  
- Framework integrations (3 tests)
- Real examples (4 tests)

### 4. Project Context Integration

#### **Always Reference Project Documentation**
- **Primary Source**: `@cafetera-poc.md` contains the complete Product Requirements Document
- **Architecture Details**: Memory-first design, Taskmaster integration, progressive intelligence
- **Performance Targets**: Specific timing requirements (e.g., <15ms node creation, <100ms sync)
- **Success Metrics**: Coverage targets, compatibility requirements, user experience goals

#### **Context-Aware Implementation**
Before implementing any task:
1. **Review PRD**: Check `@cafetera-poc.md` for relevant specifications
2. **Understand Dependencies**: How this task fits into the overall architecture
3. **Identify Interfaces**: What other components will interact with this code
4. **Performance Considerations**: Apply relevant timing and scalability requirements

### 5. Enhanced Task Execution Workflow

#### **Pre-Execution Analysis**
```
1. Parse task requirements and acceptance criteria
2. Review @cafetera-poc.md for context and specifications
3. Identify test strategy (Unit/Integration/E2E mix)
4. Determine if test-first approach is appropriate
5. Plan implementation phases
```

#### **Test-First Implementation Cycle**
```
1. Red: Write failing tests that define expected behavior
2. Green: Implement minimum code to pass tests
3. Refactor: Improve code structure while keeping tests green
4. Integrate: Test integration points with other components
5. Verify: Confirm all acceptance criteria are met
```

#### **Quality Gates (Trophy-Aligned)**
Before marking any task complete:
- [ ] Integration tests demonstrate component interactions work properly
- [ ] Unit tests cover business logic edge cases  
- [ ] Static analysis clean (Credo, Dialyzer, Sobelow)
- [ ] E2E tests validate critical workflows (minimal but essential)
- [ ] Performance benchmarks satisfied
- [ ] "Resembles the way software is used" principle satisfied
- [ ] **🚨 MANDATORY: ALL TESTS IN PROJECT PASS** - Run dual-ecosystem test suite:
  - **Snapshot Tests**: `npx haxe test/Test.hxml` (snapshot tests comparing compiler output)
  - **Mix Tests**: `MIX_ENV=test mix test --no-deps-check` (Elixir runtime validation)
  - **NPM Test**: `npm test` (runs both snapshot tests and Mix tests)
- [ ] **🚨 NO REGRESSIONS ALLOWED** - Every test that was passing before your changes must still pass
- [ ] **🚨 ZERO TOLERANCE FOR BROKEN TESTS** - If any test fails, the task is NOT complete regardless of feature implementation
- [ ] **📖 DOCUMENTATION COMPLETE** - Documentation is NOT optional, it's part of task completion:
  - **User Documentation Updated**: Feature guides, API references, examples added/updated
  - **Task History Documented**: TASK_HISTORY.md updated with comprehensive session summary
  - **Technical Documentation**: Architecture changes, patterns, and decisions captured
  - **Migration/Upgrade Guides**: Breaking changes documented with migration paths
- [ ] **🧠 AUTOMATIC MEMORY UPDATE** - Capture implementation details, performance metrics, test results, technical decisions, and integration points in CLAUDE.md
- [ ] **📊 PERFORMANCE DATA CAPTURED** - Record actual benchmark results, timing data, memory usage statistics
- [ ] **🐛 ERROR SOLUTIONS DOCUMENTED** - Record exact error messages and their solutions for future reference
- [ ] **📚 USER DOCUMENTATION ASSESSMENT** - Evaluate if task creates user-facing functionality requiring documentation updates
- [ ] **🎯 DRY PRINCIPLE APPLIED** - Ensure CLAUDE.md references user docs instead of duplicating content
- [ ] **🧹 DOCUMENTATION CLEANUP** - Remove outdated docs, consolidate duplicates, maintain structure

### 6. Testing Strategy by Component Type (Trophy-Focused)

#### **Primary Focus: Integration Tests (How Components Work Together)**
```elixir
# Integration-first testing - main focus of Testing Trophy
describe "Multi-Component Workflow Integration" do
  context "when user triggers complete business process" do
    test "should coordinate multiple components properly" do
      # Given: User initiates a complex workflow
      input = build_workflow_input()
      
      # When: Complete workflow executes across components
      {:ok, result} = BusinessWorkflow.execute(input)
      
      # Then: All components work together properly
      assert result.status == :completed
      assert result.data_stored?
      assert result.notifications_sent?
    end
  end
end

# Database Integration Testing (main value)
describe "Database Integration" do
  context "when complex data operations occur" do
    test "should handle multi-table operations correctly" do
      # Test database operations with real data and transactions
      data = create_test_data()
      result = DataService.process_complex_operation(data)
      assert result.success?
      assert database_state_consistent?()
    end
  end
end
```

#### **Supporting: Unit Tests (30% - Critical Components Only)**
```elixir
# Unit tests for critical components that need isolated testing
describe "Business Rule Engine" do
  test "should apply complex business rules correctly" do
    input = build_complex_input()
    result = BusinessRules.apply_rules(input)
    assert result.status == :approved
    assert result.score > 0.8
  end
  
  test "should handle edge cases in rule application" do
    assert BusinessRules.apply_rules(nil) == {:error, :invalid_input}
    assert BusinessRules.apply_rules(%{}) == {:ok, :default_result}
  end
end

describe "Scoring Algorithm" do
  test "should calculate scores with proper weighting" do
    data = %{relevance: 0.8, recency: 0.6, importance: 0.9}
    score = ScoringEngine.calculate_weighted_score(data)
    assert score >= 0.7 and score <= 1.0
  end
end

describe "Data Transformation" do
  test "should transform data formats correctly" do
    input = build_source_format()
    output = DataTransformer.transform(input, :target_format)
    assert output.format == :target_format
    assert output.data == expected_transformed_data()
  end
end
```

#### **Foundation: Static Analysis (Infrastructure - Runs Automatically)**
- Linting catches style issues and code smells
- Type checking catches type errors and inconsistencies
- Security scanning catches vulnerabilities
- Pre-commit hooks enforce standards
- *Configured once, provides continuous value without testing effort*

#### **Minimal: E2E Tests**
```elixir
# Only critical end-to-end workflows
test "complete user workflow: create → process → retrieve" do
  # Full system test - expensive but high confidence
  user_input = create_realistic_input()
  result = System.complete_workflow(user_input)
  assert result.success?
  assert result.meets_business_requirements?
end
```

### 7. Implementation Standards

#### **Code Quality Standards**
- Follow existing project conventions and patterns
- Maintain consistency with established architecture
- Use proper error handling and edge case management
- Implement logging and monitoring hooks where appropriate

#### **Testing Framework Standards (Snapshot Testing)**
- **Haxe Compiler Tests**: Use **snapshot testing** pattern following Reflaxe.CPP/CSharp approach
- **Test Structure**: Custom `TestRunner.hx` that compiles Haxe and compares with "intended" output files
- **No Testing Framework**: Pure Haxe implementation without utest/tink_unittest dependencies
- **Snapshot Pattern**: Each test in `test/tests/[test-name]/` with `Main.hx`, `compile.hxml`, `intended/` output
- **Compilation Verification**: Tests verify that Haxe→Elixir compilation produces expected output

#### **Test Quality Standards**
- Tests should be readable and maintainable
- Use descriptive test names that explain behavior
- Arrange-Act-Assert (AAA) pattern for clarity
- Mock external dependencies appropriately
- Test both happy path and error conditions

#### **Documentation Standards**
- Update module documentation for public interfaces
- Include usage examples in doctests
- Document complex business logic decisions
- Reference PRD specifications where applicable

#### **End-User Documentation Requirements (CRITICAL)**
After completing each task, **evaluate documentation needs**:

**📚 CLAUDE.md vs User Documentation Distinction:**
- **CLAUDE.md**: AI/Agent development context, implementation details, technical decisions
- **User Documentation**: End-user guides, setup instructions, feature usage, examples

**🎯 DRY Principle Enforcement:**
- **Single Source of Truth**: Each piece of information documented in ONE place only
- **Cross-References**: Use clear references between CLAUDE.md and user docs
- **No Duplication**: CLAUDE.md references user docs, doesn't repeat content

**📖 Post-Task Documentation Protocol:**
1. **Assess User Impact**: Does this task create user-facing functionality?
2. **Update User Docs**: If YES, update appropriate user documentation files:
   - `documentation/FEATURES.md` - Production readiness status
   - `documentation/EXAMPLES.md` - Working example walkthroughs
   - `documentation/ANNOTATIONS.md` - Annotation usage reference
   - `documentation/GETTING_STARTED.md` - Setup and first steps
3. **Reference in CLAUDE.md**: Point to user docs instead of duplicating content
4. **Maintain Separation**: Keep AI context separate from user guidance

**🚨 MANDATORY: End-User Documentation Quality Gates**
- [ ] **User-Facing Features**: All new features documented in user guides
- [ ] **DRY Compliance**: No duplicate information between CLAUDE.md and user docs
- [ ] **Clear References**: CLAUDE.md properly references user documentation
- [ ] **Comprehensive Coverage**: Setup, usage, examples, and troubleshooting documented
- [ ] **Consistent Updates**: User docs updated immediately after feature completion

### 8. 📖 Documentation as Core Task Component

#### **Documentation is NOT Optional - It's Part of Task Definition**

Every task has THREE mandatory components:
1. **Implementation** - The code/feature being built
2. **Testing** - Verification that it works correctly  
3. **Documentation** - Making it usable and maintainable

**A task is NOT complete without all three components.**

#### **Documentation Workflow During Task Execution**

```markdown
1. START OF TASK:
   - Review existing documentation to understand context
   - Identify documentation that will need updates
   - Plan documentation structure alongside implementation

2. DURING IMPLEMENTATION:
   - Document decisions and trade-offs as they're made
   - Capture error messages and solutions immediately
   - Update examples and code snippets in real-time

3. AFTER IMPLEMENTATION:
   - Update user-facing documentation (guides, examples, API refs)
   - Document in TASK_HISTORY.md with comprehensive summary
   - Clean up outdated or conflicting documentation
   - Ensure all references and cross-links are valid
```

#### **Documentation Quality Standards**

**User Documentation Requirements:**
- **Feature Documentation**: Every new feature MUST have user documentation
- **Example Code**: Working examples that users can copy and adapt
- **API Reference**: Complete function signatures, parameters, return values
- **Migration Guides**: Breaking changes require migration documentation
- **Troubleshooting**: Common errors and their solutions

**Technical Documentation Requirements:**
- **Architecture Updates**: System design changes documented
- **Pattern Documentation**: New patterns with usage examples
- **Performance Notes**: Benchmarks, optimization opportunities
- **Integration Points**: How components connect and communicate
- **Decision Rationale**: Why specific approaches were chosen

#### **Documentation File Organization**

```
documentation/
├── USER GUIDES (End-User Focused)
│   ├── GETTING_STARTED.md     # Setup and first steps
│   ├── FEATURES.md            # Feature list and status
│   ├── EXAMPLES.md            # Working code examples
│   ├── ANNOTATIONS.md         # Annotation reference
│   └── MIX_TASK_GENERATORS.md # Generator documentation
│
├── TECHNICAL DOCS (Developer Focused)
│   ├── ARCHITECTURE.md        # System design
│   ├── TESTING.md            # Testing approach
│   ├── DEVELOPMENT_TOOLS.md  # Dev environment
│   └── TROUBLESHOOTING.md    # Problem solutions
│
└── HISTORY (Progress Tracking)
    ├── TASK_HISTORY.md        # Completed tasks log
    └── CHANGELOG.md          # Version changes
```

#### **Documentation During Task Verification**

```bash
# Task verification MUST include documentation check
mcp__shrimp-task-manager-global__verify_task \
  taskId="[task-id]" \
  score=95 \
  summary="✅ Implementation complete. ✅ All tests passing (30/30). 
           📖 Documentation updated: 
           - Created MIX_TASK_GENERATORS.md with comprehensive guide
           - Updated TASK_HISTORY.md with session summary  
           - Added examples to EXAMPLES.md
           - Cleaned up outdated references in 3 files"
```

#### **Documentation Cleanup Protocol**

After completing each task:
1. **Remove Outdated Content**: Delete obsolete documentation
2. **Consolidate Duplicates**: Merge duplicate information
3. **Fix Broken Links**: Update all cross-references
4. **Verify Examples**: Ensure all code examples still work
5. **Update TOCs**: Refresh tables of contents

#### **Documentation Success Metrics**

✅ **Complete Coverage**: Every feature has user documentation
✅ **Working Examples**: All code samples execute successfully
✅ **No Dead Links**: All cross-references are valid
✅ **Current Information**: No outdated or conflicting docs
✅ **Clear Organization**: Logical structure, easy navigation
✅ **Search-Friendly**: Proper headings, keywords, indexing

### 9. Performance and Monitoring

#### **Performance Testing Integration**
- Include performance tests for critical paths
- Verify timing requirements from PRD specifications
- Monitor resource usage and optimization opportunities
- Benchmark against established baselines

#### **Monitoring and Observability**
- Add appropriate logging for debugging
- Include metrics collection for performance monitoring
- Implement health checks for critical components
- Plan for error tracking and alerting

## Usage Examples

### Example 1: Test-First Data Model Implementation
```bash
/task-executor-enhanced --test-first --component=data-model
# 1. Analyzes requirements from PRD
# 2. Creates comprehensive test suite following BDD
# 3. Implements minimum viable code
# 4. Refactors for quality
# 5. Verifies all acceptance criteria
```

### Example 2: Integration Component with Contract Testing
```bash
/task-executor-enhanced --strategy=integration --contracts=true
# 1. Reviews integration specifications in PRD
# 2. Creates contract tests for external interfaces
# 3. Implements integration layer
# 4. Validates compatibility requirements
# 5. Performance tests critical paths
```

### Example 3: Continuous Execution with Testing Trophy
```bash
/task-executor-enhanced --continuous --trophy-strategy
# 1. Executes all pending tasks sequentially
# 2. Applies appropriate test mix for each component
# 3. Maintains quality gates throughout
# 4. Provides comprehensive execution summary
```

## Quality Assurance Checklist

### Before Task Completion (Trophy-Aligned)
- [ ] **Integration Tests First**: Component interactions tested and working
- [ ] **BDD Perspective**: Tests written from consumer viewpoint  
- [ ] **Trophy Strategy**: Integration-heavy approach (Integration > Unit > Static > E2E)
- [ ] **"Resembles Usage" Principle**: Tests match how software is actually used
- [ ] **PRD Compliance**: Implementation matches specifications in @cafetera-poc.md
- [ ] **Performance Verified**: Timing requirements met with benchmarks
- [ ] **Quality Gates Passed**: Focus on integration confidence over coverage metrics
- [ ] **🚨 FULL TEST SUITE PASSES**: Run `npm test` and verify both snapshot tests and Mix tests pass
- [ ] **🚨 NO REGRESSIONS**: All previously passing tests must still pass
- [ ] **📚 END-USER DOCS UPDATED**: User-facing features documented in appropriate user guides
- [ ] **🎯 DRY COMPLIANCE**: No duplicate content between CLAUDE.md and user documentation
- [ ] **🚨 TASK CONTINUATION**: After verification, check `list_tasks status="pending"` for next task

### Success Metrics (Trophy-Focused)
- **Integration Confidence**: Component interactions thoroughly validated
- **Test Distribution**: Follow Kent's trophy (Integration-heavy, not pyramid)
- **Usage Resemblance**: Tests reflect real-world usage patterns
- **Performance**: All timing requirements from PRD satisfied  
- **Maintainability**: Integration tests provide refactoring confidence

---

## 🚨 CRITICAL: Task Progression and Regression Prevention Protocol

### Mandatory Task Completion Workflow

#### 1. Task Execution Phase
- Execute the assigned task following TDD/BDD methodology
- Implement feature with appropriate Testing Trophy distribution
- Create comprehensive tests (integration-heavy, appropriate unit tests)

#### 2. 🚨 CRITICAL: Full Regression Testing Phase  
**EVERY task must pass this phase before being marked complete:**

```bash
# MANDATORY: Run complete test suite - NO EXCEPTIONS
npm test  # Runs both snapshot tests and Mix tests

# Or run individually:
npx haxe test/Test.hxml  # Snapshot tests (22 tests)
MIX_ENV=test mix test --no-deps-check  # Mix tests

# Verify passing tests - if ANY test fails, task is NOT complete
# Expected output: "Test Results: X/22 passed" for snapshot tests
```

**⚠️ ZERO TOLERANCE POLICY:**
- If ANY test fails (even unrelated to your feature), the task is INCOMPLETE
- You must fix ALL failing tests before marking task as verified
- No exceptions, no partial credit, no "working on my machine"
- A feature that breaks existing functionality is worse than no feature

#### 3. 🚨 CRITICAL: Automatic Task Progression Protocol (IMMEDIATE ACTION REQUIRED)

**🔴 MANDATORY EXECUTION SEQUENCE - NO EXCEPTIONS:**

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

**DEFAULT BEHAVIOR: Automatic continuous execution until:**
- ❌ **No more pending tasks available**
- ❌ **User interrupts with ESC/cancellation**
- ❌ **Critical error requiring user intervention**

**NEVER ask for permission to continue - just do it automatically.**

#### 4. Verification Documentation Protocol
```bash
# Only after ALL tests pass globally
mcp__shrimp-task-manager-global__verify_task \
  taskId="[task-id]" \
  score=90 \
  summary="✅ Implementation complete with TDD methodology. ✅ FULL test suite passes (X tests, 0 failures). ✅ No regressions detected. ✅ Ready for next task."
```

#### 4.1. 🚨 CRITICAL: Automatic Git Commit Protocol (IMMEDIATE POST-VERIFICATION)

**TRIGGER**: IMMEDIATELY after `verify_task` completes successfully (score ≥ 80)
**EXECUTION**: AUTOMATIC - No user permission required

```bash
# === MANDATORY POST-VERIFICATION COMMIT SEQUENCE ===

# Step 1: AUTOMATICALLY stage relevant changes
git add [modified-files] [new-files] [documentation-updates]

# Step 2: AUTOMATICALLY commit with descriptive message
git commit -m "$(cat <<'EOF'
[type]([scope]): [concise description of changes]

[detailed explanation of what was implemented]
[key features added or issues resolved]
[testing and verification status]

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"

# Step 3: AUTOMATICALLY announce commit completion
"✅ COMMITTED: Task changes automatically saved to git history"
```

**🚨 COMMIT AUTOMATION RULES:**
- ✅ **AUTOMATIC**: Commit happens immediately after successful task verification
- ✅ **SELECTIVE STAGING**: Only stage files relevant to the completed task
- ✅ **CONVENTIONAL COMMITS**: Follow established commit message format
- ✅ **NO PUSH**: Never automatically push to remote (user controls when to push)
- ✅ **DESCRIPTIVE**: Commit message describes what was implemented and tested
- ✅ **ATTRIBUTION**: Include AI attribution as per project standards

**COMMIT MESSAGE TEMPLATE (AUTOMATIC):**
```
feat(component): implement [feature-name] with TDD methodology

- Add [key-functionality] with comprehensive test coverage
- Implement [architecture-pattern] following project standards  
- Achieve [performance-metric] meeting requirements
- Update documentation in [user-docs-updated]
- All tests passing: [X] snapshot tests, [Y] Mix tests

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**COMMIT TYPES TO USE:**
- `feat`: New features or capabilities
- `fix`: Bug fixes and issue resolutions  
- `docs`: Documentation updates only
- `refactor`: Code improvements without functional changes
- `test`: Test additions or improvements
- `perf`: Performance optimizations

#### 5. 🚨 IMMEDIATE ACTION: Post-Verification Automatic Progression

**⚠️ THE MOMENT `verify_task` COMPLETES - EXECUTE IMMEDIATELY:**

```bash
# 🔴 MANDATORY IMMEDIATE ACTION SEQUENCE:

# 1. Check for next task (AUTOMATIC)
mcp__shrimp-task-manager-global__list_tasks status="pending"

# 2. Announce progression (AUTOMATIC)
"✅ Task completed and verified! | 🔄 Checking for next task..."

# 3. Execute next task IMMEDIATELY if found (AUTOMATIC - NO PERMISSION NEEDED)
mcp__shrimp-task-manager-global__execute_task taskId="[next-task-id]"

# OR if no tasks found:
"✅ All tasks completed! | 📋 No pending tasks remaining | ⏹️ Session complete"
```

**🚨 CRITICAL: This sequence is AUTOMATIC and happens IMMEDIATELY after verify_task**
**🚨 DO NOT wait for user input, DO NOT ask for permission, JUST EXECUTE**

### Regression Prevention Standards

#### What Constitutes a Regression
- **Any previously passing test now fails**
- **Any feature that worked before now broken**  
- **Any performance degradation beyond acceptable thresholds**
- **Any compilation errors or warnings introduced**
- **Any static analysis failures (Credo, Dialyzer, Sobelow)**

#### Regression Recovery Protocol
If regressions are detected:

1. **Immediately stop feature work**
2. **Identify root cause of regression**
3. **Fix regression before continuing with feature**
4. **Re-run full test suite to confirm fix**
5. **Only then continue with original task**

#### Acceptable Test Status Changes
- ✅ **New passing tests added** (expected with new features)
- ✅ **Existing tests still pass** (mandatory requirement)
- ❌ **Any existing test now fails** (BLOCKS task completion)
- ❌ **Any test removed without replacement** (requires justification)

### Automatic Task Progression Decision Matrix

After completing a task:

| Scenario | Automatic Action |
|----------|------------------|
| 1 pending task found | ✅ Immediately execute the task |
| Multiple pending tasks | ✅ Execute highest priority/next logical task |
| No pending tasks | ⏹️ Stop with completion message |
| Tasks with unmet dependencies | ⏹️ Stop with dependency status report |
| Critical error/blocking issue | ⏹️ Stop with error details for user intervention |

**Key Point: NO user permission requests - automatic execution is the default.**

### User Control and Cancellation

**🎛️ User Control Options:**
- **ESC/Ctrl+C**: Stop automatic execution at any point
- **Interruption**: User can interrupt during any task to stop the sequence
- **Manual Control**: User can take manual control of task selection if needed

**📋 Automatic Status Updates:**
- Brief progress notifications: "✅ Task X completed | 🔄 Next: Task Y"
- No verbose explanations during automatic execution
- Detailed summaries only at natural stopping points

**⏹️ Natural Stopping Points:**
- All available tasks completed
- Dependency-blocked tasks (cannot proceed automatically)
- Critical errors requiring user intervention
- Build/test failures that cannot be auto-resolved

### Success Criteria Summary

✅ **Feature Implementation**: New functionality working as specified  
✅ **Test Coverage**: Appropriate Testing Trophy distribution  
✅ **Zero Regressions**: ALL previously passing tests still pass  
✅ **Full Test Suite**: Complete project test suite passes  
✅ **User Documentation**: End-user features properly documented in user guides  
✅ **DRY Compliance**: No duplicate content between CLAUDE.md and user docs  
✅ **Task Progression**: Next steps identified and presented to user  
✅ **Documentation**: Implementation and decisions captured in memory  

---

## Detailed Shrimp Integration Workflow

### Step-by-Step Shrimp MCP Integration

#### 1. Task Selection and Execution
```bash
# Get available tasks  
mcp__shrimp-task-manager-global__list_tasks status="pending"

# Execute specific task with TDD methodology
mcp__shrimp-task-manager-global__execute_task taskId="[task-id]"
```

#### 2. Follow Embedded TDD Instructions
Every shrimp task contains TDD instructions in the description:
- Look for "🔴 RED Phase", "🟢 GREEN Phase", "🔵 REFACTOR Phase"
- Follow "Testing Trophy Distribution" percentages
- Use embedded performance targets from PRD

#### 3. TDD Phase Progress Updates
```bash
# RED Phase Update
mcp__shrimp-task-manager-global__update_task \
  taskId="[task-id]" \
  prompt="🔴 RED Phase Complete: Created failing tests for [scenarios]. Tests fail with expected errors."

# GREEN Phase Update  
mcp__shrimp-task-manager-global__update_task \
  taskId="[task-id]" \
  prompt="🟢 GREEN Phase Complete: Implementation passes all tests. Performance: [X]ms."

# REFACTOR Phase Update
mcp__shrimp-task-manager-global__update_task \
  taskId="[task-id]" \
  prompt="🔵 REFACTOR Complete: Design improved, coverage >80%, performance optimized."
```

#### 4. Integrated Test Verification
```bash
# Verify with automatic test execution
mcp__shrimp-task-manager-global__verify_task \
  taskId="[task-id]" \
  score=85 \
  summary="TDD methodology complete. All quality gates verified."
```

**This automatically triggers:**
- TaskTestRunner.verify_task_with_tests()
- Test suite execution from task's relatedFiles
- Static analysis (Credo, Dialyzer, Sobelow)
- Performance benchmark validation
- Score adjustment based on test results

#### 5. Task Dependency Management
```bash
# Add discovered dependencies
mcp__shrimp-task-manager-global__update_task \
  taskId="[task-id]" \
  dependencies="[dep-id-1],[dep-id-2]"

# Update related files as tests are created
mcp__shrimp-task-manager-global__update_task \
  taskId="[task-id]" \
  relatedFiles='[{"path": "test/new_feature_test.exs", "type": "CREATE"}]'
```

#### 6. Quality Gate Failure Protocol
```bash
# If tests fail or quality gates don't pass
mcp__shrimp-task-manager-global__update_task \
  taskId="[task-id]" \
  prompt="Quality gate failure: [specific issues]. Continuing work to resolve."

# Only verify when all issues resolved
mcp__shrimp-task-manager-global__verify_task \
  taskId="[task-id]" \
  score=90 \
  summary="All quality gates pass. No regressions detected."
```

#### 7. 🚨 CRITICAL: Automatic Post-Verification Task Progression
```bash
# MANDATORY after any task verification - check for next work
mcp__shrimp-task-manager-global__list_tasks status="pending"

# AUTOMATICALLY execute next task (NO user permission needed)
"✅ Task completed | 🔄 Found X pending tasks | ▶️ Executing next: [Task A]"

# Immediately proceed to next task
mcp__shrimp-task-manager-global__execute_task taskId="[task-a-id]"
```

**NO user confirmation required - automatic execution is the standard workflow.**

### Feedback Loop Integration

#### Communicating Discoveries to Planner
```bash
mcp__shrimp-task-manager-global__update_task \
  taskId="[task-id]" \
  prompt="FEEDBACK: Task more complex than expected. Recommend splitting into [subtasks]. Missing dependency on [component] discovered."
```

### Key Commands Reference

- **`list_tasks`**: Get tasks with TDD instructions
- **`execute_task`**: Start task with embedded methodology  
- **`get_task_detail`**: Get complete task with test requirements
- **`update_task`**: Report progress at each TDD phase
- **`verify_task`**: Trigger integrated test verification
- **`update_task dependencies`**: Manage discovered dependencies

### Integration Success Criteria

✅ **Proper Shrimp Usage:**
- All task interactions through MCP tools
- TDD phase progress tracked in shrimp
- Test verification integrated with verify_task
- Task dependencies managed through shrimp
- Feedback communicated back to planning

✅ **Quality Assurance:**
- TaskTestRunner validates all implementations
- Static analysis enforced automatically
- Performance benchmarks meet PRD requirements
- No regressions allowed in task completion
- **🚨 FULL test suite passes before any task marked complete**

✅ **🚨 CRITICAL: Automatic Task Progression:**
- After every task completion, automatically check for next pending tasks
- **AUTOMATICALLY execute next logical task (no user permission needed)**
- Never end session without checking for more work
- Maintain project momentum through **continuous automatic execution**
- Only stop on user interruption (ESC), no tasks available, or critical errors

## 🧠 Automatic Memory Management and Documentation

### 🚨 CRITICAL: Automatic Memory Update Protocol

**EVERY task completion MUST automatically update memory with:**

#### **Mandatory Memory Capture (No Exceptions)**
1. **🔧 Implementation Details**: What was built, how it works, key components
2. **⚡ Performance Metrics**: Actual timing results, memory usage, benchmark data
3. **🧪 Test Results**: Test count, coverage achieved, integration test outcomes
4. **🏗️ Architecture Impact**: How this changes system design, new patterns introduced
5. **🐛 Issues Encountered**: Problems faced, solutions found, debugging insights
6. **📋 Technical Decisions**: Key choices made, trade-offs considered, rationale
7. **🔗 Integration Points**: How this connects to other components, API changes
8. **📈 Quality Metrics**: Static analysis results, code quality improvements
9. **📚 User Documentation Impact**: What user-facing features were added/changed
10. **🎯 Documentation Updates**: Which user docs were updated following DRY principle

#### **🎯 High-Value Information to Always Capture**
- **Error Messages & Solutions**: Exact error messages encountered and how they were resolved
- **Performance Numbers**: Actual benchmark results, timing data, memory usage statistics  
- **Test Coverage**: Specific test count, pass/fail rates, integration test insights
- **Code Patterns**: New patterns introduced, architectural decisions, design trade-offs
- **Dependencies**: New dependencies added, version constraints, compatibility issues
- **Configuration Changes**: Environment variables, config files, deployment settings
- **API Changes**: New endpoints, modified interfaces, breaking changes
- **Database Changes**: Schema modifications, migration scripts, data model evolution

#### **🔍 Context Capture Guidelines**
- **Before/After States**: What changed from start to finish
- **Decision Context**: Why specific approaches were chosen over alternatives
- **Future Implications**: How this impacts upcoming tasks or features
- **Lessons Learned**: What would be done differently, optimization opportunities
- **Integration Notes**: How this fits with existing architecture, potential conflicts

### Automatic Documentation Workflow

After completing each task, you MUST automatically document the implementation:

#### 1. 🔄 Automatic CLAUDE.md Update (Immediate)
**DO THIS AUTOMATICALLY after every task verification:**

```bash
# AUTOMATICALLY append to CLAUDE.md or appropriate memory file
# NO user prompting - just update memory immediately
```

**🚨 Auto-Capture Template (Use this format automatically):**
```markdown
# Task: [Task Name] - COMPLETED

## Implementation Summary
- **What was built**: [Core functionality implemented]
- **TDD Approach**: [RED-GREEN-REFACTOR phases completed]
- **Test Results**: [X tests passing, Y coverage achieved]
- **Performance**: [Timing benchmarks met/exceeded]
- **Architecture Impact**: [How this affects system design]

## User Documentation Impact
- **User-Facing Features**: [New features requiring user documentation]
- **Documentation Updated**: [Which user docs were updated: FEATURES.md, EXAMPLES.md, ANNOTATIONS.md, GETTING_STARTED.md]
- **DRY Compliance**: [How CLAUDE.md now references user docs instead of duplicating]

## Key Technical Decisions
- [Decision 1]: [Rationale and trade-offs]
- [Decision 2]: [Performance considerations]
- [Decision 3]: [Integration approach chosen]

## Files Modified/Created
- [list of significant files with purpose]
- Test files: [BDD test files created]
- Configuration: [Any config changes]
- Documentation: [User docs updated]

## Learnings and Discoveries
- [Implementation insights]
- [Performance optimizations discovered]
- [Integration complexity encountered]
- [Recommendations for future similar tasks]

## References
- PRD sections: [specific line references]
- Related tasks: [dependencies and follow-ups]
- User Documentation: [References to updated user guides]
```

#### 2. CLAUDE.md Size Management and Splitting

When CLAUDE.md approaches 5000+ lines or becomes unwieldy:

**Create .llm-memory directory structure:**
```bash
mkdir -p .llm-memory/tasks
mkdir -p .llm-memory/architecture
mkdir -p .llm-memory/learnings
mkdir -p .llm-memory/performance
```

**Split content by category:**
- `.llm-memory/tasks/[task-category].md` - Task implementation summaries
- `.llm-memory/architecture/[component].md` - Architecture decisions and patterns
- `.llm-memory/learnings/[domain].md` - Technical learnings and discoveries
- `.llm-memory/performance/[component].md` - Performance optimizations and benchmarks

**Update CLAUDE.md with references:**
```markdown
# CafeteraOS Development Memory

## Current Project Status
[Brief current status and active work]

## Task Implementation History
@.llm-memory/tasks/memory-system.md
@.llm-memory/tasks/testing-integration.md
@.llm-memory/tasks/taskmaster-sync.md

## Architecture Documentation
@.llm-memory/architecture/memory-first-design.md
@.llm-memory/architecture/testing-trophy-integration.md
@.llm-memory/architecture/performance-requirements.md

## Technical Learnings
@.llm-memory/learnings/elixir-patterns.md
@.llm-memory/learnings/performance-optimization.md
@.llm-memory/learnings/testing-strategies.md

## Performance Benchmarks
@.llm-memory/performance/node-operations.md
@.llm-memory/performance/search-performance.md
@.llm-memory/performance/sync-operations.md
```

#### 3. Memory File Creation Protocol

When creating split files, include:

**File Header Template:**
```markdown
# [Component/Domain] - Implementation Memory

## Context
Part of CafeteraOS development - split from main CLAUDE.md for better organization.
Related files: @.llm-memory/[related-files].md

## [Content sections...]
```

**Cross-referencing:**
- Reference related memory files using `@.llm-memory/path/file.md`
- Include bidirectional references where relevant
- Maintain chronological order within categories

#### 4. 🤖 Fully Automated Documentation Workflow

**AUTOMATICALLY execute after each task completion (no user interaction):**

1. **🔄 Auto-Document Implementation**:
   ```bash
   # AUTOMATICALLY add comprehensive task summary to CLAUDE.md
   # Capture: implementation approach, TDD phases, test results, performance metrics
   # NO user prompting required - just do it
   ```

2. **📏 Auto-Check Size and Split**:
   ```bash
   # IF CLAUDE.md > 5000 lines, AUTOMATICALLY split by category
   # AUTOMATICALLY create .llm-memory structure
   # AUTOMATICALLY update CLAUDE.md with @references
   ```

3. **📝 Auto-Update Shrimp Task**:
   ```bash
   mcp__shrimp-task-manager-global__update_task \
     taskId="[task-id]" \
     prompt="🧠 MEMORY UPDATED: Documentation automatically added to CLAUDE.md. Captured: implementation details, test results (X tests passing), performance metrics, technical decisions, and integration points."
   ```

4. **⚡ Auto-Continue to Next Task**:
   ```bash
   # After memory update, AUTOMATICALLY check for next task and execute
   # Keep the workflow moving without user intervention
   ```

#### 5. 🧠 Memory Integration with Task Verification (Automatic)

**AUTOMATICALLY update memory BEFORE verification:**

```bash
# Step 1: Auto-capture all mandatory memory items
# Step 2: Auto-update CLAUDE.md or split files  
# Step 3: Include memory status in verification

mcp__shrimp-task-manager-global__verify_task \
  taskId="[task-id]" \
  score=90 \
  summary="✅ Implementation complete with TDD methodology. 🧠 Memory automatically updated: captured implementation details, test results (X tests, 0 failures), performance metrics (Yms avg), technical decisions, and integration points. Ready for next task."
```

#### 6. 🔄 Memory Update Quality Gates

**Task verification BLOCKED if memory updates incomplete:**

- ❌ **No memory update** = Task not verified
- ❌ **Missing performance metrics** = Incomplete verification
- ❌ **No error/solution documentation** = Incomplete verification  
- ❌ **Architectural impact not captured** = Incomplete verification
- ✅ **Complete memory capture** = Ready for verification

### 🧠 Automatic Memory Success Criteria

✅ **🔄 AUTOMATIC: Every completed task documented in CLAUDE.md or split files**
✅ **🔄 AUTOMATIC: Implementation approach and TDD phases captured**
✅ **🔄 AUTOMATIC: Technical decisions and trade-offs recorded**
✅ **🔄 AUTOMATIC: Performance metrics and benchmarks documented**
✅ **🔄 AUTOMATIC: Error messages and solutions preserved**
✅ **🔄 AUTOMATIC: Test results and coverage data captured**
✅ **🔄 AUTOMATIC: Architecture impact and integration notes recorded**
✅ **🔄 AUTOMATIC: Memory structure maintained with proper @references**
✅ **🔄 AUTOMATIC: Cross-references between related implementations**
✅ **🔄 AUTOMATIC: Lessons learned and optimization opportunities documented**

**🚨 KEY PRINCIPLE: Memory updates are NOT optional - they are automatic and mandatory**

This automatic memory protocol ensures that ALL implementation knowledge is captured without user intervention, maintaining comprehensive institutional memory of technical decisions, patterns, performance data, and learnings for future development.

---

This detailed integration ensures TDD methodology is properly tracked and verified through the complete shrimp task management workflow, with comprehensive documentation of all implementations and learnings preserved in the project's memory structure.

---

This enhanced task execution mode ensures high-quality, test-driven development while maintaining full integration with the shrimp task management system and preserving all implementation knowledge for future reference.

---

## 🚨 CRITICAL: Automatic Context Management and Memory Preservation

### 🔄 Context Exhaustion Protocol (AUTOMATIC)

**TRIGGER CONDITION**: When context usage reaches 0% remaining
**SAFETY CONDITION**: Only execute if NO tasks are currently `in_progress` 

#### 1. 🔍 Context Monitoring (Continuous)
Monitor context usage and automatically trigger preservation when:
- Context remaining ≤ 0%
- No active tasks in `in_progress` status
- Safe stopping point reached (between tasks, not mid-implementation)

#### 2. 🧠 Automatic Memory Preservation (NO USER INTERACTION)
When context exhaustion detected, AUTOMATICALLY execute:

```bash
# Step 1: Verify no tasks in progress (SAFETY CHECK)
mcp__shrimp-task-manager-global__list_tasks status="in_progress"
# If result shows tasks in progress: ABORT context clearing, continue with current work

# Step 2: Automatic comprehensive memory save (if safe to clear)
# AUTOMATICALLY capture to CLAUDE.md or appropriate memory files:
```

**🧠 AUTOMATIC CONTEXT PRESERVATION CONTENT:**
1. **🔄 Task Status Summary**:
   - Current task completion status
   - Next logical tasks in pipeline  
   - Any blocking dependencies or issues
   - Progress statistics (X completed, Y pending)

2. **🏗️ Implementation Context**:
   - Current architecture state and recent changes
   - Active patterns being implemented
   - Performance metrics and benchmarks achieved
   - Key technical decisions made in current session

3. **🧪 Quality and Testing State**:
   - Test suite status (passing counts, coverage achieved)
   - Static analysis results and any warnings to resolve
   - Performance benchmarks and optimization opportunities
   - Integration points validated or requiring attention

4. **🐛 Issues and Solutions Context**:
   - Error messages encountered and solutions found
   - Debugging insights and resolution patterns
   - Compatibility issues discovered and handled
   - Configuration changes made and their impact

5. **📋 Future Continuity Information**:
   - Recommendations for next session priorities
   - Potential risks or areas requiring attention
   - Dependencies that may become available
   - Performance targets still requiring achievement

#### 3. 🗑️ Automatic Context Clearing (SAFE EXECUTION)
After successful memory preservation:

```bash
# AUTOMATICALLY clear context with preservation message
"🧠 CONTEXT PRESERVED → Memory updated with current session state
📋 READY FOR CONTINUATION → Task state maintained in shrimp system  
🔄 SEAMLESS RESUMPTION → Next session can continue from exact stopping point

Context cleared for optimization. Resume with: Check shrimp task status and continue from preserved state."
```

#### 4. 🔄 Session Continuity Protocol 

**Next Session Resumption:**
```bash
# Immediately upon new session start:
# 1. Check task system for current state
mcp__shrimp-task-manager-global__list_tasks status="pending,in_progress"

# 2. Review preserved memory context
# Read relevant @.llm-memory files and CLAUDE.md for session state

# 3. Resume from exact stopping point
# Continue with next logical task based on preserved context
```

### 🛡️ Safety Mechanisms and Safeguards

#### **Context Clearing Safety Checks (MANDATORY)**
```bash
# BEFORE any context clearing, verify:
# ❌ NO tasks with status="in_progress" 
# ❌ NO critical errors requiring immediate user attention
# ❌ NO active debugging session or incomplete troubleshooting
# ❌ NO mid-implementation state (RED phase tests without GREEN phase)
# ✅ All current work properly saved and documented
# ✅ Shrimp system reflects accurate current state
# ✅ Memory preservation completed successfully
```

#### **Abort Conditions (Never Clear Context If)**
- **Active Task in Progress**: Any task shows `in_progress` status
- **Critical Errors Present**: System in error state requiring resolution
- **Mid-TDD Cycle**: RED phase started but GREEN/REFACTOR incomplete
- **User Intervention Required**: Decisions or confirmations pending
- **Test Failures**: Test suite failures requiring immediate attention
- **Build Broken**: Compilation or critical build issues present

#### **Safe Context Clearing Scenarios (OK to Clear)**
- **Between Tasks**: All current work completed and verified
- **Task Verification Complete**: Current task successfully verified in shrimp
- **No Blocking Issues**: All critical systems functioning correctly
- **Memory Preserved**: All important context captured in memory files
- **Clear Task Pipeline**: Next steps clearly defined in shrimp system

### 🎯 Context Preservation Templates (AUTOMATIC)

#### **SESSION STATE PRESERVATION (Auto-captured)**
```markdown
# Context Preservation - Session [Date/Time]

## Task Status Summary
- **Current Session Progress**: [X tasks completed, Y pending]
- **Last Completed Task**: [Task name and verification status]
- **Next Priority Tasks**: [List of 2-3 next logical tasks]
- **Blocking Dependencies**: [Any dependencies preventing progress]

## Technical Context State  
- **Architecture Progress**: [Current state of system architecture]
- **Performance Metrics**: [Latest benchmarks and timing data]
- **Test Suite Status**: [Pass/fail counts, coverage percentages]
- **Integration Points**: [Components modified, APIs changed]

## Issues and Solutions Context
- **Error Resolution**: [Problems solved, debugging insights]
- **Configuration Changes**: [Environment, dependency updates]
- **Optimization Discoveries**: [Performance improvements found]
- **Compatibility Notes**: [Version constraints, breaking changes]

## Continuity Information
- **Resume Priority**: [What should be tackled first next session]
- **Risk Areas**: [Potential issues requiring attention]
- **Optimization Opportunities**: [Performance or architecture improvements]
- **Quality Gates**: [Any warnings or static analysis issues to resolve]

## Session Statistics
- **Duration**: [Session length]
- **Tasks Completed**: [Count and success rate]
- **Tests Added/Modified**: [Test coverage impact]
- **Performance Improvements**: [Measurable optimizations achieved]
```

### 🚀 Optimization Benefits

#### **Context Usage Efficiency**
- **Prevent Context Exhaustion**: Never run out mid-task
- **Seamless Continuity**: Pick up exactly where left off
- **Preserved Knowledge**: No loss of implementation insights
- **Optimal Resource Usage**: Context used efficiently for actual work

#### **Development Productivity** 
- **No Interruption**: Automatic optimization doesn't disrupt flow
- **Complete Context**: All necessary information preserved
- **Task Momentum**: Shrimp system maintains project momentum  
- **Quality Continuity**: Test suite status and quality gates preserved

#### **Risk Mitigation**
- **No Lost Work**: All progress and decisions captured
- **Safe Automation**: Only triggers in safe scenarios
- **Complete Recovery**: Next session can fully continue project
- **Failure Prevention**: Never clear context with work in progress

### 🔧 Implementation Guidelines

#### **Context Monitoring Integration**
- Monitor context percentage throughout task execution
- Pre-calculate context requirements for current task completion
- Trigger preservation with sufficient buffer (not exactly 0%)
- Maintain awareness of context usage in task planning

#### **Memory Integration Points**
- Use existing CLAUDE.md and .llm-memory structure
- Follow established documentation patterns
- Maintain cross-references and chronological order
- Integrate with automatic documentation workflow

#### **Shrimp System Coordination**
- Rely on shrimp task system for persistent state
- Ensure all task progress properly recorded in shrimp
- Use shrimp verification system to confirm safe clearing points
- Coordinate context clearing with task completion cycles

### 🎯 Success Criteria for Automatic Context Management

✅ **🔄 AUTOMATIC CONTEXT MONITORING**: Continuous monitoring of context usage without user awareness
✅ **🛡️ SAFETY-FIRST CLEARING**: Never clear context with work in progress or critical issues
✅ **🧠 COMPLETE MEMORY PRESERVATION**: All session knowledge captured before clearing
✅ **🔄 SEAMLESS CONTINUITY**: Next session resumes from exact stopping point  
✅ **📋 TASK SYSTEM INTEGRATION**: Shrimp system maintains complete project state
✅ **⚡ OPTIMIZATION ACHIEVED**: Context used efficiently for maximum productivity
✅ **🚫 ZERO WORK LOSS**: No implementation details or decisions lost in clearing
✅ **🤖 FULLY AUTOMATIC**: No user intervention required for optimization

**🚨 KEY PRINCIPLE: Context optimization should be invisible to user except for improved efficiency**

This automatic context management ensures optimal context usage while maintaining complete development continuity and never losing implementation knowledge or work progress.