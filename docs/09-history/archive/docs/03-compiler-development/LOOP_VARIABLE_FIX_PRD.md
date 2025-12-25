# Product Requirements Document: Loop Variable Substitution Fix

## Executive Summary
Fix the nested loop variable substitution issue where Haxe's analyzer optimization replaces loop variables with literal values, resulting in non-idiomatic Elixir output.

## Problem Statement
When Haxe's `-D analyzer-optimize` flag is enabled, loop variables in string concatenations are replaced with literal values before our compiler processes them. This results in:
- Nested loops generating `"Cell (#{0},#{1})"` instead of `"Cell (#{i},#{j})"`
- Simple loops being completely unrolled into separate statements

## Success Criteria
1. **Test-Driven Development**: All fixes must have corresponding tests with idiomatic intended outputs
2. **TodoApp Compilation**: Must compile without errors or warnings in both Haxe and Elixir
3. **No Runtime Errors**: TodoApp must run successfully after compilation
4. **Idiomatic Output**: Generated Elixir must look hand-written by an Elixir expert

## Technical Approach

### Map-Reduce Process
1. **Map Phase**: Identify all affected patterns and create test cases
2. **Analysis Phase**: Understand AST structure at each transformation stage
3. **Solution Phase**: Implement targeted fixes
4. **Reduce Phase**: Integrate solutions into coherent transformation pipeline
5. **Validation Phase**: Verify with tests and TodoApp

### Key Technical Decisions
1. **AST-First**: All solutions must work at AST level, no string manipulation
2. **Pattern Detection**: Use metadata and context tracking, not hardcoded patterns
3. **Pass Ordering**: Consider reordering transformation passes if needed
4. **Reference Implementations**: Study reflaxe reference compilers for patterns

## Implementation Strategy

### Phase 1: Pattern Analysis
- Analyze actual AST structure when loops are optimized
- Document all transformation stages
- Identify where variable information is lost

### Phase 2: Solution Design
- Consult Codex for architectural guidance
- Design metadata preservation strategy
- Plan transformation pass modifications

### Phase 3: Implementation
- Create comprehensive test cases first
- Implement fixes following test failures
- Refactor large files (>2000 lines) using SOLID principles

### Phase 4: Validation
- Run full test suite
- Compile and run TodoApp
- Verify idiomatic output quality

## Risk Mitigation
- **Getting Stuck**: Consult Codex with detailed context
- **Circular Work**: Check git history before implementing
- **Code Quality**: Follow AGENTS.md rules strictly
- **File Size**: Refactor when files exceed 2000 lines

## Reference Resources
- `$HAXE_ELIXIR_REFERENCE_PATH` - Reference implementations (optional local checkout)
- Reflaxe compiler patterns
- Haxe source code
- Phoenix and Elixir patterns

## Acceptance Criteria
- [ ] All loop-related tests pass
- [ ] TodoApp compiles without warnings
- [ ] Generated code is idiomatic
- [ ] No hardcoded patterns in solution
- [ ] Documentation is comprehensive
- [ ] Code follows SOLID principles
