# `reflaxe_runtime` and Generated Elixir Helpers

Two separate mechanisms have similar names:

| Mechanism | What it does | Who uses it |
| --- | --- | --- |
| `-D reflaxe_runtime` | Lets Haxe type the Reflaxe.Elixir compiler implementation outside macro mode. | Compiler contributors and development tooling |
| Generated Elixir helpers | Preserve Haxe behavior that has no exact, safe native Elixir representation. | Generated applications, through compiler-emitted calls |

The define does not enable, disable, or configure the generated helpers. It is
not an Elixir runtime mode, deployment profile, or application dependency.

## Application builds do not need the define

Normal applications select the target with `-lib reflaxe.elixir`:

```hxml
-lib reflaxe.elixir
-cp src_haxe
-D elixir_output=lib
Main
```

The library configuration supplies the `elixir` target marker and initializes
the compiler. Do not add `-D reflaxe_runtime` to a new application HXML file.
Older projects can remove it; keeping the redundant define while upgrading does
not select a different application backend.

## When `reflaxe_runtime` is needed

The compiler normally runs as Haxe macro code. An editor, direct type-check, or
compiler-development build may instead need to see that implementation as
ordinary Haxe code. Reflaxe-generated compiler repositories use the define for
that narrow development context:

```hxml
# DevEnv.hxml inside the compiler repository
-D reflaxe_runtime
-lib reflaxe
-cp src
reflaxe.elixir
```

Repository fixtures that deliberately bypass `-lib reflaxe.elixir` and type
compiler source directly may also need it. Application fixtures that only need
to select Elixir APIs should use the `elixir` target marker instead.

This is a repository-layout convention, not a cross-target application API.
Other Reflaxe compilers can assign their own target-specific meaning to a
similarly named define, so copy the consumer HXML contract for the target being
used rather than transferring flags between compilers.

## How generated code is chosen

Reflaxe.Elixir follows a compiler-first order of preference:

1. **Compile-time lowering.** Use facts already known by the Haxe typer and AST
   pipeline. Proven `Int` arithmetic stays native; a proven fresh one-to-one
   Array projection can become `Enum.map`; HXX becomes Phoenix `~H`.
2. **Typed target APIs.** Calls through `elixir.*`, `phoenix.*`, `ecto.*`, and
   OTP externs become direct target calls, callback shapes, tuples, or macros.
3. **Target stdlib overrides.** A portable Haxe API maps to an ordinary BEAM
   primitive when the contracts match, such as selected crypto APIs using
   `:crypto` and map surfaces using `Map` / `Enum`.
4. **Compatibility lowering or helpers.** When native syntax would change Haxe
   behavior, keep the difference explicit and centralized.

Examples of the last step include:

- `Reflaxe.Elixir.HaxeFloat` for Haxe `NaN`, infinity, parsing, formatting, and
  comparisons whose operands are not proven ordinary finite numbers;
- `Reflaxe.Elixir.HaxeThrow` for Haxe's ability to throw and catch arbitrary
  values rather than only Elixir exception structs;
- selected Haxe stdlib facades whose complete behavior is not yet an exact
  direct Elixir call.

This is the same broad design principle used by the sibling Ruby and Rust
targets: prefer target-native lowering, make semantic support explicit, and do
not hide a second application VM underneath the generated source. The exact
helpers and inclusion policy differ because Ruby, Rust, and Elixir have
different runtime semantics.

## Current helper inclusion policy

Helper **calls** are selective: concrete `Int` arithmetic does not call
`HaxeFloat`, and code that never throws a Haxe value does not need a
`HaxeThrow` call site.

The two core helper **modules** are currently less selective. Backend passes can
introduce calls after Haxe dead-code elimination has decided which Haxe types to
keep. To prevent generated code from referencing a missing module,
`CompilerInit.hx` force-types and keeps both helper types. Consequently,
`Reflaxe.Elixir.HaxeFloat` and `Reflaxe.Elixir.HaxeThrow` are emitted in normal
generated builds, including `-dce full`, even when a particular application has
no call site for one of them.

That is a conservative support-footprint policy, not evidence that every
application executes a compatibility runtime. Making module inclusion safely
demand-driven is tracked in the
[generated-output idiomaticity roadmap](../08-roadmap/generated-elixir-idiomaticity-audit.md#generated-support-footprint).
Until that work lands, describe the current contract as **selective helper
calls with conservatively retained core helper modules**, not "helpers are
emitted only when needed."

## Portable and Elixir-first code

Both authoring profiles use the same compiler pipeline and both aim for
idiomatic Elixir:

- **Typed Elixir-first** source gives the compiler direct BEAM/Phoenix concepts
  and usually produces the most handwritten-looking target shape.
- **Portable stdlib-first** source preserves cross-target Haxe behavior first,
  while still using native Elixir whenever that behavior can be proven equal.

Portable code is not an unidiomatic mode. A helper or facade is appropriate
only when it protects a real semantic difference or when a safer native
lowering has not yet been proven. See
[Authoring Profiles](AUTHORING_STYLES_PORTABLE_VS_ELIXIR_FIRST.md) and
[Standard Library Handling](../04-api-reference/STANDARD_LIBRARY_HANDLING.md).

## Source and package parity

The repo-local `haxe_libraries/reflaxe.elixir.hxml` and packaged
`extraParams.hxml` both supply the same target marker and initialize the same
compiler. CI compiles a representative project through source and built-package
layouts and compares generated output. The Reflaxe `_std` build layout changes
where target overrides are found; it does not select different lowering or
runtime semantics.

## Related reading

- [Compiler Flags Guide](../01-getting-started/compiler-flags-guide.md)
- [Source Checkout vs Release Package](../01-getting-started/SOURCE_VS_PACKAGE_LAYOUT.md)
- [Target-Conditional Stdlib Gating](../05-architecture/TARGET_CONDITIONAL_STDLIB_GATING.md)
- [Imperative to Functional Lowering](IMPERATIVE_TO_FUNCTIONAL_LOWERING.md)
- [Generated Elixir Quality Corpus](../03-compiler-development/GENERATED_OUTPUT_QUALITY_CORPUS.md)
