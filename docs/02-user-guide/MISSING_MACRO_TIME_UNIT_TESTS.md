# The Missing Testing Layer: Macro-Time Unit Tests

## You're Right - This is a Gap!

A proper compiler testing strategy should have **four layers**, not three:

### Current Testing Layers ✅
1. **Integration Tests** (Mix) - Full pipeline testing
2. **Example Tests** - Real project compilation
3. **Runtime Pattern Tests** (Mocks) - Output validation

### Missing Layer ❌
4. **Macro-Time Unit Tests** - Direct component testing at compile-time

## Why This Gap Exists

### The TypedExpr Problem

ElixirCompiler works with `TypedExpr` (Haxe's typed AST), not `Expr` (untyped AST):

```haxe
// ElixirCompiler expects this:
function compileExpression(expr: TypedExpr): String

// But in macro tests we can only create:
var expr = macro var x = 1;  // This is Expr, not TypedExpr!
```

`TypedExpr` contains:
- Type information
- Resolved symbols
- Optimized AST structure

We can't easily create `TypedExpr` in tests - it's produced by Haxe's type checker.

## What Macro-Time Unit Tests SHOULD Look Like

```haxe
#if macro
class CompilerUnitTest {
    @Test
    function testVariableCompilation() {
        var compiler = new ElixirCompiler();
        var expr = createTypedVar("name", "String", "test");
        var result = compiler.compileExpression(expr);
        Assert.equals("name = \"test\"", result);
    }
    
    @Test
    function testPatternMatching() {
        var matcher = new PatternMatcher();
        var pattern = createTypedPattern(Switch(...));
        var result = matcher.compile(pattern);
        Assert.contains("case", result);
    }
    
    @Test  
    function testTypeMapping() {
        var typer = new ElixirTyper();
        Assert.equals("binary()", typer.mapType("String"));
        Assert.equals("list()", typer.mapType("Array<Dynamic>"));
        Assert.equals("%User{}", typer.mapType("User"));
    }
}
#end
```

These would run AT COMPILE TIME and test individual components.

## How to Implement This

### Option 1: Refactor for Testability ⭐ (Best)

Extract testable units that don't require TypedExpr:

```haxe
// Instead of:
class ElixirCompiler {
    function compileExpression(expr: TypedExpr): String { }
}

// Refactor to:
class ElixirCompiler {
    function compileExpression(expr: TypedExpr): String {
        var simplified = extractData(expr);
        return compiler.compile(simplified);
    }
}

class ExpressionCompiler {
    // Testable unit that works with simple data
    function compile(data: SimpleExprData): String { }
}
```

### Option 2: Use Context.typeExpr()

Convert untyped Expr to TypedExpr in tests:

```haxe
#if macro
function createTypedExpr(): TypedExpr {
    var expr = macro var x = 1;
    return Context.typeExpr(expr);  // Convert to TypedExpr
}
#end
```

But this is complex and may not work in all contexts.

### Option 3: Capture Real TypedExpr

Create a test harness that captures TypedExpr during compilation:

```haxe
#if macro
class TestCapture {
    static var capturedExprs: Array<TypedExpr> = [];
    
    public static function capture() {
        Context.onAfterTyping(function(types) {
            // Capture real TypedExpr for testing
            for (type in types) {
                capturedExprs.push(extractExpressions(type));
            }
        });
    }
}
#end
```

### Option 4: Use utest.MacroRunner

```haxe
class MacroTest {
    static function main() {
        #if macro
        utest.MacroRunner.run(CompilerUnitTest);
        #end
    }
}
```

## Why This Matters

Without macro-time unit tests:
1. **Can't test components in isolation** - Only integration tests
2. **Slow feedback loop** - Must compile full examples
3. **Hard to test edge cases** - Need complete valid programs
4. **Difficult debugging** - Errors show up in generated code, not component

## Recommendation

The project needs:

1. **Immediate**: Document this as technical debt
2. **Short-term**: Add testable extraction layer (Option 1)
3. **Long-term**: Full macro-time unit test suite

This would make the compiler:
- More maintainable
- Easier to debug
- Faster to develop
- More reliable

## Example Implementation Plan

```haxe
// Step 1: Create testable components
class PatternCompiler {
    public function compileSwitch(cases: Array<CaseData>): String {
        // Works with simple data, not TypedExpr
    }
}

// Step 2: Create macro-time tests
#if macro
class PatternCompilerTest {
    static function test() {
        var compiler = new PatternCompiler();
        var result = compiler.compileSwitch([...]);
        if (!result.contains("case")) {
            Context.error("Test failed!", Context.currentPos());
        }
    }
}
#end

// Step 3: Run tests during compilation
--macro test.PatternCompilerTest.test()
```

## Conclusion

You're absolutely right - a compiler without unit tests for its core components is incomplete. The current integration-only testing works but is not ideal. Adding macro-time unit tests would significantly improve the project's quality and maintainability.