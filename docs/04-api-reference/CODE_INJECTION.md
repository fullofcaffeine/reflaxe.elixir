# Code Injection - Emergency Use Only ⚠️

## ⛔ CRITICAL WARNING

**`__elixir__()` is an EMERGENCY ESCAPE HATCH, not a development tool.**

This feature exists but should **NEVER** be used in production code, examples, or demos.

## The Philosophy

Code injection (`__elixir__()`) fundamentally undermines the core value proposition of Reflaxe.Elixir:
- **Breaks type safety** - No compile-time checking
- **Destroys portability** - Code becomes Elixir-specific
- **Hides complexity** - Makes code harder to understand
- **Creates technical debt** - Every use needs future removal
- **Sets bad precedent** - Encourages shortcuts over proper solutions

## When NOT to Use (99.99% of cases)

### ❌ NEVER Use For:

1. **Accessing Phoenix functions**
   ```haxe
   // ❌ WRONG - Using code injection
   __elixir__("Phoenix.PubSub.broadcast({0}, {1}, {2})", pubsub, topic, msg);
   
   // ✅ RIGHT - Using extern
   @:native("Phoenix.PubSub")
   extern class PubSub {
       static function broadcast(pubsub: Dynamic, topic: String, msg: Dynamic): Dynamic;
   }
   PubSub.broadcast(pubsub, topic, msg);
   ```

2. **Working around missing features**
   ```haxe
   // ❌ WRONG - Quick hack
   __elixir__("Enum.chunk_every({0}, {1})", list, size);
   
   // ✅ RIGHT - Implement proper abstraction
   class EnumExt {
       public static function chunkEvery<T>(list: Array<T>, size: Int): Array<Array<T>> {
           // Proper implementation
       }
   }
   ```

3. **Quick fixes**
   ```haxe
   // ❌ WRONG - Bypass type system
   __elixir__("Map.merge({0}, {1})", map1, map2);
   
   // ✅ RIGHT - Use Haxe's Map
   var merged = map1.copy();
   for (key => value in map2) {
       merged.set(key, value);
   }
   ```

4. **In examples or demos**
   ```haxe
   // ❌ WRONG - Sets terrible example
   class TodoExample {
       function demo() {
           __elixir__("IO.inspect({0})", data);
       }
   }
   
   // ✅ RIGHT - Show proper patterns
   class TodoExample {
       function demo() {
           trace(data); // or use proper logging
       }
   }
   ```

5. **Testing workarounds**
   ```haxe
   // ❌ WRONG - Hide test failures
   __elixir__("Process.sleep({0})", 1000);
   
   // ✅ RIGHT - Fix the actual timing issue
   // Or use proper async testing patterns
   ```

## When It MIGHT Be Acceptable (0.01% of cases)

### ⚠️ Emergency Situations Only:

1. **Compiler debugging during development**
   ```haxe
   // EMERGENCY: Using __elixir__ for compiler debugging only
   // TODO: Remove before commit
   // Justification: Need to inspect macro-generated AST
   #if debug
   __elixir__("IO.inspect({0}, label: \"AST\")", ast);
   #end
   ```

2. **Critical production hotfix**
   ```haxe
   // EMERGENCY: Temporary hotfix for production issue #1234
   // TODO: Replace with proper GenServer implementation by 2024-01-15
   // Justification: GenServer extern not yet implemented, blocking production
   // Approved by: TeamLead on 2024-01-08
   __elixir__("GenServer.call({0}, {:emergency_fix, {1}})", server, data);
   ```

3. **Proving concept before implementation**
   ```haxe
   // PROOF OF CONCEPT: Testing if Elixir feature works
   // TODO: Implement proper abstraction in next sprint
   // Justification: Validating approach before investing in full implementation
   // Delete by: 2024-02-01
   __elixir__("experimental_feature({0})", testData);
   ```

## Required Documentation

### Any `__elixir__()` use MUST include:

```haxe
// EMERGENCY: Using __elixir__ because [specific technical reason]
// TODO: Replace with [specific solution] by [specific date]
// Justification: [why no other option works right now]
// Approved by: [who approved this technical debt]
// Ticket: [issue tracking removal]
__elixir__("emergency_code_here", args);
```

### Documentation Requirements:

1. **EMERGENCY label** - Makes it searchable
2. **TODO with solution** - Not just "fix later"
3. **Specific date** - Creates accountability
4. **Justification** - Must be technical, not convenience
5. **Approval** - Someone takes responsibility
6. **Tracking ticket** - Ensures it gets fixed

