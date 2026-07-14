# Why Reflaxe.Elixir?

Reflaxe.Elixir is for teams that want Haxe's compile-time type system and metaprogramming while
keeping Elixir, Mix, Phoenix, and the BEAM as the application platform.

This page explains the product in practical terms, including where it has a defensible advantage,
where it adds cost, and when Gleam or hand-written Elixir is the better choice.

## Contents

- [The short version](#the-short-version)
- [What "Elixir underneath" means](#what-elixir-underneath-means)
- [Four adoption shapes](#four-adoption-shapes)
- [Elixir-flavored Haxe](#elixir-flavored-haxe)
- [Reflaxe.Elixir and Gleam](#reflaxeelixir-and-gleam)
- [Costs and limits](#costs-and-limits)
- [How to evaluate it](#how-to-evaluate-it)
- [Primary references](#primary-references)

## The Short Version

The compiler turns typed Haxe modules into Elixir source files:

```text
Haxe source -> Haxe typer and macros -> Reflaxe.Elixir -> .ex files -> Mix -> BEAM
```

That gives a project a combination that is otherwise unusual:

- **Gradual adoption:** generate one isolated module or feature without moving the rest of an
  Elixir application.
- **Target-native integration:** use normal Elixir modules and Phoenix/Ecto/OTP APIs instead of a
  separate VM or application runtime.
- **Stronger authoring checks:** validate typed records, enums, result values, routes, assigns,
  changesets, child specs, and extern boundaries while compiling.
- **Reviewable output:** inspect and format the generated `.ex` files with normal Elixir tools.
- **Selective client/server sharing:** compile portable Haxe domain logic to Elixir and JavaScript.
- **Typed metaprogramming:** use Haxe macros and metadata to remove repeated framework glue and
  invalid combinations before target code exists.

The cost is another compiler in the build, a language boundary for the team, and semantic lowering
for Haxe features that Elixir does not share. Those costs are acceptable only where the typed layer
removes more risk or duplication than it introduces.

The product has two natural entry points:

- **Elixir teams** can introduce typed Haxe around high-change domain or framework boundaries while
  most of the application remains hand-written Elixir.
- **Haxe teams** can target the BEAM and author substantial services or Phoenix applications in Haxe
  while retaining Mix, Hex packages, OTP operations, Elixir interop, and ordinary deployment.

Both paths use the same compiler and generated Elixir contract. Neither requires a second production
runtime or an all-at-once rewrite.

The project is GPL-3.0, and generated applications can include support code from this repository.
Commercial distribution therefore needs an explicit licensing review; see
[Licensing & Distribution](../06-guides/LICENSING_AND_DISTRIBUTION.md). This is a product constraint,
not a footnote to discover after adoption.

## What "Elixir Underneath" Means

"It is just Elixir underneath" is directionally useful but too imprecise for an engineering claim.
The accurate contract is:

1. Reflaxe.Elixir emits `.ex` source files.
2. Mix compiles those files with the rest of the application.
3. The deployed release runs on the standard BEAM and does not need Haxe installed.
4. Generated modules can call hand-written Elixir, and hand-written Elixir can call generated
   modules through ordinary module/function/arity contracts.
5. Some portable Haxe semantics require generated helper modules or more explicit lowering. These
   are visible target source, not a second VM, but they are still runtime support.

For example, a direct Elixir-first function may become a normal `case`, `Enum.map`, or Phoenix call.
A portable Haxe float operation must still preserve Haxe's special-value behavior on a VM that does
not represent every value in the same way. Correctness wins over cosmetic similarity in that case.

The relevant architecture contracts are [Authoring Profiles](../02-user-guide/AUTHORING_STYLES_PORTABLE_VS_ELIXIR_FIRST.md),
[`reflaxe_runtime` and Generated Helpers](../02-user-guide/REFLAXE_RUNTIME_EXPLAINED.md),
[Imperative to Functional Lowering](../02-user-guide/IMPERATIVE_TO_FUNCTIONAL_LOWERING.md), and
[Generated Output Quality](../03-compiler-development/GENERATED_OUTPUT_QUALITY_CORPUS.md).

## Four Adoption Shapes

### 1. One Typed Domain Module

Compile into an isolated namespace such as `MyAppHx.*`, then call the generated function from
existing Elixir:

```elixir
MyAppHx.Pricing.quote(cart)
```

This is the lowest-risk evaluation path. It proves build integration, output quality, boundary
types, tests, and debugging before a team commits to framework-facing code.

### 2. One Phoenix Feature

Author a LiveView, schema/changeset boundary, or route declaration in Haxe while keeping the router,
supervision tree, and surrounding modules in Elixir. The generated public surface remains the one
Phoenix expects, such as `mount/3`, `handle_event/3`, or `changeset/2`.

See the [Gradual Adoption Tutorial](../06-guides/PHOENIX_GRADUAL_ADOPTION_TUTORIAL.md) and
[`13-elixir-first-liveview`](../../examples/13-elixir-first-liveview/).

### 3. Shared Browser And Server Logic

Keep a deliberately portable domain classpath and compile it twice:

```text
shared Haxe domain -> Reflaxe.Elixir -> server .ex
                   -> Haxe JS target -> browser .js
```

The shared layer should contain data rules, validation, protocol values, and deterministic domain
logic. Phoenix sockets, Ecto schemas, browser DOM APIs, and other target-specific concerns stay at
their respective edges. [`16-portable-chat-domain`](../../examples/16-portable-chat-domain/) runs the
same domain behavior through Elixir and JavaScript in CI.

### 4. A Haxe-First Application

The compiler can author larger Phoenix surfaces, including routers, LiveViews, templates, Ecto, and
OTP modules. This is the highest-leverage path, but also the highest-commitment path. Use it after the
team has reviewed generated code and accepted the supported-subset contract.

## Elixir-Flavored Haxe

Haxe is a multi-paradigm language, not a purely functional one. It nevertheless has features that
map naturally to Elixir-style design:

- algebraic enums and pattern matching;
- `switch` and conditional expressions that return values;
- structural records (`typedef`) for explicit data shapes;
- local functions, closures, partial application, and higher-order collection operations;
- explicit `Result` and `Option` values;
- metadata and compile-time macros for typed DSLs;
- conditional compilation and multiple source targets.

For target-native output, prefer small pure functions, immutable data flow, typed records, enum
matching, and thin typed externs over broad use of classes, mutation, or portable stdlib machinery.
The documented imperative subset is supported; covered mutation and loop forms lower into immutable
Elixir rebinding rather than pretending the source was already functional. Haxe is broader than the
currently proved compiler surface, so this is not a promise that every legal imperative program works.

This makes Haxe a better bridge to Elixir than treating TypeScript-shaped objects and promises as the
design center, but it does not make every Haxe program Elixir-like automatically. Authoring style is
part of the output contract. See [Writing Idiomatic Haxe for Elixir](../02-user-guide/WRITING_IDIOMATIC_HAXE_FOR_ELIXIR.md).

## Reflaxe.Elixir And Gleam

This is a use-case comparison, not a universal ranking. Gleam is already a stable, production-ready
language. Reflaxe.Elixir is still pre-1.0.

| Dimension | Reflaxe.Elixir | Gleam | Practical consequence |
| --- | --- | --- | --- |
| Primary artifact | Elixir `.ex` source compiled by Mix | Erlang or JavaScript output managed by the Gleam toolchain | Reflaxe.Elixir can live directly in an existing Phoenix source/build model, subject to generated-file ownership rules. |
| Framework macros | Can emit and integrate Elixir/Phoenix macro and DSL shapes | Elixir macros cannot be called from outside Elixir; wrappers are required | Reflaxe.Elixir has the clearer path when Phoenix/Ecto macro integration is central. |
| Language philosophy | Broad, multi-paradigm language with macros, OO, mutation, ADTs, and pattern matching | Small immutable functional language without mutation, exceptions, OO, or language macros | Gleam is easier to reason about as one cohesive functional language; Haxe offers more metaprogramming and migration flexibility. |
| Existing Elixir adoption | Designed for isolated generated namespaces and per-feature replacement | Can compile and call Elixir code through externals | Both interoperate, but Reflaxe.Elixir optimizes for generated Elixir living in the app's normal tree. |
| Cross-target story | Haxe has many targets; this project proves selected Elixir/JavaScript sharing | Erlang and JavaScript are first-class Gleam targets | Haxe offers broader reach; Gleam offers a narrower and more uniform language contract. |
| Native ecosystem access | Typed externs plus generated Elixir wrappers/DSLs | Typed externals to BEAM/JS code; external implementations are outside Gleam's analysis | Both need accurate boundary declarations and runtime tests. |
| Metaprogramming | Haxe build/expression macros and metadata | Deliberately no language macro system today | Haxe can build richer typed project DSLs, with corresponding complexity and compile-time risk. |
| Maturity and community | Pre-1.0, smaller maintainer/adopter base, GPL-3.0 | Stable language, established package/tooling ecosystem | Gleam is the lower organizational-risk choice today. |

### Choose Reflaxe.Elixir When

- the application is already Elixir/Phoenix and generated `.ex` is a requirement;
- adoption must begin with one module or bounded feature;
- Phoenix, LiveView, Ecto, or OTP target conventions must remain visible in generated source;
- Haxe macros can remove meaningful project-specific duplication;
- the team already has Haxe code or needs Haxe's wider target ecosystem;
- selected domain logic must run in both a browser Haxe build and an Elixir service.

### Choose Gleam When

- the project is greenfield and a standalone typed functional stack is desirable;
- enforced immutability and a deliberately small language are primary values;
- the team does not need direct Phoenix macro/DSL integration or generated Elixir source;
- mature 1.x language stability and a larger dedicated ecosystem outweigh Haxe compatibility;
- Erlang/JavaScript portability should use one purpose-built language contract.

### Choose Hand-Written Elixir When

- the module is already clear and small;
- types or macros would not remove repeated boundary risk;
- direct access to a rapidly changing Elixir API matters more than a typed wrapper;
- the team cannot accept another build tool or language.

Reflaxe.Elixir's gradual model makes this a normal outcome, not a failure. Generated and hand-written
modules are expected to coexist.

## Costs And Limits

- **Pre-1.0 status:** use the [Production Readiness](../06-guides/PRODUCTION_READINESS.md) scorecard,
  not the README pitch, for a deployment decision.
- **Compiler surface:** Haxe is broader than Elixir, so not every construct can become a direct target
  form without semantic machinery.
- **Build complexity:** projects add Haxe, Lix, Reflaxe, and generated-source ownership rules. The
  Mix integration fingerprints recursive HXML, Haxe sources on classpaths, resources, libraries,
  toolchain state, and declared macro inputs; macros that read arbitrary non-Haxe files must list
  them with `:extra_inputs`.
  In-place generation does not yet provide one fail-closed ownership protocol for every application
  module. Prefer an isolated generated root and retain clean regeneration in CI as defense in depth
  while that ownership blocker is open.
- **Debugging:** generated Elixir is readable, but experimental source maps do not yet provide a
  complete source-level debugger experience.
- **Ecosystem size:** the compiler and typed Elixir extern ecosystem are much smaller than Elixir's
  and Gleam's communities.
- **Portability boundaries:** Phoenix/Ecto/OTP code is intentionally target-specific. Only a separated
  portable classpath should be shared with JavaScript or other Haxe targets.
- **License:** the compiler is GPL-3.0; review the
  [Licensing and Distribution guide](../06-guides/LICENSING_AND_DISTRIBUTION.md) for project policy.

## How To Evaluate It

1. Start with [`01-simple-modules`](../../examples/01-simple-modules/) and compare Haxe to generated
   Elixir.
2. Add one isolated module and output root to an existing app using the
   [Gradual Adoption Guide](../06-guides/PHOENIX_GRADUAL_ADOPTION.md).
3. Run that module's Elixir tests and compile generated code with warnings as errors.
4. Review generated source for target-native names, data shapes, calls, and error behavior.
5. Pin and checksum the exact release package, then test the exact toolchain versions intended for
   deployment from a clean workspace.
6. Expand only if the typed boundary measurably improves refactoring, duplication, or correctness.

## Primary References

The comparison above is grounded in the projects' own documentation:

- Haxe: [language features](https://haxe.org/documentation/introduction/language-features.html),
  [compiler targets](https://haxe.org/documentation/introduction/compiler-targets.html),
  [macros](https://haxe.org/manual/macro.html), and
  [JavaScript target](https://haxe.org/manual/target-javascript.html).
- Gleam: [frequently asked questions](https://gleam.run/frequently-asked-questions/) and
  [externals guide](https://gleam.run/documentation/externals/).
- Elixir: [typespecs](https://hexdocs.pm/elixir/typespecs.html).
- Reflaxe.Elixir evidence: [Examples](../../examples/README.md),
  [Support Matrix](../06-guides/SUPPORT_MATRIX.md), and
  [Production Readiness](../06-guides/PRODUCTION_READINESS.md).
