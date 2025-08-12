# Troubleshooting Guide

This guide helps you resolve common issues when working with Reflaxe.Elixir. If you can't find your issue here, please [open an issue](https://github.com/fullofcaffeine/reflaxe.elixir/issues) on GitHub.

## Table of Contents
- [Installation Issues](#installation-issues)
- [Compilation Errors](#compilation-errors)
- [Runtime Errors](#runtime-errors)
- [Type System Issues](#type-system-issues)
- [Phoenix Integration Problems](#phoenix-integration-problems)
- [Performance Issues](#performance-issues)
- [IDE and Tooling Issues](#ide-and-tooling-issues)
- [Common Error Messages](#common-error-messages)
- [FAQ](#faq)

## Installation Issues

### Problem: "reflaxe.elixir not found" when running haxelib

**Symptom:**
```bash
$ haxelib run reflaxe.elixir create my-app
Error: Library reflaxe.elixir is not installed
```

**Solution:**
```bash
# Install via lix (recommended)
lix install github:fullofcaffeine/reflaxe.elixir

# Or install via haxelib
haxelib install reflaxe.elixir

# Verify installation
haxelib list | grep reflaxe
```

### Problem: "lix: command not found"

**Symptom:**
```bash
$ lix install reflaxe.elixir
bash: lix: command not found
```

**Solution:**
```bash
# Install lix globally
npm install -g lix

# Or locally in your project
npm install --save-dev lix

# If using local installation, use npx
npx lix install reflaxe.elixir
```

### Problem: Haxe version incompatibility

**Symptom:**
```
Error: Reflaxe.Elixir requires Haxe 4.3.0 or later
```

**Solution:**
```bash
# Check current Haxe version
haxe --version

# Update Haxe via lix
lix install haxe 4.3.6

# Or download from haxe.org
# https://haxe.org/download/
```

## Compilation Errors

### Problem: "Type not found" errors

**Symptom:**
```
src_haxe/Main.hx:3: characters 8-15 : Type not found : Product
```

**Possible Causes & Solutions:**

1. **Missing import statement:**
```haxe
// Add the import
import schemas.Product;
```

2. **File not in classpath:**
```hxml
# Add to build.hxml
-cp src_haxe
-cp src_haxe/schemas
```

3. **Circular dependency:**
```haxe
// Break circular dependencies by using interfaces
// or moving shared types to a separate module
```

### Problem: "Cannot access private field"

**Symptom:**
```
src_haxe/Service.hx:15: Cannot access private field getData
```

**Solution:**
```haxe
// Change field visibility
class DataProvider {
    // Change from private to public
    public function getData(): Array<String> {
        return data;
    }
}
```

### Problem: "Abstract type cannot be instantiated"

**Symptom:**
```
src_haxe/Main.hx:10: Abstract MyAbstract cannot be instantiated
```

**Solution:**
```haxe
// Use factory method or @:from
abstract MyAbstract(String) {
    // Add a factory method
    public static function create(value: String): MyAbstract {
        return cast value;
    }
    
    // Or use @:from
    @:from
    public static function fromString(s: String): MyAbstract {
        return cast s;
    }
}
```

### Problem: "@:module annotation required"

**Symptom:**
```
Error: Classes compiled to Elixir modules must have @:module annotation
```

**Solution:**
```haxe
// Add the annotation
@:module
class MyClass {
    // class implementation
}
```

## Runtime Errors

### Problem: "undefined function" in generated Elixir

**Symptom:**
```
** (UndefinedFunctionError) function MyModule.myFunction/1 is undefined
```

**Possible Causes & Solutions:**

1. **Function not compiled:**
```haxe
// Ensure function is public and static for module functions
@:module
class MyModule {
    public static function myFunction(arg: String): String {
        return arg;
    }
}
```

2. **Compilation not run:**
```bash
# Recompile Haxe to Elixir
npx haxe build.hxml

# Verify generated file exists
ls lib/generated/my_module.ex
```

3. **Mix compiler not configured:**
```elixir
# In mix.exs
def project do
  [
    compilers: [:haxe] ++ Mix.compilers(),
    # ...
  ]
end
```

### Problem: "no match of right hand side value"

**Symptom:**
```
** (MatchError) no match of right hand side value: {:error, :not_found}
```

**Solution:**
```haxe
// Handle all possible return values
var result = Database.find(id);
switch (result) {
    case {:ok, value}:
        return value;
    case {:error, reason}:
        // Handle error case
        throw new Error('Database error: $reason');
}
```

### Problem: "argument error" when calling Elixir functions

**Symptom:**
```
** (ArgumentError) argument error
```

**Solution:**
```haxe
// Check parameter types match Elixir expectations
// Haxe Int → Elixir integer
// Haxe Float → Elixir float
// Haxe String → Elixir binary
// Haxe Array → Elixir list

// Use proper type conversions
var elixirAtom = untyped :my_atom;
var elixirTuple = {ok: "value"}; // Creates {:ok, "value"}
```

## Type System Issues

### Problem: "Int should be String" type mismatch

**Symptom:**
```
src_haxe/Main.hx:20: Int should be String
```

**Solution:**
```haxe
// Use Std.string for conversion
var number: Int = 42;
var text: String = Std.string(number);

// Or use string interpolation
var message: String = 'The number is $number';
```

### Problem: "Array<T> has no field map"

**Symptom:**
```
src_haxe/Service.hx:25: Array<Product> has no field map
```

**Solution:**
```haxe
// Use Lambda for array operations
import Lambda;

var products: Array<Product> = getProducts();
var names = Lambda.map(products, p -> p.name);

// Or use for loop
var names = [for (p in products) p.name];
```

### Problem: Null safety issues

**Symptom:**
```
src_haxe/Service.hx:30: Null<String> should be String
```

**Solution:**
```haxe
// Handle null explicitly
var nullableValue: Null<String> = getNullable();

// Option 1: Null check
if (nullableValue != null) {
    var value: String = nullableValue;
    process(value);
}

// Option 2: Default value
var value: String = nullableValue ?? "default";

// Option 3: Throw on null
var value: String = nullableValue.sure();
```

## Phoenix Integration Problems

### Problem: LiveView not updating

**Symptom:**
LiveView component renders but doesn't respond to events.

**Solution:**
```haxe
@:liveview
class MyLive {
    // Ensure handleEvent returns the socket
    public function handleEvent(event: String, params: Dynamic, socket: Socket): Socket {
        return switch (event) {
            case "click":
                // Must return the socket
                socket.assign("clicked", true);
            default:
                socket; // Always return socket
        };
    }
}
```

### Problem: "assign @products not available in eex template"

**Symptom:**
```
** (ArgumentError) assign @products not available in eex template
```

**Solution:**
```haxe
// Ensure assigns are set in mount
public function mount(params: Dynamic, session: Dynamic, socket: Socket): Socket {
    return socket.assign({
        products: [], // Initialize all assigns
        loading: true
    });
}
```

### Problem: Routes not found

**Symptom:**
```
** (UndefinedFunctionError) function Routes.product_path/3 is undefined
```

**Solution:**
```elixir
# In router.ex, ensure resources are defined
scope "/", MyAppWeb do
  pipe_through :browser
  
  resources "/products", ProductController
end
```

## Performance Issues

### Problem: Slow compilation

**Symptom:**
Compilation takes more than a few seconds.

**Solutions:**

1. **Use compilation server:**
```bash
# Start compilation server
haxe --wait 6000

# In another terminal
haxe build.hxml --connect 6000
```

2. **Split into smaller modules:**
```hxml
# Create separate compilation units
# build-schemas.hxml
-cp src_haxe
-D reflaxe.output=lib/generated/schemas
schemas

# build-controllers.hxml
-cp src_haxe
-D reflaxe.output=lib/generated/controllers
controllers
```

3. **Use conditional compilation:**
```haxe
#if !debug
// Skip debug code in production
#end
```

### Problem: Large generated files

**Symptom:**
Generated Elixir files are very large.

**Solution:**
```hxml
# Enable optimization
-D analyzer-optimize
-D reflaxe.optimize

# Remove debug information
-D no-debug
```

### Problem: Memory issues during compilation

**Symptom:**
```
Error: Out of memory
```

**Solution:**
```bash
# Increase Node.js memory (if using npx)
NODE_OPTIONS="--max-old-space-size=4096" npx haxe build.hxml

# Or increase Java heap (if using Java target)
export HAXE_STD_PATH="--java=-Xmx2G"
```

## IDE and Tooling Issues

### Problem: VS Code not recognizing Haxe files

**Solution:**
```bash
# Install Haxe extension pack
code --install-extension vshaxe.haxe-extension-pack

# Create .vscode/settings.json
{
    "haxe.executable": "npx",
    "haxe.arguments": ["haxe"],
    "haxe.displayConfigurations": [
        ["build.hxml"]
    ]
}
```

### Problem: Autocompletion not working

**Solution:**
1. Create `.haxerc` file:
```json
{
    "version": "4.3.6",
    "resolveLibs": "scoped"
}
```

2. Ensure build.hxml has proper paths:
```hxml
-cp src_haxe
-cp std
-lib reflaxe.elixir
```

3. Restart language server:
- VS Code: Cmd/Ctrl+Shift+P → "Haxe: Restart Language Server"

### Problem: Formatter not working

**Solution:**
```bash
# Install formatter
lix install formatter

# Create formatter.json
{
    "lineEnds": "\n",
    "indentation": "    "
}

# Run formatter
haxelib run formatter -s src_haxe
```

## Test Environment Error Handling

### Understanding Test vs Production Errors

Reflaxe.Elixir includes intelligent error handling that differentiates between expected test behavior and real errors.

#### Expected Test Behavior

**Symptom:**
```bash
[warning] Haxe compilation failed (expected in test): Library reflaxe.elixir is not installed
```

**This is NORMAL** ✅
- Tests run in isolated environments without full library installation
- The test framework validates compilation behavior, not successful execution
- No ❌ symbol appears because this is expected behavior

**Why this happens:**
- Test environments use minimal setups to avoid dependency conflicts
- Tests focus on validating compiler logic, not runtime execution
- This warning confirms the test isolation is working correctly

#### Real Compilation Errors

**Symptom:**
```bash
[error] ❌ Haxe compilation failed: src_haxe/Main.hx:5: Type not found : MyClass
```

**This needs fixing** ❌
- Shows ❌ symbol indicating a real problem
- Should cause test failures if encountered
- Indicates actual compilation issues in your code

#### Implementation Details

The logic is implemented in `HaxeWatcher.ex`:

```elixir
# Check if this is an expected error in test environment
if Mix.env() == :test and String.contains?(error, "Library reflaxe.elixir is not installed") do
  # Use warning level without emoji for expected test errors
  Logger.warning("Haxe compilation failed (expected in test): #{error}")
else
  # Use error level with emoji for real errors
  Logger.error("❌ Haxe compilation failed: #{error}")
end
```

#### When to Worry

**Don't worry about:**
- ⚠️ Warnings without ❌ symbols during tests
- "Library not installed" messages in test environment
- Expected compilation failures that tests are designed to handle

**Do investigate:**
- ❌ Error messages with red X symbols
- Test failures in CI/CD
- Compilation errors in development environment
- Any unexpected error patterns

#### Testing Best Practices

**For Contributors:**
- Expected warnings are part of the test design - don't try to "fix" them
- Focus on ❌ symbols as indicators of real problems
- Understand that test isolation creates some expected failures

**For CI/CD:**
- Green checkmarks = all tests passed (warnings are OK)
- Red X marks = real test failures occurred
- Expected warnings don't break the build

## Common Error Messages

### "Type not found : ElixirCompiler"

**Cause:** Reflaxe.elixir not properly installed.

**Fix:**
```bash
lix install github:fullofcaffeine/reflaxe.elixir
lix download
```

### "Abstract 'Socket' has no field assign"

**Cause:** Missing Phoenix extern definitions.

**Fix:**
```haxe
import phoenix.Socket;
// Not import elixir.Socket
```

### "Cannot read property 'fields' of undefined"

**Cause:** Macro error during compilation.

**Fix:**
```haxe
// Check for typos in annotations
@:liveview // Correct
// Not @:liveView or @:live_view
```

### "Unexpected ;"

**Cause:** Elixir doesn't use semicolons.

**Fix:**
```haxe
// Haxe code is fine with semicolons
var x = 10; // This is OK

// But in untyped blocks, avoid them
untyped __elixir__('
    x = 10  # No semicolon
');
```

## FAQ

### Q: Can I use existing Elixir libraries?

**A:** Yes! Use extern definitions or escape hatches:
```haxe
@:native("ExistingLibrary")
extern class ExistingLibrary {
    public static function doSomething(arg: String): Dynamic;
}
```

### Q: How do I debug generated Elixir code?

**A:** Check the generated files in `lib/generated/`:
```bash
# View generated code
cat lib/generated/my_module.ex

# Add IO.inspect in Haxe
trace(myVariable); // Becomes IO.inspect in Elixir
```

### Q: Can I mix Haxe and Elixir files?

**A:** Yes! Put Haxe in `src_haxe/` and Elixir in `lib/`:
```
project/
├── src_haxe/        # Haxe sources
│   └── MyModule.hx
├── lib/
│   ├── generated/   # Generated from Haxe
│   └── manual/      # Hand-written Elixir
```

### Q: How do I handle Elixir atoms?

**A:** Use untyped or create an enum:
```haxe
// Direct atom
var atom = untyped :my_atom;

// Enum abstraction
enum Atom {
    @:native(":ok") OK;
    @:native(":error") ERROR;
}
```

### Q: What about Elixir macros?

**A:** Use escape hatches:
```haxe
untyped __elixir__('
    require Logger
    Logger.info("Message")
');
```

### Q: How do I profile generated code?

**A:** Use Elixir's built-in profiling:
```elixir
# In iex
:fprof.start()
:fprof.trace([:start])
MyModule.function()
:fprof.trace([:stop])
:fprof.analyse()
```

## Getting Help

If you can't resolve your issue:

1. **Check the documentation:**
   - [Getting Started Guide](./GETTING_STARTED.md)
   - [API Reference](./API_REFERENCE.md)
   - [Examples](../examples/)

2. **Search existing issues:**
   - [GitHub Issues](https://github.com/fullofcaffeine/reflaxe.elixir/issues)

3. **Ask the community:**
   - [Discord Server](#)
   - [Forum](#)

4. **Report a bug:**
   - [Create an issue](https://github.com/fullofcaffeine/reflaxe.elixir/issues/new)
   - Include:
     - Haxe version (`haxe --version`)
     - Elixir version (`elixir --version`)
     - Minimal reproduction code
     - Error messages
     - Expected vs actual behavior

## Debug Checklist

When encountering issues, go through this checklist:

- [ ] Haxe version 4.3.0+ installed?
- [ ] Reflaxe.elixir properly installed?
- [ ] All dependencies installed (`npm install` and `mix deps.get`)?
- [ ] Code compiled (`npx haxe build.hxml`)?
- [ ] Mix compilers configured in `mix.exs`?
- [ ] Generated files present in `lib/generated/`?
- [ ] No syntax errors in Haxe code?
- [ ] All required annotations present (@:module, @:liveview, etc.)?
- [ ] Imports correct (not mixing std libs)?
- [ ] Types match between Haxe and Elixir?

## Summary

Most issues fall into these categories:
- ✅ **Installation**: Ensure all tools are properly installed
- ✅ **Configuration**: Check build.hxml and mix.exs settings
- ✅ **Type mismatches**: Verify type conversions
- ✅ **Missing annotations**: Add required annotations
- ✅ **Compilation order**: Ensure files are compiled before use

Remember: The compiler is your friend! Read error messages carefully—they usually point directly to the problem.