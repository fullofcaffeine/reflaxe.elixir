Title: Haxe @:using Metadata in Reflaxe.Elixir

Overview

- Haxe’s @:using metadata attaches extension methods to an existing type. In Reflaxe.Elixir we use it to add macro-powered APIs without bloating the runtime representation.

Why we use @:using for TypedQuery<T>

- Goals:
  - Keep ecto.TypedQuery<T> lean at runtime (opaque query struct wrapper).
  - Provide type-safe, compile-time-validated query builders.
  - Generate idiomatic Ecto.Query code (e.g., t.field == ^value) from Haxe lambdas.

- How:
  - We annotate typed queries with @:using(reflaxe.elixir.macros.TypedQueryLambda) so calls like `query.where(u -> u.name == value)` are resolved by a macro.
  - The macro inspects the lambda, validates schema fields, and emits correct Ecto DSL with pinned runtime expressions.

Benefits

- Compile-time safety: invalid fields fail the build early.
- Idiomatic output: emitted Elixir follows standard Ecto.Query patterns.
- No stringly-typed APIs: avoids drift and silent runtime failures.

Notes

- Macro code only runs at macro time; the extension type remains thin at runtime.
- Keep macro-only imports/logic within `#if macro` to prevent non-macro compile errors.

