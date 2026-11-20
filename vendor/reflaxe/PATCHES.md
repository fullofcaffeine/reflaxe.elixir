# Reflaxe Framework Patch Audit

This directory vendors Reflaxe framework sources so Reflaxe.Elixir can use a
known framework baseline while carrying a small number of fixes required by the
Elixir target and the repository-local release/package flow.

## Audit Status

Last audit: 2026-07-12 (framework sync drift decision)

Compared against:

- Vendored base recorded by the previous patch notes:
  `430b4187a6bf4813cf618fc3a73ccf494a2ab9f5`
  (`Fix secret null-safety issue`)
- Current upstream `SomeRanDev/reflaxe` `main` at audit time:
  `73a983112e039daad46b37912ab238df6bf0cf53`
- Local reference checkout:
  `../haxe.compilerdev.reference/reflaxe`
- Recently converted sibling targets:
  `../haxe.rust` and `../haxe.ocaml`

Result:

- Reflaxe.Elixir now follows the generated-target layout convention for
  package metadata: `haxelib.json` owns `classPath` and `reflaxe.stdPaths`,
  source-checkout builds use `haxe_libraries/reflaxe.elixir.hxml`, and
  installed package builds rely on Reflaxe's `_std` flattening into packaged
  `.cross.hx` files.
- `CompilerBootstrap.Start()` remains a target-specific addition, not a
  deviation to remove. The bare `reflaxe new` template only calls
  `CompilerInit.Start()`, but Reflaxe.Elixir needs bootstrap to add
  `std/elixir/_std`, target-owned `std`, `vendor/reflaxe/src`, and
  `vendor/phoenix_shared/src` early enough for consumer installs and nested
  repo-local builds.
- None of the required local fixes below are upstreamed in current upstream
  `main`.
- No vendored patch was removed in this audit.
- No Elixir AST pipeline or target semantic pass was changed in this audit.
- `EnumIntrospectionCompiler` is target-owned Reflaxe.Elixir code, not a
  vendored framework patch, so it is intentionally not tracked here.

Sibling compiler findings:

- `../haxe.rust` still vendors Reflaxe and carries a broader local patch set.
  That confirms vendoring remains an accepted local pattern when a target needs
  framework fixes before upstream Reflaxe has them.
- `../haxe.ocaml` currently resolves Reflaxe from the haxelib cache in its root
  scoped hxml. That is the desired long-term shape for Reflaxe.Elixir only after
  the required local patches below are upstreamed, replaced, or proven obsolete.
- The `reflaxe/newproject` template establishes the simple baseline:
  `reflaxe.stdPaths`, package-scoped `nullSafety(...)`, and
  `CompilerInit.Start()`. Reflaxe.Elixir intentionally adds bootstrap and
  package smoke guards because its stdlib/framework surfaces have stricter
  source-vs-package ordering requirements.

## External Contribution Policy

This audit may call a patch an "upstream candidate," but that classification is
only a maintenance assessment. Do not open or update an upstream Reflaxe pull
request or issue unless the user explicitly asks for that external action.

