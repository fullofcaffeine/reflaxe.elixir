# Product Requirements Document: Phoenix.Presence Module Context Fix

## Executive Summary

This PRD outlines the implementation plan for fixing the Phoenix.Presence function call issue where modules using `Phoenix.Presence` require `self()` as the first argument for injected functions, but our compiler currently generates calls without it.

## Problem Statement

### Current Behavior
When a Haxe class with `@:presence` annotation calls `Presence.track()`, the compiler generates:
```elixir
track(socket, "users", user_id, metadata)
```

This causes a runtime error:
```
** (FunctionClauseError) no function clause matching in Phoenix.Tracker.track/5
```

### Expected Behavior
Inside a module that uses `Phoenix.Presence`, the generated code should be:
```elixir
track(self(), socket, "users", user_id, metadata)
```

### Root Cause
Phoenix.Presence works differently when called from INSIDE vs OUTSIDE a Presence module:
- **Inside**: Uses injected local functions that automatically handle self()
- **Outside**: Uses Phoenix.Presence.track with explicit PID
- The Haxe compiler needs to generate different code based on this context

## Technical Requirements

### Functional Requirements

1. **Module Context Detection**
   - Detect when compiling a class with `@:presence` metadata
   - Track this context throughout the compilation pipeline
   - Pass context information from ElixirCompiler to ElixirASTBuilder

2. **Context-Aware Code Generation**
   - When inside a @:presence module:
     - Generate local function calls with self() as first argument
     - Methods affected: track, update, untrack
     - Method not affected: list (doesn't need self())
   - When outside a @:presence module:
     - Generate Phoenix.Presence.method() calls as currently

3. **Backward Compatibility**
   - Existing non-@:presence code must continue to work
   - Phoenix.Presence extern calls from regular modules unchanged

### Non-Functional Requirements

1. **Performance**: No measurable compilation time increase
2. **Maintainability**: Clear separation of concerns
3. **Testability**: Comprehensive test coverage for both contexts
4. **Documentation**: Clear inline documentation of the context-aware behavior

## Implementation Architecture

### Phase 1: Module Context Detection

**Component**: ElixirCompiler
**File**: `src/reflaxe/elixir/ElixirCompiler.hx`

```haxe
// Add field to track presence module context
public var isInPresenceModule: Bool = false;

// In compileClassImpl method
override function compileClassImpl(classType: ClassType, ...): Null<ElixirAST> {
    // Check for @:presence metadata
    isInPresenceModule = classType.meta.has(":presence");
    
    // Pass to AST builder
    var builder = new ElixirASTBuilder(this, isInPresenceModule);
    // ... rest of compilation
}
```

### Phase 2: AST Builder Modifications

**Component**: ElixirASTBuilder
**File**: `src/reflaxe/elixir/ast/ElixirASTBuilder.hx`

```haxe
// Add constructor parameter
public function new(compiler: ElixirCompiler, isInPresenceModule: Bool = false) {
    this.compiler = compiler;
    this.isInPresenceModule = isInPresenceModule;
}

// In TField case for static methods (around line 1421)
case TField(_, FStatic(classRef, cf)):
    var classType = classRef.get();
    var methodName = cf.get().name;
    
    // Special handling for Presence methods
    if (classType.name == "Presence" && isInPresenceModule) {
        return handlePresenceMethodInModule(methodName, args);
    }
    // ... existing logic

// New helper method
function handlePresenceMethodInModule(methodName: String, args: Array<ElixirAST>): ElixirAST {
    var snakeCaseMethod = toSnakeCase(methodName);
    
    switch(methodName) {
        case "track", "update", "untrack":
            // Add self() as first argument
            var selfCall = makeAST(ECall(null, "self", []));
            var newArgs = [selfCall].concat(args);
            return ECall(null, snakeCaseMethod, newArgs);
            
        case "list", "listTopic":
            // No self() needed
            return ECall(null, snakeCaseMethod, args);
            
        default:
            // Fallback to regular handling
            return null;
    }
}
```

### Phase 3: Testing Strategy

1. **Unit Test**: Create `test/tests/PhoenixPresenceModule/`
   - Test @:presence module generates correct calls
   - Test regular module generates Phoenix.Presence calls
   - Test all Presence methods (track, update, list, untrack)

2. **Integration Test**: todo-app validation
   - Compile todo-app with fix
   - Verify presence.ex has correct function calls
   - Test runtime functionality works

3. **Regression Test**: Ensure existing code unaffected
   - Run full test suite
   - Verify non-presence Phoenix code unchanged

## Success Metrics

1. **Functional Success**
   - ✅ TodoPresence.hx compiles without errors
   - ✅ Generated presence.ex contains `track(self(), ...)` calls
   - ✅ Phoenix server starts without FunctionClauseError
   - ✅ Presence functionality works at runtime

2. **Quality Metrics**
   - ✅ Zero regression in existing tests
   - ✅ New tests provide 100% coverage of presence scenarios
   - ✅ Code follows established compiler patterns

## Risk Analysis

### Technical Risks

1. **Risk**: Breaking existing Phoenix.Presence usage
   - **Mitigation**: Comprehensive testing of both contexts
   - **Fallback**: Feature flag to disable new behavior

2. **Risk**: Complex edge cases with nested modules
   - **Mitigation**: Clear documentation of limitations
   - **Fallback**: Only support direct @:presence classes

3. **Risk**: Performance impact from context tracking
   - **Mitigation**: Use simple boolean flag
   - **Fallback**: Cache context per compilation unit

## Alternative Approaches Considered

1. **PresenceModule Base Class**
   - Pros: Explicit, type-safe
   - Cons: Requires __elixir__() in user code
   - Decision: Rejected - violates principle of no __elixir__ in user code

2. **Metadata on Each Method Call**
   - Pros: Fine-grained control
   - Cons: Verbose, error-prone
   - Decision: Rejected - too much burden on users

3. **Compiler-Level Context Detection** 
   - Pros: Transparent to users, follows Phoenix patterns
   - Cons: Requires compiler modification
   - Decision: **Selected** - best user experience

## Timeline

- **Phase 1**: Module context detection (1 hour)
- **Phase 2**: AST builder modifications (2 hours)
- **Phase 3**: Testing and validation (1 hour)
- **Total estimate**: 4 hours

## Dependencies

- ElixirCompiler.hx must pass context to ElixirASTBuilder
- ElixirASTBuilder must have access to current module metadata
- No external dependencies required

## Open Questions

1. Should we support nested @:presence modules?
2. How to handle inheritance from @:presence classes?
3. Should we add debug traces for presence context?

## Approval

This PRD represents the technical approach to fixing the Phoenix.Presence module context issue. The solution is designed to be minimally invasive while providing correct behavior for both internal and external Presence usage.

**Status**: Ready for implementation
**Priority**: High (blocking todo-app functionality)
**Owner**: Compiler team