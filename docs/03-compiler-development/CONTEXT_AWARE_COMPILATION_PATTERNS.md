# Context-Aware Compilation Patterns

## Architectural Lessons: Context Detection vs Hardcoded Patterns

This document captures critical architectural lessons learned during Phoenix API integration, which demonstrates why **context-aware compilation** and **API validation** are superior to **hardcoded pattern matching**.

## 🚨 The Problem: Brittle Hardcoded Detection

### The Issue
When fixing Phoenix.LiveView.assign API calls, the initial approach used hardcoded field name detection:

```haxe
// ❌ BRITTLE APPROACH: Hardcoded field names
var liveviewAssignFields = [
    "todos", "filter", "sort_by", "current_user", "editing_todo", 
    "show_form", "search_query", "selected_tags", "total_todos",
    "completed_todos", "pending_todos", "loading", "error", "success",
    "changeset", "assigns", "socket", "params", "session"
];

var liveviewFieldMatches = 0;
for (field in fieldNames) {
    if (liveviewAssignFields.indexOf(field) != -1 && isValidAtomName(field)) {
        liveviewFieldMatches++;
    }
}

if (liveviewFieldMatches >= 3) {
    // Use atom keys for LiveView assigns
    return true;
}
```

### Why This is Architecturally Flawed

1. **Unmaintainable**: Every new LiveView field requires compiler updates
2. **Fragile**: Changes to field naming conventions break the detection
3. **Non-scalable**: Doesn't work for user-defined field names
4. **Magic Numbers**: The "3 matches" threshold is arbitrary and brittle
5. **Framework Coupling**: Hardcodes Phoenix-specific knowledge in generic data structure compiler
6. **False Positives**: Unrelated objects with matching field names get incorrect compilation

## ✅ The Solution: Context-Aware Detection

### Robust Architecture Pattern

Instead of guessing based on field names, **detect the compilation context**:

```haxe
// ✅ ROBUST APPROACH: Context-aware detection
private function isInPhoenixContext(): Bool {
    // Check if current class has Phoenix annotations
    var currentClass = compiler.getCurrentClass();
    if (currentClass != null) {
        // LiveView classes should use atom keys for assigns
        if (currentClass.meta.has(":liveview")) {
            return true;
        }
        
        // Schema classes for Ecto changesets use atom keys
        if (currentClass.meta.has(":schema")) {
            return true;
        }
    }
    
    // Check if current function suggests Phoenix context
    var currentFunction = compiler.getCurrentFunction();
    if (currentFunction != null) {
        var functionName = currentFunction.name;
        
        // LiveView lifecycle functions use atom keys
        var liveViewFunctions = ["mount", "handle_event", "handle_info", "handle_params", "render"];
        if (liveViewFunctions.indexOf(functionName) != -1) {
            return true;
        }
    }
    
    // Default: not in Phoenix context
    return false;
}
```

### Why This is Architecturally Sound

1. **Semantic Understanding**: Compiler understands *what* it's compiling, not just field names
2. **Annotation-Driven**: Uses explicit developer intent via `@:liveview`, `@:schema` annotations
3. **Function Context**: Recognizes Phoenix lifecycle functions automatically
4. **Maintainable**: Adding new Phoenix patterns doesn't require field name lists
5. **Scalable**: Works for any user-defined fields in Phoenix contexts
6. **Framework Agnostic**: Core logic remains clean, Phoenix knowledge is contextual
7. **No False Positives**: Only applies to actual Phoenix contexts

## 🏗️ Architectural Principles Learned

### 1. **Context Over Content**
```haxe
// ❌ BAD: Analyze content to guess context
if (hasFieldsLike("todos", "user", "session")) {
    // Probably Phoenix...
}

// ✅ GOOD: Use explicit context information
if (classHasAnnotation(":liveview")) {
    // Definitively Phoenix LiveView
}
```

### 2. **Semantic Understanding Over Pattern Matching**
```haxe
// ❌ BAD: Magic pattern matching
if (fieldCount >= 3 && containsCommonNames(fields)) {
    // Guess the use case...
}

// ✅ GOOD: Semantic context detection
if (isInPhoenixLifecycleFunction()) {
    // Semantic understanding of context
}
```

