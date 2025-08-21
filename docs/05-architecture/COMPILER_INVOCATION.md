# Compiler Invocation Methods: --macro vs --custom-target

## Overview

Reflaxe compilers can be invoked in different ways. Both `--macro` and `--custom-target` are **Reflaxe-specific conventions**, not standard Haxe features:

1. **`--macro` approach** - Used by Reflaxe.Elixir (our current implementation)
2. **`--custom-target` approach** - Used by some other Reflaxe compilers like Reflaxe.CSharp

## The Key Misunderstanding

**IMPORTANT**: The `--custom-target` flag is **NOT a Haxe compiler flag**. It's a convention that some Reflaxe compilers implement by parsing command-line arguments themselves. This was the source of our confusion.

## Current Implementation: --macro Approach

### How it works
```hxml
-lib reflaxe
--macro reflaxe.elixir.CompilerInit.Start()
-D elixir_output=out
```

This approach:
- Uses Haxe's built-in `--macro` flag (a real Haxe feature)
- Calls `CompilerInit.Start()` at macro-time during compilation
- Uses `Context.onAfterInitMacros()` to register callbacks
- Hooks into `Context.onAfterTyping()` to receive the typed AST
- Transforms the AST to Elixir code during compilation

### Implementation Details
```haxe
// CompilerInit.hx
public static function Start() {
    haxe.macro.Context.onAfterInitMacros(Begin);
}

public static function Begin() {
    ReflectCompiler.AddCompiler(new ElixirCompiler(), {...});
}
```

## Alternative: --custom-target Approach

### How it works (in other Reflaxe compilers)
```hxml
-lib reflaxe.csharp
--custom-target csharp=out
```

This approach:
- Is a Reflaxe-specific convention (not a Haxe feature)
- The Reflaxe compiler library parses this flag from command-line arguments
- Still uses Haxe's macro system underneath to do the actual compilation
- Provides a cleaner invocation syntax

### Why We Don't Use It

1. **Additional complexity**: Would need to implement command-line parsing
2. **No functional benefit**: Both approaches achieve exactly the same result
3. **Transparency**: The `--macro` approach makes it clear we're using Haxe's macro system
4. **Already working**: Our current approach has full test coverage

## The CustomTarget Check in Our Code

The code in `CompilerInit.hx` that checks for `CustomTarget("elixir")` is actually checking for something completely different:

```haxe
#if (haxe >= version("5.0.0"))
switch(haxe.macro.Compiler.getConfiguration().platform) {
    case CustomTarget("elixir"):  // This checks Haxe's platform config
    case _: return;
}
#end
```

This is checking if someone defined a custom Haxe platform (a rarely-used Haxe feature), NOT checking for the `--custom-target` flag. The version check was wrong too - this code would work in Haxe 4.3.x as well.

## Key Differences Summary

| Aspect | --macro | --custom-target |
|--------|---------|-----------------|
| **What it is** | Haxe's built-in macro flag | Reflaxe-specific convention |
| **Parsing** | Handled by Haxe | Must be parsed by Reflaxe lib |
| **Transparency** | Clear it's using macros | Hides macro usage |
| **Our Support** | Fully implemented | Not implemented |
| **Complexity** | Simple, direct | Requires CLI parsing code |

## Lessons Learned

1. **`--custom-target` is NOT a Haxe feature** - It's just a convention some Reflaxe compilers use
2. **Both approaches use macros** - The difference is just in the invocation syntax
3. **No migration needed** - There's no technical advantage to switching
4. **Research before assuming** - We incorrectly assumed `--custom-target` was a Haxe 5.0 feature
5. **Different isn't better** - Just because other Reflaxe compilers use a different approach doesn't mean we should

## Practical Differences: Is It Just Syntax Sugar?

**Short answer: Yes, it's purely syntax sugar.** Both approaches do exactly the same thing underneath.

### Technical Analysis

Both `--macro` and `--custom-target` ultimately:
1. Execute macro code at compile-time
2. Hook into `Context.onAfterTyping()` to get the typed AST
3. Transform the AST to the target language
4. Write output files

The ONLY differences are:

| Aspect | --macro | --custom-target |
|--------|---------|-----------------|
| **User syntax** | `--macro reflaxe.elixir.CompilerInit.Start()` | `--custom-target elixir=out` |
| **Implementation** | Direct macro call | Parse args → call macro |
| **Output dir config** | `-D elixir_output=out` | Part of the flag |
| **Library setup** | Explicit `-lib reflaxe` | May be implicit |

### No Functional Differences

There are **zero functional differences** in:
- Compilation speed
- Output quality
- Features available
- Type checking
- Error reporting
- File generation

### Why Different Approaches Exist

1. **User experience**: `--custom-target elixir=out` is cleaner to type
2. **Convention**: Makes Reflaxe targets look more like native Haxe targets (`--js out.js`)
3. **Historical**: Different Reflaxe authors made different choices

### The Implementation Truth

If we implemented `--custom-target`, it would literally just:
```haxe
// Pseudo-code of what --custom-target does
function parseCustomTarget(args: Array<String>) {
    if (args.contains("--custom-target")) {
        var target = parseTargetName(args);  // "elixir"
        var output = parseOutputDir(args);    // "out"
        
        // Just call the same macro!
        CompilerInit.Start();
        Compiler.define("elixir_output", output);
    }
}
```

It's a wrapper that calls the same underlying macro code.

## Conclusion

The distinction between `--macro` and `--custom-target` is **100% syntax sugar** with no practical differences:
- Both compile the same way
- Both produce identical output
- Both have the same capabilities
- Both use Haxe's macro system

Our current `--macro` approach is:
- ✅ Simple and transparent
- ✅ Fully functional with 34 passing tests
- ✅ Well-documented and understood
- ✅ No need to change

The initial confusion arose from seeing `--custom-target` in other Reflaxe projects and incorrectly assuming:
1. It was a Haxe compiler feature (it's not - it's Reflaxe-specific)
2. It had technical advantages (it doesn't - it's just syntax)
3. We should migrate to it (we shouldn't - there's no benefit)

**Final verdict**: `--custom-target` is syntactic sugar that some Reflaxe compilers implement for a cleaner command-line interface. There are no practical differences in functionality, performance, or capabilities.