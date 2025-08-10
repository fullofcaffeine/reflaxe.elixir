# Macro-Time Testing Analysis: utest vs tink_unittest

## Executive Summary
After analyzing the source code of both frameworks, I discovered that **utest DOES support macro-time testing** through `MacroRunner`, while tink_unittest doesn't have explicit macro-time test support. However, **our Reflaxe.Elixir tests never use macro-time testing** in either framework, and there's a good architectural reason for this.

## Key Findings

### 1. utest Has Macro-Time Support ✅
```haxe
// utest/MacroRunner.hx
class MacroRunner {
  #if macro
  public static function run(testClass : Any) {
    var runner = new Runner();
    addClass(runner, testClass);
    new MacroReport(runner);
    runner.run();
    return { expr: EConst(CType("Void")), pos: Context.currentPos() };
  }
  #end
}
```

**Usage Pattern**:
```haxe
class Main {
  static function main() {
    Main.runTests();
  }
  
  macro static function runTests() {
    return MacroRunner.run(new MyTestClass());
  }
}
```

### 2. tink_unittest Has No Explicit Macro-Time Support ❌
- Uses build macros (`@:build(tink.unit.TestBuilder.build())`) to generate test infrastructure
- All actual test execution happens at runtime via `Runner.run(TestBatch.make([...]))`
- No equivalent to utest's MacroRunner

### 3. Our Tests Never Use Macro-Time Testing 🎯

Despite having `#if macro` blocks in our test code, **these blocks never execute** because:

1. **We use runtime test runners**:
   ```haxe
   // UTestRunner.hx - Runs at RUNTIME
   class UTestRunner {
     static function main() {
       var runner = new Runner();
       runner.addCase(new SimpleTestUTest()); // Runtime instantiation
       runner.run(); // Runtime execution
     }
   }
   ```

2. **Our `#if macro` blocks are dead code**:
   ```haxe
   function testChangesetAnnotationDetection() {
     #if !(macro || reflaxe_runtime)
     // THIS ALWAYS RUNS - we're at runtime
     var result = ChangesetCompiler.isChangesetClass("UserChangeset");
     #else
     // THIS NEVER RUNS - would need MacroRunner
     var result = ChangesetCompiler.isChangesetClass("UserChangeset");
     #end
   }
   ```

## Why We Don't Use Macro-Time Testing

### 1. Compilation Context Isolation
Macro-time tests run during compilation, not after. They can't test the output of the compilation they're part of:

```
Compilation Phase 1: Macros run → Tests would run HERE
Compilation Phase 2: Reflaxe.Elixir transpiles
Compilation Phase 3: Output generated
Runtime: Normal tests run HERE (can verify output)
```

### 2. Practical Limitations
- **No access to generated files**: Macro-time tests can't read the .ex files that will be generated
- **No async support**: Many test features require runtime async handling
- **Limited debugging**: Macro context has different debugging capabilities
- **CI/CD complexity**: Most CI systems expect tests to run as a separate step

### 3. The Right Tool for the Job
Our current approach is actually correct:
- **Unit tests (with mocks)**: Test the logic/behavior contracts
- **Integration tests (Mix)**: Test the actual generated Elixir code

## Could We Use Macro-Time Testing?

Theoretically yes, but it would require restructuring:

```haxe
// Hypothetical macro-time test
class MacroTimeCompilerTest {
  macro public static function testCompiler() {
    // This WOULD have access to the real ChangesetCompiler
    var result = ChangesetCompiler.compileFullChangeset("Test", "User");
    
    // But we can only trace or fail compilation
    if (!result.contains("defmodule Test"))
      Context.error("Compiler test failed", Context.currentPos());
    
    return macro null;
  }
}
```

**Problems with this approach**:
1. Tests become part of compilation - failures break builds
2. No test reporting infrastructure (just compiler errors)
3. Can't test the final output (hasn't been generated yet)
4. Mixes concerns (testing vs building)

## Conclusion

1. **I was wrong**: The `#if macro` blocks in our tests ARE misleading - they never run
2. **utest could theoretically help**: It has MacroRunner for macro-time testing
3. **But we shouldn't use it**: Our current approach (runtime mocks + Mix integration tests) is the right pattern for testing a transpiler
4. **The confusion is understandable**: Seeing `#if macro` suggests macro testing, but it's actually just dead code

## Recommendations

1. **Remove misleading `#if macro` blocks** from tests - they create confusion
2. **Keep using runtime mocks** - they properly test behavior contracts
3. **Continue Mix integration tests** - they validate actual transpiler output
4. **Document this clearly** - Future developers need to understand why we use mocks

The current testing strategy is correct, even if the code structure is confusing!