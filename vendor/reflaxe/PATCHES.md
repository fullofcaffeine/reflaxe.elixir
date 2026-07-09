# Reflaxe Framework Patch Audit

This directory vendors Reflaxe framework sources so Reflaxe.Elixir can use a
known framework baseline while carrying a small number of fixes required by the
Elixir target and the repository-local release/package flow.

## Audit Status

Last audit: 2026-07-09

Compared against:

- Vendored base recorded by the previous patch notes:
  `430b4187a6bf4813cf618fc3a73ccf494a2ab9f5`
  (`Fix secret null-safety issue`)
- Current upstream `SomeRanDev/reflaxe` `main` at audit time:
  `73a983112e039daad46b37912ab238df6bf0cf53`

Result:

- None of the required local fixes below are upstreamed in current upstream
  `main`.
- No vendored patch was removed in this audit.
- `EnumIntrospectionCompiler` is target-owned Reflaxe.Elixir code, not a
  vendored framework patch, so it is intentionally not tracked here.

## Required Local Patches

### 1. `Run.hx`: Build Root File Copy

Status: local patch, not upstreamed.

Files:

- `Run.hx`

Why it exists:

The upstream `reflaxe build` command recursively copies `classPath` and
`stdPaths` into a package build directory. If a source root contains files
directly at its root, such as this repo's `src/Run.hx`, the copy helper can try
to copy the file before the destination root exists.

Observed failure shape:

```text
Uncaught exception .../_Build/src/Run.hx: No such file or directory
```

Local fix:

- Create the destination directory before walking a source directory.
- Create each copied file's parent directory before `File.copy`.

Current decision:

Keep. This is needed by `scripts/release/package-haxelib.sh`, which delegates
package flattening to Reflaxe's own build command.

Upstream action:

Good upstream PR candidate. The patch is small, target-agnostic, and should be
safe for all Reflaxe targets.

Validation before removal:

- `npm run test:haxelib-package`
- `npm run test:quick`

### 2. `BaseTypeHelper.hx`: Leading Slash Module Sanitization

Status: local patch, not upstreamed.

Files:

- `src/reflaxe/helpers/BaseTypeHelper.hx`

Why it exists:

Reflaxe.Elixir has historically seen malformed module names for some standard
library paths, most visibly `EReg` from regex literal use. The malformed module
name can contain a leading slash, producing a module id that later looks like an
absolute filesystem path.

Observed failure shape:

```text
Uncaught exception /e_reg.ex: Read-only file system
```

Local fix:

- Strip one leading slash from `BaseType.module` before Reflaxe converts module
  dots to underscores.

Current decision:

Keep. Reflaxe.Elixir still relies on this defensive normalization while it uses
normal Haxe stdlib resolution for affected classes.

Upstream action:

Needs a focused upstream repro before PR. The upstreamable version should
probably be framed as defensive module-id normalization, not as an
Elixir-specific `EReg` workaround.

Validation before removal:

- Snapshot coverage using regex literals.
- `npm run test:quick`
- `npm run test:examples`

### 3. `OutputManager.hx`: Last-Chance Malformed Path Guard

Status: local patch, not upstreamed.

Files:

- `src/reflaxe/output/OutputManager.hx`

Why it exists:

This is a second defensive layer for malformed generated filenames that begin
with `/` but are intended to be relative output filenames. Without the guard,
the output manager can attempt to write generated target files to the filesystem
root.

Local fix:

- If a path starts with `/` but does not look like an intentional absolute path,
  strip the leading slash before resolving it against the output directory.

Current decision:

Keep, but treat it as a defensive backstop. The preferred root fix is to prevent
malformed module ids before filenames are computed.

Upstream action:

Possible upstream PR, but the current heuristic should be refined before
submission. A better upstream shape would be an explicit distinction between
module-relative output paths and caller-provided absolute paths.

Validation before removal:

- Same regex-literal snapshot/runtime coverage as `BaseTypeHelper`.
- `npm run test:quick`
- `npm run test:examples`

### 4. `RemoveTemporaryVariablesImpl.hx`: Null Initializer Guard

Status: local patch, not upstreamed.

Files:

- `src/reflaxe/preprocessors/implementations/RemoveTemporaryVariablesImpl.hx`

Why it exists:

The temporary-variable remover can inspect valid Haxe declarations without
initializers, for example:

```haxe
var value:Int;
value = 42;
```

Upstream calls `maybeExpr.trustMe()` after `shouldRemoveVariable(...)`. In modes
such as `AllVariables`, `shouldRemoveVariable(...)` can return `true` even when
`maybeExpr` is null, causing `Trusted on null value`.

Local fix:

- Only attempt temporary removal when `maybeExpr != null`.

Current decision:

Keep. Uninitialized local variables are valid Haxe and the optimizer should skip
them rather than crash.

Upstream action:

Good upstream PR candidate with a minimal Reflaxe test covering an uninitialized
local variable under the affected preprocessor mode.

Validation before removal:

- Focused snapshot/regression using an uninitialized local variable.
- `npm run test:quick`

### 5. `TargetCodeInjection.hx`: Local Identifier Injection Calls

Status: local patch, not upstreamed.

Files:

- `src/reflaxe/compiler/TargetCodeInjection.hx`

Why it exists:

Reflaxe upstream detects target-code injection calls only when the callee is a
typed identifier (`TIdent`). Reflaxe.Elixir also accepts the callee when Haxe
types it as a local (`TLocal`) with the configured injection name. This protects
raw target-code injection such as `untyped __elixir__(...)` across Haxe typing
shapes.

Local fix:

- In both direct and generic injection detection, accept `TLocal(v)` when
  `v.name == injectFunctionName`.

Current decision:

Keep. Reflaxe.Elixir uses target-code injection heavily inside stdlib and
framework shims.

Upstream action:

Potential upstream PR, but it needs a target-agnostic repro that demonstrates
when Haxe emits a `TLocal` callee for a configured injection function.

Validation before removal:

- `test/snapshot/core/elixir_injection_test`
- `test/snapshot/regression/ElixirInjectionExpansion`
- `npm run test:quick`
- `npm run test:examples`

### 6. `ClassModifier.hx`: Haxe 4.3 Compatibility

Status: local patch, not upstreamed.

Files:

- `src/reflaxe/input/ClassModifier.hx`

Why it exists:

Reflaxe upstream calls `Compiler.addMetadata(...)`. Reflaxe.Elixir still
supports Haxe 4.3.x in CI/package smoke lanes, and Haxe 4.3 does not provide
that API. The local patch falls back to `Compiler.addGlobalMetadata(...)` for
Haxe versions before 4.4.

Local fix:

- Use `Compiler.addMetadata(...)` on Haxe 4.4+.
- Use `Compiler.addGlobalMetadata(...)` on Haxe 4.3.x.

Current decision:

Keep while Haxe 4.3.x remains supported.

Upstream action:

Upstream PR only makes sense if upstream Reflaxe intends to keep Haxe 4.3.x
compatibility. Otherwise this remains a Reflaxe.Elixir compatibility patch.

Validation before removal:

- Minimum-toolchain CI lane.
- `npm run test:haxelib-package`

## Local Non-Framework Metadata

These files are local to this vendored copy and are not framework patches:

- `PATCHES.md` - this audit document.
- `FUTURE_MODIFICATIONS.md` - notes for possible future framework integration
  of target syntax helpers.
- `haxelib.json` - local vendored-package metadata used for clarity; the active
  scoped hxml still pins `-D reflaxe=4.0.0-beta`.

## Cleanup Notes

2026-07-09 cleanup:

- Removed local debug-only instrumentation from
  `src/reflaxe/ReflectCompiler.hx`.
- Removed local debug-only instrumentation from
  `src/reflaxe/preprocessors/ExpressionPreprocessor.hx`.
- Kept the whitespace-only difference in
  `src/reflaxe/preprocessors/implementations/everything_is_expr/EverythingIsExprSanitizer.hx`
  because matching upstream exactly would reintroduce trailing whitespace and
  violate this repo's diff hygiene.

Vendored framework cleanup commits should still validate with:

- `npm run test:haxelib-package`
- `npm run test:quick`

## Upstream Migration Path

When a required patch is merged and released upstream:

1. Update the scoped Reflaxe dependency to the upstream version.
2. Remove only the matching local vendored patch.
3. Run that patch's validation checklist.
4. Run `npm run test:haxelib-package`.
5. Update this document with the upstream commit/release that made the local
   patch unnecessary.