### 3. **Developer Intent Over Heuristics**
```haxe
// ❌ BAD: Heuristic guessing
if (looksLikePhoenixAssign(fields)) {
    // Compiler makes assumptions...
}

// ✅ GOOD: Explicit developer annotations
@:liveview // Developer explicitly declares intent
class TodoLive {
    // Compiler respects explicit intent
}
```

## 📋 Decision Framework for Future Compiler Features

When implementing new compilation patterns, ask these questions:

### ✅ Context-Aware Approach Indicators
- Can I detect this using existing annotations?
- Does the function/class context provide semantic information?
- Am I using developer-provided metadata?
- Will this work for any user-defined names/patterns?
- Is the detection based on *what* the code is trying to do?

### ❌ Hardcoded Pattern Warning Signs
- Am I creating lists of expected names/patterns?
- Do I need to update the compiler when users add new fields?
- Am I using "magic numbers" for thresholds?
- Am I guessing based on naming conventions?
- Is the detection based on *how* the code looks?

## 🎯 Implementation Guidelines

### For New Compiler Features

1. **Start with Context**: What semantic information is available?
   - Class annotations (`@:liveview`, `@:schema`, etc.)
   - Function names and contexts
   - Compilation phase information
   - Parent class/module information

2. **Use Explicit Intent**: How can developers declare their intent?
   - Add new annotations for new patterns
   - Use existing Haxe metadata systems
   - Respect developer-provided configuration

3. **Avoid Heuristics**: Don't guess what the developer meant
   - No "looks like Phoenix" detection
   - No threshold-based pattern matching
   - No hardcoded name lists

4. **Test Edge Cases**: Ensure robustness
   - User-defined field names
   - Mixed contexts (Phoenix + non-Phoenix in same file)
   - Evolution of framework patterns over time

### Code Review Checklist

When reviewing compiler code, reject patterns that show:
- [ ] Hardcoded lists of expected names/patterns
- [ ] Magic number thresholds for detection
- [ ] Content-based guessing instead of context detection
- [ ] Framework-specific assumptions in generic compilers
- [ ] Pattern matching without semantic understanding

Accept patterns that demonstrate:
- [x] Annotation-based context detection
- [x] Semantic understanding of compilation context
- [x] Explicit developer intent recognition
- [x] Framework-agnostic core with contextual specialization
- [x] Robust detection that works for any user naming

## 📚 Related Documentation

- **[DataStructureCompiler.hx](/src/reflaxe/elixir/helpers/DataStructureCompiler.hx)** - Implementation example of context-aware detection
- **[Framework Integration Patterns](/docs/claude-includes/framework-integration.md)** - Annotation-driven framework integration
- **[Compiler Architecture](/docs/03-compiler-development/architecture.md)** - Overall compiler design principles

## 🏆 Success Metrics

This architectural approach provides:

1. **Maintainability**: No compiler updates needed for new Phoenix field names
2. **Reliability**: Zero false positives from unrelated objects with similar field names  
3. **Scalability**: Works for any Phoenix pattern, not just hardcoded ones
4. **Developer Experience**: Respects explicit annotations and semantic context
5. **Framework Evolution**: Adapts to Phoenix changes without compiler modifications

## 💡 Key Takeaway

**Context-aware compilation uses semantic understanding and explicit developer intent, while hardcoded patterns rely on content analysis and heuristic guessing.**

The former creates robust, maintainable compilers. The latter creates brittle technical debt that breaks as applications evolve.

**Always detect context, never hardcode patterns.**

## 🔍 Phoenix API Validation Lesson

### The Problem: Incorrect API Assumptions

During Phoenix LiveView integration, we discovered that our standard library was calling non-existent functions:

```haxe
// ❌ WRONG: Assumed API that doesn't exist
@:native("Phoenix.LiveView.assign")  // Phoenix.LiveView has NO assign functions!
static function assign<TAssigns>(socket: Socket<TAssigns>, key: String, value: Any): Socket<TAssigns>;
```

**Runtime Error**: `Phoenix.LiveView.assign/2 is undefined or private`

### The Investigation Process

When runtime errors occurred, we validated against the actual Phoenix source code:

```bash
# Search Phoenix.LiveView module for assign functions
grep -n "def assign" /path/to/phoenix_live_view/lib/phoenix_live_view.ex
# Result: [] (empty - no assign functions exist!)

# Search Phoenix.Component module for assign functions  
grep -n "def assign" /path/to/phoenix_live_view/lib/phoenix_component.ex
# Result: Multiple assign function definitions found!
```