Until then, keep the fix in this audited vendored baseline. A backup branch may
also be pushed to the project-owned `fullofcaffeine/reflaxe` fork without
opening a pull request. Existing upstream PR
[`SomeRanDev/reflaxe#52`](https://github.com/SomeRanDev/reflaxe/pull/52) predates
this policy; its status remains historical patch evidence, not a default for
future work.

## Required Local Patches

### Target-owned Class Cache Dependencies

`BaseCompiler.shouldRecompileClass` lets a target rebuild an unchanged class
when its output depends on another typed module. Reflaxe checks this hook after
the target's `filterTypes` scan and before removing cached classes.

Reflaxe.Elixir uses it for private-method exports. Adding an authorized remote
call must change the target method from `defp` to `def`, even when that target's
source file did not change. Removing the call must restore `defp`. Dependency
state advances only after successful output publication. The default hook
returns false and preserves existing source-cache behavior for other targets.

Reflaxe.Elixir also uses it when dead-code elimination changed the members of a
class that Haxe did not type again. Under `-dce full`, an edit that calls an
unused public method of an unchanged class gives that class the method, and an
edit that stops the last use removes it. The target records the member lists
that each class was built with, its own and those of its superclasses (a
subclass module repeats its parent's public methods), beside the module name it
registered. It keeps a record for every class that reaches `compileClassImpl`,
and the hook returns true when the current lists differ. The upstream cache filter has the
same blind spot for every target, because it rebuilds only the classes that
Haxe typed again.

The private-export add/remove cases and the `dce-members` case in
`test:reflaxe-server-cache` compare warm output with fresh output. Owners:
`haxe.elixir.codex-x31` and `haxe.elixir.codex-c0o.23`. This patch stays local
until an equivalent upstream cache hook is reviewed, adopted, and verified.

### Types That Haxe Typed Again Carry The Request That Typed Them

On a compilation server, Reflaxe keeps only the types that Haxe typed again in
the current request. Upstream Reflaxe finds them with a global build macro,
`addToBuildCache`, that its initialization macro registers. A build macro runs
only for a type that Haxe types after the macro was registered. A type that
Haxe typed earlier in the request was never recorded.

Observed failure shape: a project HXML had a line
`--macro haxe.macro.Context.getType("CacheNative")` in front of
`-lib reflaxe.elixir`. After an ordinary edit of `CacheNative`, Haxe typed the
class again, before Reflaxe started. The cache filter left the class out, the
old `cache_web/native_label.ex` stayed on disk, and the build exited 0. The
same happened to an enum in the request after a same-second edit (see below).

Local fix: `ReflectCompiler.onAfterTyping` adds
`@:reflaxe.typedIn("<request token>")` to each type that has no such metadata
yet. A request token is the request's start time and a request count. A type
that Haxe reused from the server cache keeps the token of the request that
typed it; a type that Haxe typed again is a new object without metadata and
gets the current token. `wasTypedThisRequest(type)` returns true when the type
has no token or the current one. This does not depend on when Haxe typed the
type.

Why it is exact on Haxe 4.3:

- Haxe saves the metadata of a class after typing and puts it back when a later
  request reuses the class. `onAfterTyping` runs before that save, so the token
  is part of the saved state. Metadata added later, for example after output
  publication, is removed again on reuse; a first version of this fix did that
  and built every class again in each request.
- Haxe adds the typed modules of a request to its cache only when the request
  had no error. A type with an older token therefore comes from a request that
  published its output.
- The metadata has a position outside every source file. With the type's own
  position, an editor request on a cached module found the metadata at the
  cursor and failed with "No completion point was found".

The token lives on the type object, so a class that Haxe renamed with
`@:native("MyAppWeb.ErrorJSON")` is found without a path comparison. The
earlier patch compared the source module and the Haxe path (`@:realPath`),
because the build macro saw the Haxe path and the target saw the native one;
that comparison is no longer needed and was removed.

The cache filter uses the same query for enums. Upstream Reflaxe generates each
enum again on each warm request; this patch drops an enum that Haxe reused.
Why this is safe: Haxe types an enum again when its source file or a module
that it uses changed, and the source fingerprint of every non-class declaration
(patch 9) still forces one full target build when any such file changes.
Typedefs and abstracts are still always passed on; the Elixir target generates
no module for them. Measured on a consumer backend with 80 enum modules: the
pass pipeline of a one-class warm edit ran for 81 modules (about 3.2 s) before,
and for 1 module (about 0.06 s) after.

Reflaxe.Elixir also uses `wasTypedThisRequest` to keep per-class results
between server requests: private-method export uses, clean reference-semantics
scans, and the module name and member list that each class was built with
(`ClassResultCache`). Before, each warm request scanned every class body two
times (about 0.6 s on the todo-app under load), and the printer's module
registry missed the classes that the request did not build, so a one-class
edit printed `FlashTypeTools` where a fresh build printed
`TodoApp.FlashTypeTools`.

Reflaxe.Elixir's `ServerSourceFreshness.refuseStaleReuse` uses the same query
for the last gap: a same-second edit of a file whose module Haxe loaded before
the target started. Haxe then holds the old type in that request, and no
filter can produce the new output. The build stops with an error that names
the module, and writes nothing; Haxe types the module again in the next build.

Tests in `test:reflaxe-server-cache`: `early-typed` (an ordinary class edit, an
unchanged request that must build no class module, an ordinary enum edit, and
a same-second enum edit that must refuse once and then equal a fresh build),
`native-class` (a `@:native` class body edit), `private-exports` (a one-class
edit scans fewer classes than a full scan), and every variant's comparison of
warm output with a fresh build. This patch stays local until upstream Reflaxe
has an equivalent query.

Limits: the exactness argument rests on the Haxe 4.3 server rules above. A
Haxe version that rebuilds cached type objects from a binary cache without the
metadata would build more types again, not fewer. A type that Haxe types only
after `onAfterTyping`, for example from a target callback, has no token and is
built again in the next request.

### 1. `Run.hx`: Build Root File Copy

Status: local patch, submitted upstream in
[`SomeRanDev/reflaxe#52`](https://github.com/SomeRanDev/reflaxe/pull/52).

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

### 7. `ClassFieldHelper.hx`: Lazy Function-Type Resolution

Status: local patch, not upstreamed.

Files:

- `src/reflaxe/helpers/ClassFieldHelper.hx`

Why it exists:

Reflaxe lets targets add already-typed modules from `BaseCompiler.filterTypes`.
Haxe can expose method signatures on those modules as `TLazy(TFun)` while still
providing a complete `TFunction` expression. Reflaxe matched only a direct
`TFun`, so it discarded valid methods and emitted one `Function information not
found` warning per method. Reflaxe.Elixir exposed this with its conditional
`StringTools` runtime inclusion. Generated callers could then reference
`StringTools.*` without a generated `string_tools.ex` module, so the diagnostic
was a correctness signal rather than harmless noise.

Local fix:

- Recursively unwrap only `TLazy` field-type nodes before extracting function
  arguments and return types.
- Use the same resolved type for overloaded-method cache keys so overloads do
  not collide when Haxe leaves their signatures lazy.

Current decision:

Keep. Adding module types in `filterTypes` is part of Reflaxe's documented
compiler API, and resolving Haxe's lazy wrapper preserves the method's existing
typed expression and semantics. Do not remove the vendored patch merely because
the pull request is merged: first select an upstream commit or release that
contains the fix, then run the source-versus-package parity checks below.

Upstream action:

Submitted the target-agnostic fix and regression as
[`SomeRanDev/reflaxe#52`](https://github.com/SomeRanDev/reflaxe/pull/52):

- Upstream baseline: `73a983112e039daad46b37912ab238df6bf0cf53`.
- Pull-request commit: `024937acffd242f129265d969a840d3779f02bcd`.
- Reproduction: load an otherwise unused class with `Context.getType(...)`,
  append its `TClassDecl` from `filterTypes`, and ask `ClassFieldHelper` for a
  static method's `ClassFuncData`.
- Baseline result on Haxe 4.3.7: compilation fails with
  `Function information not found for lazily typed field.`
- Patched result on Haxe 4.3.7: the same upstream `haxe Test.hxml` fixture
  passes.

The regression is intentionally part of Reflaxe's own test compiler rather
than an Elixir fixture. This proves that resolving `TLazy(TFun)` is framework
behavior and does not depend on the Elixir AST pipeline or semantic passes.

Validation before removal:

- `npm run test:examples`
- `npm run test:examples-output`
- `npm run test:haxelib-package`
- `npm run test:quick`
- `npm test`

### 8. `BaseCompiler.hx`: Target-Owned Output Publication Hooks

Status: local patch, not upstreamed.

Files:

- `src/reflaxe/BaseCompiler.hx`

Why it exists:

Reflaxe's default output manager publishes one file at a time directly into the
configured destination. Reflaxe.Elixir also needs to format, validate, and
ownership-check the complete generated tree before changing an in-place Phoenix
source directory. The base compiler previously offered neither a target-owned
output-manager factory nor a hook for operating on a prepared tree before
publication.

Local fix:

- Construct the output manager through an overridable `createOutputManager()`
  factory while preserving the existing default manager.
- Expose `onOutputPrepared(outputDirectory)` for transactional target managers
  to invoke after staging and before publication.
- Keep the ownership manifest, collision checks, recovery journal, and atomic
  publication protocol entirely target-owned; the framework patch adds only the
  two generic extension points.

Current decision:

Keep. These extension points let Reflaxe.Elixir reject unowned collisions,
format staged output, verify owned hashes, remove stale owned files, and commit
the ownership manifest last without changing the default behavior of other
targets.

Upstream action:

Good upstream candidate after the target protocol has accumulated release
evidence. No external issue or pull request has been opened. Any proposal should
remain target-agnostic and preserve the default `OutputManager` behavior.

Validation before removal:

- `mix test test/exunit/generated_output_ownership_test.exs`
- `npm run test:generated-formatting`
- `npm run test:haxelib-package`
- `npm run test:quick`
- `npm run test:examples-qa`

### 9. `ReflectCompiler.hx`: Full Rebuild for Unsafe Cache Boundaries

Status: local patch, not upstreamed.

Files:

- `src/reflaxe/ReflectCompiler.hx`

Why it exists:

During a normal Haxe compilation-server edit, Reflaxe can regenerate only the
types that Haxe typed again. Two boundaries cannot be represented safely by
that list:

- A deleted class no longer exists, so Haxe cannot type it again. A rename is
  the same problem expressed as one deletion plus one addition.
- Enums, typedefs, and abstracts can affect otherwise unchanged classes through
  inline code, representation, metadata, and global framework registries.
  Building only the changed declaration again is not enough.

Observed failure shape:

- `CacheLegacy.hx` generated `cache_legacy.ex`.
- The source was renamed to `CacheRenamed.hx` and generated
  `cache_renamed.ex` during the same server lifetime.
- The warm output still contained stale `cache_legacy.ex`, unlike a clean
  one-shot build.
- An unchanged HXX template used `phx-hook="Known"`. After an unreferenced
  `@:phxHookNames` abstract renamed that entry, a clean build rejected the hook
  but the warm build accepted it using stale registry facts.

Local fix:

- Remember the complete typed module-identity set after each successful target
  publication.
- When the next request has added, removed, or renamed a module, bypass the
  rebuilt-class filter for that request and regenerate all currently live
  modules once.
- Remember the exact source text for every source file that contributes a
  visible enum, typedef, or abstract. If one changes, bypass the class-only
  filter and regenerate all currently live modules once. The server keeps the
  text itself and compares it with native string equality. An earlier version
  kept a SHA-256 digest, which Haxe computes in the macro interpreter: about
  0.5 s for each warm request of a consumer backend. Two texts are equal
  exactly when their bytes are equal, so the same edits cause a full
  regeneration; the cost is one in-memory copy of those source files.
- Commit both successful baselines only after output succeeds, so a failed
  target build cannot poison the next request.
- Compare that source text without its classes and module-level fields. Many
  source files declare a typedef or an enum beside a class or beside
  module-level functions (a "mixed file"). With the complete file text, an edit
  in a function body of a mixed file regenerated every module. Now a class in a
  mixed file has the same rule as a class in a file of its own: Haxe types it
  again and reports it, and Reflaxe builds it and the classes that Haxe typed
  again with it.

  What is cut: `class Name { ... }` and `interface Name { ... }` from the
  keyword to the last brace, and each module-level function or variable from
  its first modifier to the end of its body. Each cut leaves one zero byte.
  What stays: every enum, typedef and abstract, imports, the text between
  declarations, and the metadata and documentation in front of a class (Haxe
  does not include them in the class position). An edit in any of these still
  regenerates every module.

  A Haxe position counts characters, not bytes: a byte order mark, `é` and an
  emoji are one character each. The cut therefore works on the decoded text,
  which Haxe's macro interpreter also indexes by character. The first version
  of this patch cut raw bytes. With non-ASCII text in front of a class, the cut
  started too early and could remove an enum or an abstract from the
  comparison, so a warm build could keep stale output and report success.

  Each position is checked against the text on disk: it must lie inside the
  file and not overlap another position, the text must start with that
  declaration, a class must end with `}`, and the text must not contain the
  start of an enum, typedef or abstract. When one check fails, nothing is cut
  from that file and its complete text is compared, as before this patch. A
  failed check can therefore only cause an extra full regeneration. The hidden
  class that holds the methods of an abstract is never cut, because its
  position is the abstract itself.

  Why this keeps the earlier guarantee: the text of every non-class
  declaration, with its metadata, is still compared byte for byte. The only
  edits that no longer force a full regeneration are edits inside a class or
  inside a module-level field. Those are the edits that already took the
  class-only path when the class had a file of its own.

Current decision:

Keep. Module topology and non-class source edits are less common than ordinary
class-body edits. One conservative full regeneration at those boundaries is
preferable to stale target files, missed global diagnostics, or a second
target-specific dependency cache. Class-only edits retain the narrower cached
path.

Upstream action:

Good upstream candidate after the warm-server regression is also reproduced in
Reflaxe's own target-neutral test suite. Do not open a PR without explicit user
authorization.

The `mixed-file` cases in `test:reflaxe-server-cache` edit a class body, a
module-level function body, a typedef and an abstract in mixed files. They
require a partial build for the first two and a full build for the last two,
and compare each warm output with a fresh build. The `mixed-registry` case
keeps a `@:phxHookNames` registry beside a class: a class edit must pass, and a
registry edit must still make the warm build reject the removed hook name.
The `byte-order-mark`, `e-acute` and `emoji` cases repeat the class edit and
the abstract edit with non-ASCII text in front of the class. The
`decoy-registry` case uses a file in which byte offsets and character offsets
disagree so that a byte cut would cover the registry; the warm build must
reject the renamed hook.

Not done (`haxe.elixir.codex-c0o.4`): an edit to the enum, typedef or abstract
itself still regenerates every module. A class edit in a module that many
modules import still builds each module that Haxe typed again.

Validation before removal:

- `test/snapshot/regression/server_cache_non_class_invalidation/run_server_cache_test.sh`
- `npm run test:reflaxe-server-cache`
- `npm run test:haxelib-package`
- `npm run test:quick`

## Local Non-Framework Metadata

These files are local to this vendored copy and are not framework patches:

- `PATCHES.md` - this audit document.
- `FUTURE_MODIFICATIONS.md` - notes for possible future framework integration
  of target syntax helpers.
- `haxelib.json` - local vendored-package metadata used for clarity; the active
  scoped hxml still pins `-D reflaxe=4.0.0-beta`.

## Upstream Drift Decisions

The selected framework baseline remains the vendored
`430b4187a6bf4813cf618fc3a73ccf494a2ab9f5` base plus the required local patches
documented above. Current upstream `73a983112e039daad46b37912ab238df6bf0cf53`
is not imported wholesale.

- Upstream/reference Reflaxe adds the 429-line
  `RemovePureExpressionsImpl.hx`, a matching `RemovePureExpressions` enum case,
  and that preprocessor to Reflaxe's default list. Reflaxe.Elixir deliberately
  provides its own explicit preprocessor list in `CompilerInit.hx`, so the new
  upstream default would not activate unless the target opts into it.
- Do not import the pass as dormant vendored code. Its broad purity and control-
  flow rewriting goes beyond the inline-return artifact that motivated
  [`SomeRanDev/reflaxe#47`](https://github.com/SomeRanDev/reflaxe/pull/47), and
  the current `hasSideEffects` composite-expression branch returns a variable
  named `isPure`. That result needs upstream clarification and focused semantic
  tests before this target depends on it.
- Reflaxe.Elixir already removes its actual warning-producing artifact with
  `BareLiteralDrop_AbsoluteLast`, a narrow target-AST pass that drops only
  non-final pure literals after all semantic rewrites. Keep that tested behavior
  rather than replacing it with a broader typed-expression optimizer.
- The checked sibling Rust and OCaml compilers do not carry or select
  `RemovePureExpressions` either. Revisit this decision when a future selected
  Reflaxe baseline includes upstream regression coverage and the Elixir target
  has a concrete reason to adopt the pass.
- Removed the inactive local `#if debug_output_manager` trace blocks from
  `OutputManager.hx`. They were not part of normal compiler behavior or a
  required patch; removing them only reduces framework diff noise.
- `src/reflaxe/preprocessors/implementations/everything_is_expr/EverythingIsExprSanitizer.hx`
  differs only by trailing-whitespace cleanup. Keep the local whitespace-clean
  copy unless the vendored baseline is refreshed wholesale.

## Cleanup Notes

2026-07-09 cleanup:

- Removed local debug-only instrumentation from
  `src/reflaxe/ReflectCompiler.hx`.
- Rechecked `src/reflaxe/preprocessors/ExpressionPreprocessor.hx`; the current
  diff is upstream/reference `RemovePureExpressions` drift, not an active
  Reflaxe.Elixir patch.
- Kept the whitespace-only difference in
  `src/reflaxe/preprocessors/implementations/everything_is_expr/EverythingIsExprSanitizer.hx`
  because matching upstream exactly would reintroduce trailing whitespace and
  violate this repo's diff hygiene.

2026-07-12 framework sync audit:

- Kept the selected vendored baseline instead of importing upstream's broad,
  currently unused `RemovePureExpressions` optimizer.
- Removed inactive `debug_output_manager` traces from `OutputManager.hx` to
  match upstream in those code paths without changing generated output.

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
