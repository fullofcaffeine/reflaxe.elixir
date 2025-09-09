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

External strategy emits `<module>.exs` script files in the output directory (and if there is only one entrypoint module, a `main.exs`). These scripts:
- Require the full transitive dependency closure in topological order
- Require the module file itself
- Call `<Module>.main()`

Run with:

```
elixir main.exs
elixir AnotherModule.exs
```

Inline strategy requires only the generated `main.ex`:

```
elixir main.ex
```

## Notes

- `@:application` modules never generate bootstrap code; OTP manages startup.
- The compiler generates snake_case file names and directory paths based on package/module names.
- `.exs` scripts are not compiled into releases; they are ideal for entrypoint runners without polluting library code.

## Strategy matrix and recommendations

- External (`-D bootstrap_strategy=external`): recommended. Produces `<module>.exs` runner with deterministic, complete requires. Great for examples, CLIs, and scripts. Keeps `<module>.ex` pure.
- Inline (`-D bootstrap_strategy=inline`): quick single-file execution by injecting requires + `<Module>.main()` into `<module>.ex`. Simpler but intermixes execution with module definition.
- Inline deterministic (`-D bootstrap_strategy=inline_deterministic`): same as inline but computes requires after compilation (full graph) for deterministic ordering. Useful when you want `<module>.ex` to be the entrypoint without `.exs` runners.

### Example: todo-app

- Server side entrypoint (Main.main/0) can be run via `main.exs` or inline strategies.
- Phoenix apps (`@:application`) do not emit bootstrap; they start with `mix phx.server` or via `start/2` in releases.