### The Root Cause

**Phoenix's delegation pattern was misunderstood**:

```
Expected:   User Code → Phoenix.LiveView.assign/2 ❌
Actual:     User Code → Phoenix.Component.assign/2 → Phoenix.LiveView.Utils.assign/2 ✅
```

Phoenix.LiveView **has zero assign functions** - they're all implemented in Phoenix.Component which then delegates to Phoenix.LiveView.Utils internally.

### The Fix

```haxe
// ✅ CORRECT: Use the actual API that exists
@:native("Phoenix.Component.assign")  // The correct module that has assign functions!
static function assign<TAssigns>(socket: Socket<TAssigns>, key: String, value: Any): Socket<TAssigns>;

@:native("Phoenix.Component.assign")  
static function assign_multiple<TAssigns>(socket: Socket<TAssigns>, assigns: TAssigns): Socket<TAssigns>;

@:native("Phoenix.Component.assign_new")
static function assign_new<TAssigns, TValue>(socket: Socket<TAssigns>, key: String, defaultFunction: Void -> TValue): Socket<TAssigns>;
```

### API Validation Methodology

**Before implementing framework integrations:**

1. **Search actual framework source code** - Never assume based on module names
2. **Test function existence in framework console** - Verify APIs exist in IEx/Elixir
3. **Check framework documentation** - Official docs show correct usage patterns  
4. **Examine reference implementations** - Look at how the framework uses its own APIs

### Understanding @:native Annotations

The `@:native` annotation specifies the **Elixir function name**, not its arity:

```haxe
@:native("Phoenix.Component.assign")  // ✅ Generates: Phoenix.Component.assign(socket, key, value)
@:native("Phoenix.Component.assign/3") // ❌ Would generate incorrect calls
```

**Why no arity in @:native?**
- **Function reference**: `Phoenix.Component.assign/3` (includes arity for documentation)
- **Function call**: `Phoenix.Component.assign(socket, key, value)` (no arity in actual usage)
- The compiler generates **function calls**, not function references

### Phoenix Framework Architecture Patterns

**Key Discovery**: Phoenix often uses delegation patterns where:

1. **Public API modules** (like Phoenix.Component) provide user-facing functions
2. **Implementation modules** (like Phoenix.LiveView.Utils) handle the actual work  
3. **Namespace modules** (like Phoenix.LiveView) may have no functions, just types

**Always check the public API module first**, not the namespace module.

### Prevention Strategy for Future Framework Integration

#### Before Writing Standard Library Bindings:

1. **Validate function existence**:
   ```bash
   # Example validation commands
   cd /path/to/framework/source
   grep -r "def assign" lib/
   grep -r "def assign_new" lib/  
   ```

2. **Test in framework console**:
   ```elixir
   # In IEx
   Phoenix.LiveView.__info__(:functions)    # Check what functions exist
   Phoenix.Component.__info__(:functions)   # Compare with expected location
   ```

3. **Document unexpected API locations**:
   ```haxe
   /**
    * ARCHITECTURAL NOTE: This maps to Phoenix.Component.assign/3, not Phoenix.LiveView.assign/3.
    * Phoenix.LiveView module has no assign functions - they're implemented in Phoenix.Component
    * which delegates to Phoenix.LiveView.Utils.assign/3 internally.
    */
   @:native("Phoenix.Component.assign")
   static function assign<TAssigns>(socket: Socket<TAssigns>, key: String, value: Any): Socket<TAssigns>;
   ```

#### API Change Detection:

- **Add compilation tests** that verify generated function calls match actual framework APIs
- **Include framework version compatibility** in documentation  
- **Monitor for deprecation warnings** in generated code compilation

### Related Framework Integration Patterns

This lesson applies broadly to framework integration:

- **Phoenix.PubSub** - Functions are in Phoenix.PubSub, not in a sub-module
- **Ecto.Changeset** - Functions are in Ecto.Changeset, not Ecto.Schema  
- **GenServer** - Callbacks vs client functions have different module locations

**Always validate API locations empirically, never assume based on logical naming.**

## 🔄 Variable Scoping Paradigm Bridging

### The Problem: Haxe vs Elixir Variable Scoping Rules

