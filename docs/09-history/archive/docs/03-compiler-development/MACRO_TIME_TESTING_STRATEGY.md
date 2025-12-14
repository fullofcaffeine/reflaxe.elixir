# How Reflaxe.Elixir Tests Macro-Time Code

## The Challenge

ElixirCompiler and its helpers only exist at macro-time (during Haxe compilation). How do we test them?

## The Solution: Three-Layer Testing Strategy

### Layer 1: Integration Testing via Mix (PRIMARY) ✅

**This is where the real testing happens!**

```elixir
# test/mix_integration_test.exs
test "compiler generates correct Elixir" do
  # 1. Create Haxe source files
  File.write!("src_haxe/User.hx", haxe_code)
  
  # 2. Run the ACTUAL Haxe compiler
  # ElixirCompiler runs AT MACRO-TIME here!
  {:ok, files} = Mix.Tasks.Compile.Haxe.run([])
  
  # 3. Verify the generated Elixir
  generated = File.read!("lib/User.ex")
  assert generated =~ "defmodule User"
end
```

**Key Point**: When Mix.Tasks.Compile.Haxe.run() executes `npx haxe build.hxml`, the ElixirCompiler runs at macro-time and generates Elixir files. We then verify those files.

### Layer 2: Example Compilation Tests ✅

```haxe
// SimpleExampleTest.hx
var exitCode = Sys.command("npx", ["haxe", "build.hxml"]);
// ElixirCompiler runs at macro-time during this command!

if (exitCode == 0) {
    trace("✅ Compilation succeeded");
}
```

Running `npm test:examples`:
- Compiles 9 different example projects
- Each compilation runs ElixirCompiler at macro-time
- Verifies successful compilation (exit code 0)

### Layer 3: Runtime Pattern Testing (Mocks) ✅

```haxe
// PatternMatchingTestUTest.hx
function testSwitch() {
    #if macro
    // DEAD CODE - Documents what we're testing
    var compiler = new ElixirCompiler();
    var result = compiler.compileExpression(switchExpr);
    #else
    // ACTUAL TEST - Validates output patterns
    var result = mockCompileSwitch();
    Assert.isTrue(result.contains("case x do"));
    #end
}
```

**Purpose**: Validates that the patterns we expect are correct, even though we can't run the actual compiler at test runtime.

## Why Not Test at Macro-Time Directly?

We COULD use utest.MacroRunner:

```haxe
class MacroTest {
    static function main() {
        #if macro
        utest.MacroRunner.run(CompilerTest);  // Runs at compile-time!
        #end
    }
}
```

But we don't because:
1. **Integration tests are better** - They test the full pipeline
2. **Harder to debug** - Compile-time failures are cryptic
3. **Current approach works well** - Mix tests catch real issues

## The Testing Flow

```
1. Developer writes Haxe code
           ↓
2. npm test runs:
   a. test:haxe - Runtime pattern tests with mocks
   b. test:examples - Compiles 9 examples (ElixirCompiler runs here!)
   c. test:mix - Mix integration tests (ElixirCompiler runs here!)
           ↓
3. ElixirCompiler executes AT MACRO-TIME in steps 2b and 2c
           ↓
4. Generated Elixir files are validated
```

## Summary

**Q: How do we test macro-time entities?**

**A: By running the actual compiler during tests!**

- Mix tests create .hx files and compile them
- Example tests compile real projects
- The ElixirCompiler ACTUALLY RUNS at macro-time during these tests
- We verify the generated output files

The Pattern test mocks are just for validating output patterns when we can't run the compiler (like in unit tests). The REAL testing happens when we actually compile Haxe code and check the generated Elixir.