# Test Integration Example

This example demonstrates the integration testing setup for Haxe→Elixir compilation within a Mix project environment.

## Overview

This is a minimal test case used to validate that:
- Haxe compilation works correctly within Mix projects
- Generated Elixir modules can be used by ExUnit tests
- Build pipeline integration functions properly
- Package path resolution works across ecosystems

## Files Structure

```
├── mix.exs                           # Elixir project configuration
├── build.hxml                        # Haxe compilation configuration  
└── src_haxe/
    └── test/
        └── integration/
            └── TestModule.hx         # Simple test module
```

## Purpose

This example serves as:

1. **Integration Validation**: Ensures the Haxe→Elixir compilation pipeline works end-to-end
2. **Mix Project Template**: Shows minimal setup for Haxe within Mix projects  
3. **CI/CD Testing**: Used by automated tests to validate cross-compilation
4. **Package Resolution Testing**: Validates proper package structure and imports

## Generated Output

The `TestModule.hx` compiles to:

```elixir
defmodule Test.Integration.TestModule do
  def main() do
    IO.puts("Hello from integrated Mix compilation!")
  end
  
  def get_message() do
    "Mix integration successful!"
  end
end
```

## Usage

```bash
# Compile Haxe code to Elixir
haxe build.hxml

# Run Mix tests (if any ExUnit tests are present)
mix test

# Test the generated module
iex -S mix
iex> Test.Integration.TestModule.main()
Hello from integrated Mix compilation!
```

## Integration Testing

This example is primarily used by:
- **CI workflows** to validate compilation across different environments
- **Mix test suites** to ensure generated code integrates properly
- **Package managers** to test dependency resolution
- **Build tools** to validate the Haxe compilation step within Mix projects

## Key Benefits

- **Minimal Setup**: Shows the bare minimum required for Haxe→Mix integration
- **Validation Target**: Provides a simple test case for build pipeline validation  
- **Template Base**: Can be used as starting point for new Mix+Haxe projects
- **Cross-Platform Testing**: Works consistently across different development environments

This example ensures that the fundamental compilation and integration mechanisms work correctly before more complex features are tested.