When transpiling from Haxe (imperative language) to Elixir (functional language), a critical paradigm bridging issue emerges with **variable scoping in conditional expressions**.

#### The Haxe Pattern
```haxe
// Haxe: Imperative variable assignment in conditionals
var tempArray;
if (config != null) {
    tempArray = [config];
} else {
    tempArray = [];
}
args = tempArray;  // tempArray is available in outer scope
```

#### The Naive Elixir Translation (BROKEN)
```elixir
# ❌ WRONG: Inline if expressions don't bind variables to outer scope
if (config != nil), do: temp_array = [config], else: temp_array = []
args = temp_array  # ERROR: Variable 'temp_array' is undefined!
```

#### The Problem Explanation
**Elixir's inline if expressions** (`if condition, do: value, else: value`) treat variable assignments as **expression results**, not as **side effects that persist in the outer scope**.

This means:
- `if condition, do: var = value` → Assignment happens inside the expression
- The variable `var` is NOT available outside the if expression
- This breaks Haxe's imperative variable assignment semantics

#### The Correct Elixir Translation
```elixir
# ✅ CORRECT: Block-style if statements allow variable binding in outer scope
if (config != nil) do
  temp_array = [config]
else
  temp_array = []
end
args = temp_array  # ✅ temp_array is properly bound to outer scope
```

### The Compiler Solution: Assignment Detection

The fix requires detecting **assignments within if expressions** and forcing **block-style compilation**:

```haxe
/**
 * PARADIGM BRIDGING: Variable scoping detection
 * 
 * WHY: Elixir inline if expressions don't bind variables to outer scope
 * WHAT: Detect TBinop(OpAssign) patterns that require block-style if statements  
 * HOW: Force block compilation when assignments are present
 */
private function isSimpleExpression(expr: TypedExpr): Bool {
    return switch (expr.expr) {
        case TBinop(OpAssign, _, _): false;      // ⚠️ CRITICAL: Assignments need block-style if
        case TConst(_): true;                    // Constants are simple
        case TLocal(_): true;                    // Variable references are simple
        case _: /* other simple patterns */
    };
}
```

### Pattern Recognition: When This Matters

This paradigm bridging issue appears when:

1. **Conditional variable assignment**: `if (cond) var = value`
2. **Ternary-like patterns**: `var = condition ? value1 : value2` 
3. **Switch expression results**: `var = switch(x) { case A: value1; case B: value2; }`
4. **Temporary variable optimization**: Any temp variable assignment within conditions

### Architecture Lesson: Semantic vs Syntactic Differences

This demonstrates a **semantic difference** between languages, not just syntactic:

- **Haxe semantics**: All assignments create outer-scope bindings
- **Elixir semantics**: Only block statements create outer-scope bindings
- **Compiler responsibility**: Bridge the semantic gap transparently

### Real-World Impact: TypeSafeChildSpecTools

This issue was discovered in `TypeSafeChildSpecTools.ex`:
```elixir
# Generated (broken):
if (((config != nil))), do: temp_array = [config], else: temp_array = []
args = temp_array  # undefined variable error!

# Fixed (working):  
if (config != nil) do
  temp_array = [config]
else
  temp_array = []
end
args = temp_array  # ✅ works correctly
```

### Prevention Strategy

**In ControlFlowCompiler.compileIfExpression():**

1. **Always check for assignments** before choosing inline vs block compilation
2. **Use block-style for any TBinop(OpAssign)** patterns
3. **Preserve inline form only for pure value expressions** (no side effects)
4. **Document the WHY** - this is paradigm bridging, not a preference

### Related Patterns

This paradigm bridging pattern affects:
- **Loop variable assignments**: Similar scoping issues in while/for loops
- **Match expression results**: Pattern matching with variable binding
- **Exception handling**: Variable scoping in try/rescue blocks
- **Lambda variable capture**: Closure variable binding rules

### Architecture Principle: Language Semantic Preservation

**Core Principle**: The transpiler must preserve the **semantic intent** of the source language, even when target language syntax differs.

- **Haxe intent**: Variable assignment with outer scope binding
- **Elixir implementation**: Use block statements to achieve same semantic effect
- **Developer experience**: Variables work exactly as expected from Haxe perspective

**This is not a bug fix - it's semantic preservation across language paradigms.**