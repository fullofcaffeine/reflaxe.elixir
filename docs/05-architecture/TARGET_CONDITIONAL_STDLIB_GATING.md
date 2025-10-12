# Target-Conditional Stdlib Gating (Implemented)

This document describes how Reflaxe.Elixir gates Elixir-specific staged standard library overrides so they are only available when compiling to the Elixir target, and never leak into macro evaluation or other targets (e.g., JavaScript via genes).

## WHAT

- Elixir-only overrides live under `std/_std/` (e.g., `.cross.hx` files using `__elixir__()`).
- These paths are added to the Haxe classpath only when building the Elixir target.
- Macro contexts and non-Elixir targets see the regular `std/` externs without Elixir-specific overrides.

## WHY

- Prevent "Unknown identifier: __elixir__" during macro time and for non-Elixir targets.
- Avoid cross-target shadowing: staged overrides must not replace stock Haxe stdlib except for Elixir builds.
- Align with mature target patterns (hxcpp, reflaxe.cs), which gate their target stdlib conditionally.

## HOW

Implemented in `src/reflaxe/elixir/CompilerInit.hx` inside `CompilerInit.Start()`:

1) Haxe 5 platform guard (already present):

```haxe
#if (haxe >= version("5.0.0"))
switch (haxe.macro.Compiler.getConfiguration().platform) {
  case CustomTarget("elixir");
  case _: return; // Do nothing for non-elixir platforms
}
#end
```

2) Classpath injection (Elixir only):

```haxe
var targetName = Context.definedValue("target.name");
var thisFile = Context.resolvePath("reflaxe/elixir/CompilerInit.hx");
var repoRoot = Path.directory(Path.directory(Path.directory(Path.directory(thisFile))));
var stagedStd = Path.normalize(Path.join([repoRoot, "std/_std"]));

// Gate strictly to Elixir target. Fallback for Haxe 4 where target.name may be unset: use -D elixir_output.
if (targetName == "elixir" || Context.defined("elixir_output")) {
  haxe.macro.Compiler.addClassPath(stagedStd);
}
```

3) Library configuration update:

- Removed the unconditional `-cp ${SCOPE_DIR}/std/_std/` from `haxe_libraries/reflaxe.elixir.hxml`.
- Kept `-cp ${SCOPE_DIR}/std/` (generic externs).
- Rationale: classpath gating is now handled centrally by the bootstrap macro.

## Activation Scenarios

Gating activates (i.e., `std/_std/` is added) in these scenarios:

- Haxe 5 + Elixir custom target:
  - `--macro reflaxe.elixir.CompilerInit.Start()` is present
  - Platform is `CustomTarget("elixir")`
  - Result: classpath injection runs; Elixir-only overrides are available

- Haxe 4 + Reflaxe.Elixir builds (tests/examples):
  - `--macro reflaxe.elixir.CompilerInit.Start()` is present
  - Either `Context.definedValue("target.name") == "elixir"` OR `-D elixir_output=...` is set (fallback)
  - Typical: test snapshots (`test/snapshot/*/compile.hxml`), examples (`examples/todo-app/build-server.hxml`)

Gating DOES NOT activate in these scenarios:

- Non-Elixir targets (e.g., genes JavaScript builds via `build-client.hxml`)
- Macro-only utilities and code generation not targeting Elixir
- Any Haxe invocation lacking `-D elixir_output` and not running with `target.name == "elixir"`

## Verification

- Elixir builds: `npx haxe build-server.hxml` succeed; mix compiles; Elixir-only overrides are present.
- Non-Elixir builds: `npx haxe build-client.hxml` (genes) succeed; no `__elixir__()` symbols; no staged overrides on classpath.
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
