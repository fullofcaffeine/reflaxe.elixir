# Bootstrap Code Generation for Standalone Scripts

## Overview

Reflaxe.Elixir automatically generates bootstrap code for classes with static `main()` functions, allowing standalone scripts to auto-execute when run with the Elixir command. This feature bridges the gap between Haxe's entry point convention and Elixir's script execution model.

## How It Works

When the compiler detects a class with a static `main()` function, it automatically adds a module-level call to execute that function after the module definition:

### Haxe Input
```haxe
class MyScript {
    static function main() {
        trace("Hello, World!");
    }
}
```

### Generated Elixir Output
```elixir
defmodule MyScript do
  def main() do
    IO.puts("Hello, World!")
  end
end
MyScript.main()  # <-- Bootstrap code auto-generated
```

### Running the Script
```bash
# Compile Haxe to Elixir
npx haxe -cp src -cp std -lib reflaxe --macro reflaxe.elixir.CompilerInit.Start() MyScript

# Execute directly with Elixir
elixir my_script.ex
# Output: Hello, World!
```

## Key Features

### Automatic Detection
- The compiler automatically detects static `main()` functions
- No annotations or special configuration required
- Works with any class name, not just "Main"

### Public Visibility
- `main()` is always generated as `def` (public), even if marked private in Haxe
- This ensures the bootstrap code can call it from module level

### Smart Exclusions
The bootstrap code is NOT added for:
- **Classes with `@:application` annotation** - OTP applications manage their own startup via supervision trees
- **Classes without static main()** - Only static methods trigger bootstrap
- **Instance methods named main()** - Must be static to qualify as entry point

## Use Cases

### Command-Line Scripts
```haxe
class CLITool {
    static function main() {
        var args = Sys.args();
        switch (args[0]) {
            case "help": showHelp();
            case "version": showVersion();
            default: processCommand(args);
        }
    }
}
```

### Data Processing Scripts
```haxe
class DataProcessor {
    static function main() {
        var input = File.getContent("input.csv");
        var processed = processData(input);
        File.saveContent("output.json", processed);
        trace("Processing complete!");
    }
}
```

### Quick Testing Scripts
```haxe
class TestRunner {
    static function main() {
        trace("Running tests...");
        testFeatureA();
        testFeatureB();
        trace("All tests passed!");
    }
}
```

## Integration with OTP Applications

### @:application Classes (No Bootstrap)
```haxe
@:application
class MyApp {
    static function main() {
        // This won't get bootstrap code
        // OTP manages startup via Application behavior
    }
    
    public function start(type, args) {
        // OTP entry point
        var children = [...];
        Supervisor.start_link(children, opts);
    }
}
```

### Why No Bootstrap for Applications?
- OTP applications have their own startup mechanism via `mix run` or releases
- The Application behavior handles initialization
- Bootstrap would interfere with supervision tree startup

## Migration from Manual Bootstrap

### Before (Manual Bootstrap Required)
```haxe
// Haxe code
class Script {
    static function main() {
        doWork();
    }
}

// Had to manually add in generated Elixir:
// Script.main()
```

### After (Automatic Bootstrap)
```haxe
class Script {
    static function main() {
        doWork();
    }
}
// Bootstrap automatically added by compiler!
```

## Debugging Bootstrap Generation

### Enable Debug Traces
```bash
# Compile with bootstrap debugging enabled
npx haxe build.hxml -D debug_bootstrap

# Output will show:
# [ModuleBuilder] Checking statics for class MyScript
# [ModuleBuilder] Found static field: main
# [ModuleBuilder] Adding bootstrap code for static main() in MyScript
# [ModuleBuilder] Bootstrap code added after module for MyScript
```

### Verify Generated Code
```bash
# Check the generated Elixir file
cat my_script.ex | tail -1
# Should show: MyScript.main()
```

## Technical Implementation

### AST Structure
The bootstrap code is implemented as an `ECall` AST node:
```haxe
// In ModuleBuilder.hx
var bootstrapCode = makeAST(
    ECall(
        null,  // No receiver (module-level call)
        moduleName + ".main",  // e.g., "MyScript.main"
        []  // No arguments
    )
);
```

### Module Wrapping
The module and bootstrap are wrapped in an `EBlock`:
```haxe
moduleAST = makeAST(EBlock([moduleAST, bootstrapCode]));
```

This generates:
```elixir
defmodule MyScript do
  # ... module contents ...
end
MyScript.main()
```

## Best Practices

### Keep main() Simple
```haxe
class App {
    static function main() {
        // Just initialization and delegation
        var config = loadConfig();
        var app = new App(config);
        app.run();
    }
}
```

### Handle Errors Gracefully
```haxe
class Script {
    static function main() {
        try {
            performWork();
        } catch (e:Dynamic) {
            trace('Error: $e');
            Sys.exit(1);
        }
    }
}
```

### Use for Scripts, Not Libraries
- Bootstrap is for executable scripts
- Libraries should not have main() functions
- Use @:application for OTP applications

## Compatibility

### Works With
- ✅ Standalone scripts
- ✅ Command-line tools
- ✅ Data processing scripts
- ✅ Test runners
- ✅ Mix tasks (when run directly)

### Does Not Work With
- ❌ OTP applications (use @:application)
- ❌ Phoenix applications (use Application behavior)
- ❌ Library modules (no entry point needed)
- ❌ GenServer modules (use callbacks)

## FAQ

**Q: Can I have multiple classes with main() in one project?**
A: Yes, but only compile one at a time as the entry point. Each generates its own bootstrap.

**Q: What if I don't want bootstrap code?**
A: Either rename your function from `main()` or add `@:application` annotation.

**Q: Can main() take arguments?**
A: No, use `Sys.args()` to access command-line arguments inside main().

**Q: Does this work with async main()?**
A: Yes, the bootstrap just calls the function. Async behavior is handled by Elixir runtime.

## See Also
- [Module Building Architecture](../03-compiler-development/architecture.md#module-builder)
- [OTP Application Support](otp-applications.md)
- [Phoenix Applications](phoenix-integration.md)