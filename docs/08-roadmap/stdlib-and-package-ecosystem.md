# Standard Libraries And Packages: The Road To 1.0 And Beyond

There are three different jobs hiding behind the phrase “library support.” They need different
promises and different tests:

1. **Haxe standard library:** portable Haxe code should keep Haxe behavior on the BEAM, the Erlang
   virtual machine that runs Elixir. Reflaxe.Elixir 1.0 requires complete support.
2. **Elixir standard library:** Elixir-first Haxe should have a precise, pleasant Haxe API for the
   public modules that ship with Elixir. This is a 1.x product track.
3. **Mix dependencies from Hex, Git, or local paths:** an app should be able to generate a reviewed
   typed layer for a resolved dependency without pretending that Reflaxe.Elixir owns that dependency.
   This is also a 1.x product track and shares its type machinery with the Elixir standard-library
   work.

The short version is: **1.0 proves portable Haxe; 1.x fills out native Elixir authoring; package
tooling makes the wider BEAM ecosystem easy to adopt.**

## 1.0 Means The Complete Applicable Haxe Standard Library

“Complete” does not mean copying every file from Haxe into this repository. Haxe already provides
portable implementations for many modules, and using those implementations unchanged is often the
cleanest answer.

Complete support means that every public API in the pinned Haxe standard library is accounted for:

- Runtime APIs that apply to an Elixir system target compile from ordinary Haxe and pass behavioral
  tests on the BEAM.
- Macro and compiler-time APIs remain usable in their real compile-time context and have compile or
  macro-evaluation evidence where appropriate.
- APIs owned by another target, such as a Node.js-only HTTP implementation, are marked not
  applicable with the source condition that proves it. “Hard to implement” is not a valid reason.
- Each supported API names its owner: the official Haxe implementation, compiler lowering, a
  BEAM-specific override, or a small semantics-preserving runtime helper.
- Each runtime API has positive Haxe compile evidence and BEAM runtime evidence. A generated-code
  snapshot is useful for reviewing output, but it does not prove behavior by itself.

For runtime-relevant APIs, the final 1.0 inventory must contain **zero** entries marked unsupported,
partial, unknown, or untested.

This makes several current limitations release blockers. The list includes, but is not limited to:

- object-identity behavior in `haxe.ds.ObjectMap`;
- the mutating linked-node contract in `haxe.ds.ListSort`;
- the remaining `Serializer`, `Unserializer`, and `Template` behavior;
- caller-buffer mutation in byte, TCP, UDP, and TLS reads;
- the remaining SSL certificate and signing surface;
- process/main-loop and thread synchronization behavior that currently fails fast; and
- `sys.db.*`, even though Ecto remains the better Elixir-first API for new application code.

Recommending Ecto is good product guidance. It is not a substitute for implementing the portable
Haxe contract before claiming complete Haxe stdlib support.

### Why The Current “88 Modules” Number Is Not A Support Score

The checked-in module report currently compares 204 reference modules with 116 locally owned target
modules and lists 88 modules without a local override. That number answers “does this repository own
a target-specific file?” It does **not** answer “does this Haxe API work?”

For example, a small enum abstract can work perfectly through the official Haxe implementation and
correctly have no local override. Conversely, a local file can exist only to produce a clear
unsupported diagnostic. The checked 1.0 inventory now works at public-API level and records the
support and evidence state for each row; counting files is not enough. It lists the 204 source
modules separately from the generated public API-row total, so those two measurements cannot be
confused.

The current reports remain useful inputs:

- [Public API Inventory](stdlib-parity/api-inventory.md)
- [Stdlib Support Matrix](../04-api-reference/STDLIB_SUPPORT_MATRIX.md)
- [Module-level Gap Report](stdlib-parity/gap-report.md)
- [Stdlib Parity Work](stdlib-parity/epic.md)
- [`unitstd` Manifest](../../test/upstream_unitstd/manifest.json)

Beads epic `haxe.elixir.codex-0yn.10` owns the complete-stdlib requirement. Its work is split into the
API inventory, core/data semantics, host and IO semantics, warning cleanup, and a final
installed-package audit.

The normal inventory guard rejects a changed Haxe surface, a missing module decision, a stale API
override, a missing evidence file, or a blocker that has already been closed. The separate
`npm run guard:stdlib-api-release-ready` command rejects every remaining runtime support or evidence
gap. Keeping these as two commands lets ordinary 0.x CI track honest work in progress while making
the 1.0 requirement fail closed.