## The Correct Approach

### 1. Use Extern Definitions

```haxe
// Define extern for existing Elixir module
@:native("ElixirModule")
extern class ElixirModule {
    static function someFunction(arg: String): Int;
}

// Use it type-safely
var result = ElixirModule.someFunction("test");
```

### 2. Implement Proper Abstractions

```haxe
// Create Haxe abstraction
abstract TaskSupervisor(Dynamic) {
    public function new(options: Dynamic) {
        this = Supervisor.startLink([], options);
    }
    
    public function startChild(spec: Dynamic): Dynamic {
        return Supervisor.startChild(this, spec);
    }
}
```

### 3. Extend Standard Library

```haxe
// Add to std/ directory
package elixir;

class Process {
    public static function sleep(ms: Int): Void {
        // Proper implementation
    }
}
```

### 4. Use Compile-Time Macros

```haxe
// Build macro for code generation
class ElixirMacro {
    macro public static function defmodule(name: String, body: Expr) {
        // Generate proper module structure
    }
}
```

## Detection and Prevention

### Automated Detection

1. **Linting Rules**
   ```bash
   # .reflaxe/lint.yml
   forbidden_patterns:
     - pattern: "__elixir__"
       severity: error
       message: "Code injection is forbidden"
   ```

2. **CI/CD Checks**
   ```yaml
   # .github/workflows/check.yml
   - name: Check for code injection
     run: |
       if grep -r "__elixir__" src/; then
         echo "ERROR: Code injection detected"
         exit 1
       fi
   ```

3. **Pre-commit Hooks**
   ```bash
   #!/bin/bash
   # .git/hooks/pre-commit
   if git diff --cached | grep "__elixir__"; then
       echo "ERROR: Remove __elixir__ before committing"
       exit 1
   fi
   ```

### Code Review Policy

- **Automatic rejection** of PRs containing `__elixir__()`
- **Exception process** requires architecture team approval
- **Removal plan** must be included in PR description
- **Follow-up ticket** must be created immediately

## Migration Path

### When you find `__elixir__()` in code:

1. **Understand the need**
   - What Elixir feature is being accessed?
   - Why wasn't it available in Haxe?

2. **Create proper solution**
   - Write extern definition
   - Or implement Haxe abstraction
   - Or extend standard library

3. **Test thoroughly**
   - Ensure type safety
   - Verify runtime behavior
   - Check edge cases

4. **Remove injection**
   - Replace with proper solution
   - Update documentation
   - Close tracking ticket

## Impact on Architecture

### Why This Matters:

1. **Type Safety** - Core value proposition
   - Every `__elixir__()` is a type hole
   - Defeats compile-time checking
   - Introduces runtime errors

2. **Portability** - Cross-platform promise
   - Code with `__elixir__()` only works on BEAM
   - Cannot compile to other targets
   - Breaks platform abstraction

3. **Maintainability** - Long-term health
   - Hidden dependencies
   - Unclear contracts
   - Technical debt accumulation

4. **Learning** - Sets precedent
   - New developers copy bad patterns
   - Encourages shortcuts
   - Degrades code quality

## Examples in todo-app

The todo-app demonstrates **ZERO** uses of `__elixir__()`:
- All Phoenix integration via externs
- All Ecto operations through typed APIs  
- All LiveView features with annotations
- All business logic in pure Haxe

This proves that real applications can be built without code injection.

## Alternatives Summary

| Need | Wrong (Injection) | Right (Proper Solution) |
|------|------------------|------------------------|
| Elixir module access | `__elixir__("Module.function(...)")` | Extern definition |
| Missing Haxe feature | `__elixir__("elixir_code")` | Implement in Haxe |
| Quick debugging | `__elixir__("IO.inspect(...)")` | Use trace() or logger |
| Framework integration | `__elixir__("Phoenix.thing")` | Phoenix externs |
| Testing helpers | `__elixir__("Process.sleep")` | Test framework features |

## Final Word

**Every `__elixir__()` is a failure of abstraction.**

Before using it, ask:
1. Have I tried extern definitions?
2. Can I implement this in Haxe?
3. Is this truly an emergency?
4. Who will remove this and when?
5. What's the real cost of this shortcut?

Remember: The goal is **elegant, type-safe code**, not quick hacks.

## Enforcement

This policy is enforced through:
- Automated CI/CD checks
- Code review requirements
- Linting rules
- Documentation standards
- Team culture

**Violations will be rejected automatically.**