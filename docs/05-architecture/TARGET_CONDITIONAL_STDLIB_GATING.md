# Target-Conditional Stdlib Gating (Implemented)

This document describes how Reflaxe.Elixir gates Elixir-specific staged standard library overrides so they are only available when compiling to the Elixir target, and never leak into macro evaluation or other targets (e.g., JavaScript via genes).

## WHAT

- Elixir-specific stdlib work in this repo is split into two buckets:
  - `std/**/*.cross.hx`: cross-platform overrides selected by Haxe when compiling in `cross` mode (Reflaxe targets on Haxe 4).
  - `std/_std/**/*.hx`: Elixir-only shims/bridge modules that must never leak into macro-only or non-Elixir builds.
- `std/` and `std/_std/` are added to the Haxe classpath only when we detect an Elixir build.
- Macro contexts and non-Elixir targets use the upstream Haxe stdlib (no `__elixir__()` leaks).

## WHY

- Prevent "Unknown identifier: __elixir__" during macro time and for non-Elixir targets.
- Avoid cross-target shadowing: staged overrides must not replace stock Haxe stdlib except for Elixir builds.
- Align with mature target patterns (hxcpp, reflaxe.cs), which gate their target stdlib conditionally.

## HOW

Implemented in two places:

- `src/reflaxe/elixir/CompilerBootstrap.hx` (`CompilerBootstrap.Start()`) — earliest possible injection (invoked from `extraParams.hxml`).
- `src/reflaxe/elixir/CompilerInit.hx` (`CompilerInit.Start()`) — compiler registration + a redundant early injection (safe) for repo-local builds.

### Haxe 5 platform guard (Elixir target only)

```haxe
#if (haxe >= version("5.0.0"))
switch (haxe.macro.Compiler.getConfiguration().platform) {
  case CustomTarget("elixir");
  case _: return; // Do nothing for non-elixir platforms
}
#end
```

### Classpath injection (Elixir builds only)

```haxe
var targetName = Context.definedValue("target.name");
var isElixirBuild = (targetName == "elixir" || Context.defined("elixir_output"));

if (isElixirBuild) {
  // Compute <repo>/std + <repo>/std/_std from this library's resolved path.
  var compilerInitPath = Context.resolvePath("reflaxe/elixir/CompilerInit.hx");
  var elixirDir = Path.directory(compilerInitPath);      // .../src/reflaxe/elixir
  var reflaxeDir = Path.directory(elixirDir);            // .../src/reflaxe
  var srcDir = Path.directory(reflaxeDir);               // .../src
  var libraryRoot = Path.directory(srcDir);              // .../

  var standardLibrary = Path.normalize(Path.join([libraryRoot, "std"]));
  var stagedStd = Path.normalize(Path.join([libraryRoot, "std/_std"]));

  Compiler.addClassPath(standardLibrary); // <repo>/std
  Compiler.addClassPath(stagedStd);       // <repo>/std/_std
}
```

### Library configuration update

- Removed the unconditional `-cp std/_std/` from `haxe_libraries/reflaxe.elixir.hxml`.
- Kept `-cp std/` for local-repo development convenience (consumer installs rely on `extraParams.hxml`).
- Rationale: classpath gating is handled centrally by the bootstrap macros, so `std/_std` should never be unconditional.

## Activation Scenarios

Gating activates (i.e., `std/_std/` is added) in these scenarios:

- Haxe 5 + Elixir custom target:
  - `--macro reflaxe.elixir.CompilerInit.Start()` is present
  - Platform is `CustomTarget("elixir")`
  - Result: classpath injection runs; Elixir-only overrides are available

- Haxe 4 + Reflaxe.Elixir builds (tests/examples):
  - `--macro reflaxe.elixir.CompilerInit.Start()` is present
  - `-D elixir_output=...` is set (stable signal; `target.name` is commonly `cross` under Haxe 4 for Reflaxe targets)
  - Typical: test snapshots (`test/snapshot/*/compile.hxml`), examples (`examples/todo-app/build-server.hxml`)

Gating DOES NOT activate in these scenarios:

- Non-Elixir targets (e.g., genes JavaScript builds via `build-client.hxml`)
- Macro-only utilities and code generation not targeting Elixir
- Any Haxe invocation lacking `-D elixir_output` and not running with `target.name == "elixir"`

## Verification

- Elixir builds: `haxe examples/todo-app/build-server.hxml` succeeds; mix compiles; Elixir-only shims are present.
- Non-Elixir builds: `haxe examples/todo-app/build-client.hxml` (genes) succeeds; no `__elixir__()` symbols; no staged overrides on classpath.
- Macro contexts: running macro tools no longer error on `__elixir__()`.

## Notes

- This approach provides a clean separation of concerns and mirrors established Reflaxe target patterns.
- The fallback on `-D elixir_output` ensures compatibility across Haxe 4 setups used in the test harness.

### Transformer Ordering Note

- ERaw normalizers are intentionally scheduled at the very end of the transformation pipeline to
  catch late ERaw injections from stdlib/native helpers. In particular:
  - `ERawWebModuleQualification(Final)` ensures module qualification within ERaw inside `<App>Web.*`.
  - `ERawEctoValidateAtomNormalize(Final)` normalizes `validate_*` field atoms and opts nil-comparisons
    in ERaw segments.
  - A final Web-context EFn reducer pass qualifies `Enum.reduce_while` bodies introduced late.

This ordering complements classpath gating by ensuring that any ERaw code originating from target-gated
stdlib overrides is normalized before printing.
