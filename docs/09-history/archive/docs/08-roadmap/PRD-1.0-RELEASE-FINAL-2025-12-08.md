# PRD: 1.0 Release - Todo-App E2E Working

**Created**: 2025-12-08 11:19:09
**Status**: Active
**Priority**: P0 - Critical

## Executive Summary

Get the Reflaxe.Elixir todo-app example to 1.0 release quality:
1. Zero Haxe compilation errors
2. Zero critical Elixir compilation warnings
3. All 15 Playwright E2E tests passing
4. All 78 snapshot tests passing (individually reviewed)

## Current State Assessment

| Component | Status | Details |
|-----------|--------|---------|
| Haxe Compilation | ✅ Pass | Works from todo-app directory |
| Elixir Compilation | ⚠️ Warnings | 8+ unused variable/function warnings |
| Snapshot Tests | ❌ 60/78 | 18 failing (output mismatch, syntax OK) |
| Playwright E2E | ? Unknown | Needs validation |

## User Requirements

1. **Priority**: Playwright E2E tests first (functional app over compiler purity)
2. **Snapshots**: Review each failure individually to verify output is sound
3. **Warnings**: Fix critical ones; document non-critical for post-1.0 point release

## Success Criteria

- [ ] `npx haxe build-server.hxml` - Zero errors
- [ ] `mix compile` - Zero critical warnings
- [ ] Playwright E2E - All 15 tests pass
- [ ] Snapshot tests - 78/78 pass (all reviewed)
- [ ] QA sentinel with `--playwright` - Clean exit

---

## Phased Execution Plan

### Phase 1: Validate Playwright E2E Status (P0)
**Goal**: Establish baseline - which E2E tests pass/fail

**Rationale**: Can't fix what we can't measure. Need current state before making changes.

**Tasks**:
1. Boot todo-app with QA sentinel (async, deadline 300s)
2. Run all 15 Playwright tests with timeout
3. Document results with failure reasons

**bd Issue**: `1.0-phase1-validate-e2e`

---

### Phase 2: Fix E2E Test Failures (P0)
**Goal**: All 15 Playwright tests pass

**Depends on**: Phase 1 (need to know what's broken)

**Likely issues**:
- Incomplete stub functions in TodoLive.hx (`completeAllTodos`, `deleteCompletedTodos`)
- Event handling issues
- Runtime errors from generated code

**Files to modify**:
- `examples/todo-app/src_haxe/server/live/TodoLive.hx`
- Possibly compiler transforms if systematic

**bd Issue**: `1.0-phase2-fix-e2e-failures`

---

### Phase 3: Fix Critical Elixir Warnings (P1)
**Goal**: Zero critical warnings (unused functions, dead code, type violations)

**Depends on**: Phase 2 (E2E tests verify we don't break functionality)

**Critical warnings to fix**:
1. Unused functions: `render_todo_item/2`, `render_tags/1` (lines 520, 599)
2. Dead code: `list = list` stub patterns
3. Type violations: "clause will never match" warnings

**Non-critical (defer to post-1.0)**:
- Unused `params` in handle_event clauses
- Unused pattern variables in nested cases

**bd Issues**:
- `1.0-phase3-fix-critical-warnings`
- `1.0-post-fix-unused-params` (deferred)

---

### Phase 4: Review & Fix Snapshot Tests (P1)
**Goal**: All 78 snapshot tests pass with verified correct output

**Depends on**: Phase 3 (compiler changes may affect snapshots)

**Approach**:
1. Diff each failing test's `out/` vs `intended/`
2. Verify generated Elixir is sound and idiomatic
3. If improvement → update `intended/`
4. If regression → fix compiler

**Failing tests (18)**:
- core/SourceMapGeneration
- core/switch_variable_extraction
- core/domain_abstractions_exunit
- core/strings (timeout - investigate)
- core/CaseClauseVariableDeclarations
- core/enhanced_pattern_matching
- core/ElixirInjection
- core/option_nested_pattern
- core/enhanced_patterns
- core/enums
- core/elixir_idiomatic
- core/SourceMapTracking
- core/elixir_injection_test
- core/idiomatic_loops
- core/domain_abstractions
- core/try_catch
- core/idiomatic_enum_patterns
- regression/enum_pattern_names

**bd Issue**: `1.0-phase4-review-snapshot-tests`

---

### Phase 5: Final Validation & Cleanup (P1)
**Goal**: Full green CI, bd issues closed

**Depends on**: Phases 1-4

**Tasks**:
1. Full QA sentinel with `--playwright`
2. Full `npm test` - all snapshot tests
3. Create bd issues for deferred warnings
4. Close completed bd issues
5. Final commit

**bd Issue**: `1.0-phase5-final-validation`

---

## Timeout Safety Requirements

All commands MUST have timeouts to prevent agent hangs:

| Operation | Timeout | Command Pattern |
|-----------|---------|-----------------|
| QA Sentinel | 300s | `--deadline 300` |
| Playwright | 300s | `timeout 300 npx playwright test` |
| Individual test | 120s | `timeout 120` |
| Full npm test | 900s | `timeout 900 npm test` |

---

## bd Issue Dependency Graph

```
1.0-phase1-validate-e2e (P0)
    ↓
1.0-phase2-fix-e2e-failures (P0)
    ↓
1.0-phase3-fix-critical-warnings (P1)
    ↓
1.0-phase4-review-snapshot-tests (P1)
    ↓
1.0-phase5-final-validation (P1)
    ↓
haxe.elixir-713 (1.0 Release Epic) - CLOSE
```

---

## Issues to Close on Completion

**Existing issues that will be resolved**:
- `haxe.elixir-713` - 1.0 Release epic
- `haxe.elixir-i4w` - Run Playwright E2E tests
- `haxe.elixir-9jg` - Run QA sentinel
- `haxe.elixir-5tm` - Fix unused function warnings
- `haxe.elixir-e0m` - Fix app-level unused variables
- `haxe.elixir-2cr`, `haxe.elixir-cje`, `haxe.elixir-n6u`, `haxe.elixir-ml4` - Module issues (already exist in std/)

**Issues to create for post-1.0**:
- Unused `params` in handle_event clauses (compiler improvement)
- Unused pattern variables in nested cases (optimizer)

---

## Files Reference

### Primary Files to Modify
- `examples/todo-app/src_haxe/server/live/TodoLive.hx` - App fixes
- `test/snapshot/*/intended/` - Snapshot updates after review

### Potentially Modified (if systematic issues)
- `src/reflaxe/elixir/ast/transformers/` - Compiler transforms

### Reference Files
- `std/phoenix/SafePubSub.hx` - Exists ✅
- `std/phoenix/Sorting.hx` - Exists ✅
- `std/phoenix/types/Flash.hx` - Exists ✅
- `std/ecto/ChangesetTools.hx` - Exists ✅

---

## Appendix: Exploration Findings

### Elixir Warning Analysis

| Warning Type | Count | Priority | Fix Location |
|-------------|-------|----------|--------------|
| Unused functions | 2 | Critical | TodoLive.hx |
| Dead assignments (`x = x`) | 3 | Critical | TodoLive.hx stubs |
| Type violations | 3 | Critical | Compiler/App |
| Unused `params` | 5 | Deferred | Compiler transform |
| Unused pattern vars | 15+ | Deferred | Optimizer |

### Snapshot Test Failure Analysis

- **17 tests**: Output mismatch with valid syntax (review needed)
- **1 test**: Timeout (core/strings - investigate for infinite loop)
- **Pattern**: Mostly related to pattern matching and enum handling
