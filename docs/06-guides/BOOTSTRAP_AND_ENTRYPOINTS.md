# Bootstrap and Entrypoints

This target supports two entrypoint modes and two bootstrap strategies for loading and running code.

Entrypoint modes:
- Main: a class defines a static `main()` function that should be executed as a standalone script.
- OTP: a class annotated with `@:application` that starts via OTP `start/2`; no bootstrap is generated.
- None: regular library/module code; no bootstrap.

Bootstrap strategies:
- External (default): generate a separate bootstrap file after compilation that requires all dependencies in topological order, then calls `Main.main()`.
- Inline: insert `Code.require_file(...)` and the `Main.main()` call directly into the main module file.

## How it works

1) Detection (compile-time)
- The compiler detects a static `main()` on a class and marks it as an entrypoint (mode = Main), unless the class has `@:application` (mode = OTP).
- The AST builder records each such module in `modulesWithBootstrap`.

2) Dependency tracking (compile-time)
- While compiling functions, the compiler records module dependencies whenever it generates a remote call (`Module.func(...)`). Built-in Elixir modules are ignored.
- Dependencies are recorded under the final module name (after applying `@:native`) so they align with the actual output paths.

3) Emission (final output phase)
- With External strategy, after compiling all modules, a `bootstrap_<module>.ex` file is generated for each entrypoint:
  - It loads the transitive dependency closure in topological order using `Code.require_file("<path>", __DIR__)`.
  - It then requires the main module file and calls `Module.main()`.
- With Inline strategy, `Code.require_file(...)` and `Module.main()` are injected into the main module file directly.

## Configuring strategy

Use one of the following defines in your `.hxml`:

- `-D bootstrap_strategy=external` (default)
- `-D bootstrap_strategy=inline`
- `-D inline_bootstrap` (alias for `inline`)

Examples:

```
# External bootstrap (default)
-D bootstrap_strategy=external

# Inline bootstrap
-D bootstrap_strategy=inline
# or
-D inline_bootstrap
```

## Why External is better

- Deterministic ordering: dependencies are loaded in topological order, preventing rare "module not found" issues.
- Complete closure: uses the full graph built during compilation, so transitive requirements are included.
- Clean modules: avoids mixing execution concerns into module files.

Inline remains available for simple scripts or when you prefer a single file.

## Running

External strategy emits `bootstrap_<module>.ex` files in the output directory. Run them with:

```
elixir bootstrap_main.ex
```

Inline strategy requires only the generated `main.ex`:

```
elixir main.ex
```

## Notes

- `@:application` modules never generate bootstrap code; OTP manages startup.
- The compiler generates snake_case file names and directory paths based on package/module names.