### The Release File Enforces The Decision

[`release/manifest.json`](../../release/manifest.json) now lists `complete-haxe-stdlib` as a pending
major-1 requirement. The release validator rejects an approval record while any named requirement is
pending. Completing the task still requires the tests and review above; changing the word `pending`
is not evidence by itself.

## 1.x: A Complete Typed Surface For Elixir's Standard Library

The Haxe standard library and the Elixir standard library solve different problems:

- `haxe.io.Path`, `haxe.Json`, or `haxe.ds.Map` help portable Haxe code keep Haxe semantics.
- `ElixirString`, `Enum`, `File`, `Task`, or `GenServer` let Elixir-first code describe the BEAM API
  directly and generate ordinary Elixir calls.

The second surface should feel like Elixir written with Haxe's type checker, not like a Java-style
wrapper library. For example:

```haxe
import elixir.ElixirString;
import elixir.Enum;

var needle = ElixirString.downcase(ElixirString.trim(query));
var matches = Enum.filter(names, name ->
  ElixirString.contains(ElixirString.downcase(name), needle)
);
```

The target shape stays ordinary Elixir:

```elixir
needle = String.downcase(String.trim(query))
matches = Enum.filter(names, fn name ->
  String.contains?(String.downcase(name), needle)
end)
```

The value is earlier feedback and better editor help. There is no replacement `Enum` or `String`
runtime in production.

### What “Complete And Properly Typed” Means

For each supported Elixir release line, the inventory must cover every public module, function,
macro, callback, behaviour, protocol, exception, struct, and documented type. It uses Elixir's
typespecs—the `@spec` and related type metadata published by a module—as source evidence. Each entry
is one of:

- precisely typed in Haxe;
- genuinely open because the Elixir typespec itself uses `term()`;
- owned by a typed Haxe macro or DSL because the Elixir API is a macro; or
- narrowly non-applicable, with an official source-backed reason.

The type mapper must understand the shapes Elixir developers actually use: literal atoms, unions,
tuples, `{:ok, value} | {:error, reason}`, closed and open maps, structs, keyword options, lists,
function types, generics, remote types, callbacks, and exceptions. `Term` is correct when the native
contract truly says “any BEAM term.” It must not be used to hide a signature the metadata describes
more precisely. `Dynamic` is not a completeness strategy.

The low-level surface should remain API-faithful and produce direct calls. A separate Haxe wrapper is
welcome when it gives a real ergonomic win, such as a closed option enum or a better `Result` API,
but wrappers must not obscure the underlying Elixir primitive.

Beads epic `haxe.elixir.codex-zwu` owns this 1.x track.

## 1.x: Make A Mix Dependency Easy To “Haxify”

Today, `mix haxe.gen.extern Module.Name` is a useful **single-module starter**. It loads a module,
lists exported function names and arities, and writes an extern—a Haxe declaration for code that
already exists—whose parameters and results are `elixir.types.Term`. A developer then refines the
types by hand. It does not inspect a whole resolved dependency, read Elixir typespec metadata such as
`@spec`, or prove that its generated signatures are precise.

The dependency-level flow should be deliberately more conservative. The intended user experience is:

```bash
mix deps.get
mix haxe.adopt jason
mix haxe.adopt jason --write
mix compile.haxe
mix test
```

`mix haxe.adopt` is the planned dependency-level command, not a command available today. With no write
flag it only reports what it found. `--write` creates or updates the reviewed Haxe contracts. Because
the task starts from Mix's resolved dependency graph, the same flow can cover Hex, Git, and local path
dependencies. The final name must remain consistent across the implementation, help text, tests, and
this guide.

### Discovery First, Writes Second

The discovery command should resolve the selected dependency from the app's real Mix graph and
configuration, include its lock entry when one exists, then read its compiled `.beam` files without
loading arbitrary dependency modules. It should record:

- dependency name, source kind, resolved version/revision/path identity, and any lock identity;
- every public module, exported function, and macro;
- embedded documentation, specs, public types, callbacks, behaviours, deprecations, and source links;
- signatures the mapper understands;
- signatures it omitted and the exact reason; and
- any missing, ambiguous, escaped, stale, or conflicting input.

Discovery is read-only. Writing contracts requires an explicit second command. Writes use a versioned
ownership record, reject hand-written-file collisions, and show what changed when a dependency is
upgraded or downgraded.

