# Target-Conditional Stdlib Gating (Implemented)

This document describes how Reflaxe.Elixir gates the Elixir-target standard library root so it is
available when compiling to Elixir and does not leak into macro evaluation or other targets
(e.g., JavaScript via genes).

For the package-layout comparison with upstream Reflaxe's skeleton `build` flow, and for the exact
roles of `extraParams.hxml`, `CompilerBootstrap.Start()`, and `CompilerInit.Start()`, see
`docs/03-compiler-development/CROSS_FILES_STAGING_MECHANISM.md`.

## WHAT

- Elixir-specific stdlib work in this repo uses two source roots:
  - `std/elixir/_std/**/*.hx`: authored target-specific overrides for upstream Haxe stdlib modules.
  - plain `std/**/*.hx`: target-owned APIs/support modules such as `elixir.*`, `phoenix.*`, and `ecto.*`.
- Additionally, a tiny set of **bootstrap-safe overrides** live under the initial `src/haxe/**`
  classpath because they are resolved *very early* (before bootstrap macros can guarantee target
  std insertion):
  - `src/haxe/Exception.cross.hx` is the lone source-tree `.cross.hx` override. It keeps macro/eval
    and non-cross targets on upstream's extern `haxe.Exception`, while Elixir output gets the concrete
    `Reflaxe.Exception` runtime base.
  - `src/haxe/ds/{ArraySort,BalancedTree,EnumValueMap,ListSort}.hx` are plain `.hx` dual-mode
    surfaces for macro/eval plus Elixir output.
  - `src/haxe/ds/{GenericStack,HashMap,List}.hx` are early BEAM-safe stdlib implementations whose
    receiver semantics are tied to compiler lowering.
- `std/elixir/_std/` and `std/` are added to the active Haxe classpath for Elixir builds by
  `CompilerBootstrap.Start()`.
- Macro contexts and non-Elixir targets normally use the upstream Haxe stdlib, except for the
  explicitly documented early `src/haxe/**` overrides above.

## WHY

- Prevent "Unknown identifier: __elixir__" during macro time and for non-Elixir targets.
- Avoid cross-target shadowing: target overrides must not replace stock Haxe stdlib except for Elixir builds.
- Align with mature target patterns (hxcpp, reflaxe.cs), which gate their target stdlib conditionally.

## HOW

Implemented in two places:

- `src/reflaxe/elixir/CompilerBootstrap.hx` (`CompilerBootstrap.Start()`) — earliest possible injection (invoked from `extraParams.hxml` and, in this repo, also from `haxe_libraries/reflaxe.elixir.hxml` for scoped-lib builds).
- `src/reflaxe/elixir/CompilerInit.hx` (`CompilerInit.Start()`) — compiler registration + safety metadata (does not own classpath gating).

`extraParams.hxml` is the haxelib/lix hook that makes this automatic for consumers using
`-lib reflaxe.elixir`. It must remain cwd-agnostic, so it calls bootstrap/init macros instead of adding
relative `-cp` entries that would be resolved from the consumer project.

### Haxe 5 platform guard (Elixir target only)

```haxe
#if (haxe >= version("5.0.0"))
switch (haxe.macro.Compiler.getConfiguration().platform) {
  case CustomTarget("elixir");
  case _: return; // Do nothing for non-elixir platforms
}
#end
```

### Classpath insertion (Elixir builds only)

```haxe
var bootstrapPath = Context.resolvePath("reflaxe/elixir/CompilerBootstrap.hx");
var libraryRoot = ...; // derived from the resolved installed package path

var vendoredReflaxe = Path.normalize(Path.join([libraryRoot, "vendor", "reflaxe", "src"]));
var targetStdOverrides = Path.normalize(Path.join([libraryRoot, "std", "elixir", "_std"]));
var standardLibrary = Path.normalize(Path.join([libraryRoot, "std"]));

if (isElixirBuild()) {
  injectClassPathsFirst([targetStdOverrides, standardLibrary, vendoredReflaxe]);
} else {
  injectClassPathsFirst([vendoredReflaxe]);
}
```

`injectClassPathsFirst` intentionally prepends these paths. Appending is too late for modules that
must shadow the official Haxe stdlib in Elixir builds.

### Library configuration update

- Kept `-cp ${SCOPE_DIR}/std/` for repo-local scoped-lib ergonomics and added
  `-cp ${SCOPE_DIR}/std/elixir/_std/` so source-tree builds see authored std overrides directly;
  `CompilerBootstrap.Start()` still prepends the target paths for Elixir builds so ordering matches
  consumer installs.
- Added `--macro reflaxe.elixir.CompilerBootstrap.Start()` so repo-local scoped-lib builds get the same package-root classpath insertion behavior as consumer installs.
- For the handful of modules that must be available before macros run, we place a documented
  bootstrap-safe implementation under `src/haxe/**`. Use this only for concrete early-resolution
  constraints; ordinary stdlib replacements belong in `std/elixir/_std/**`.

## Activation Scenarios

Gating activates (i.e., `std/elixir/_std/` and `std/` are added to the active Haxe classpath) in these scenarios:

- Haxe 5 + Elixir custom target:
  - `--macro reflaxe.elixir.CompilerInit.Start()` is present
  - Platform is `CustomTarget("elixir")`
  - Result: classpath injection runs; Elixir-only overrides are available

- Haxe 4 + Reflaxe.Elixir builds (tests/examples):
  - `--macro reflaxe.elixir.CompilerBootstrap.Start()` is present
  - Elixir build signals:
    - Preferred: `-D elixir_output=...` (stable signal used throughout the harness)
    - Early fallback: `platform == cross` (Reflaxe targets on Haxe 4)
  - Typical: test snapshots (`test/snapshot/*/compile.hxml`), examples (`examples/todo-app/build-server.hxml`)

Gating DOES NOT activate in these scenarios:

- Non-Elixir targets (e.g., genes JavaScript builds via `build-client.hxml`)
- Macro-only utilities and code generation not targeting Elixir
- Any Haxe invocation lacking `-D elixir_output` and not running with `target.name == "elixir"`

## Verification

- Elixir builds: `haxe examples/todo-app/build-server.hxml` succeeds; mix compiles; target std overrides are present.
- Non-Elixir builds: `haxe examples/todo-app/build-client.hxml` (genes) succeeds; no `__elixir__()` symbols; no Elixir target overrides on classpath.
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