### Precise Or Omitted

Suppose a package publishes this Elixir contract:

```elixir
@spec encode(term(), [encode_opt()]) ::
        {:ok, String.t()} | {:error, Jason.EncodeError.t()}
```

A generated native Haxe contract should preserve those facts. This is an excerpt of the planned
output: the mapper would generate the referenced option and error declarations beside it, after
reading them from the dependency. It is not a copy-and-paste API available today.

```haxe
import elixir.types.Term;
import haxe.functional.Result;

@:native("Jason")
extern class JasonNative {
  @:native("encode")
  public static function encode(
    value:Term,
    options:JasonEncodeOptions
  ):Result<String, JasonEncodeError>;
}
```

The emitted call is still the package's normal function:

```elixir
Jason.encode(value, options)
```

If the generator cannot represent `encode_opt()` honestly, it should omit that overload and explain
what needs review. It should not quietly replace the option type with `Term` and print “type-safe.”
An explicit `term()` input remains `Term`, because that is exactly what the package promised.

### Who Owns What

- Mix owns dependency resolution, configuration, compilation, and runtime selection. Hex, Git, or the
  local path remains the source of the dependency's code.
- The dependency owns its behavior and native typespecs.
- Reflaxe.Elixir owns deterministic discovery, type lowering, generated-file safety, and Haxe compile
  checks.
- The application owns its reviewed wrappers and business-specific policy.
- A popular, stable integration can become a separate companion Haxelib package, published
  through Haxe's package manager. The original dependency remains the runtime dependency.

Tests should prove the typed layer, not re-run the dependency's own test suite. The useful evidence is
a deterministic inventory, reviewed generated output, positive and negative Haxe compilation, and
one small runtime test proving that the generated call reaches the real dependency.

The design borrows one important lesson from
[RailsHx gem adoption](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/docs/railshx-gradual-adoption.md#haxe-consumes-existing-ruby):
deterministic metadata comes first. An AI assistant may help draft a reviewable patch after
discovery, but it may not invent confident contracts, erase omission diagnostics, or replace
compile/runtime evidence.

Beads epic `haxe.elixir.codex-5np` owns this package-adoption track.

### LiveReact Is A Hand-Maintained Phoenix Companion Surface

The planned PhoenixHx LiveReact integration is intentionally not generated
dependency-adoption dogfood. It is a small, manually maintained Phoenix
authoring and project-setup surface whose value comes from typed HXX wrappers,
static application registries, safe setup/removal, and compatibility evidence.
Stock `:live_react` remains the Mix/npm runtime owner; PhoenixHx must not copy
its hook, renderer, Vite plugin, or DOM protocol.

The public Haxe namespace is frozen as `phoenix.live_react`. Its low-level std
declaration is API-faithful; strict application props remain in discoverable
app-local `@:component` wrappers. Mix resolves the canonical upstream checkout,
npm consumes that exact checkout through a checked project-relative `file:`
reference, and Vite is the enabled lane's only JavaScript bundler. The current
vendored Genes source mode and `plain-js` are both initial inputs; moving to a
released `genes-ts` artifact is a separate nonblocking migration and no sibling
checkout is part of the package contract.

The integration may ship in the existing Haxelib initially because it is
opt-in and tightly coupled to PhoenixHx component discovery, scaffolding, and
Live Event Protocols. A separately versioned companion Haxelib becomes useful
only when adoption or compatibility cadence demonstrates independent release
pressure. Package separation would not, by itself, require a separate Git
repository.

The active decision and implementation graph live in
[`plans/active/phoenixhx-live-react-integration.md`](../../plans/active/phoenixhx-live-react-integration.md)
and Beads epic `haxe.elixir.codex-msb`. Generic dependency discovery remains a
related ownership policy, not a prerequisite.

## Recommended Order

1. Finish the API-level Haxe stdlib inventory and close every 1.0 runtime gap.
2. Make the complete stdlib conformance lane warning-clean and run it from the installed package.
3. Finish the licensing decision, exact supported-API list, and external release-candidate testing.
4. After 1.0, build the shared model for BEAM contracts and types, plus safe package discovery.
5. Use that same machinery for both the complete typed Elixir stdlib and app-local dependency layers.
6. Promote proven, popular integrations into separately versioned companion packages.

That order keeps the promises honest: portable Haxe is complete at 1.0, while the 1.x line steadily
makes native Elixir and the wider package ecosystem feel first-class from typed Haxe.
