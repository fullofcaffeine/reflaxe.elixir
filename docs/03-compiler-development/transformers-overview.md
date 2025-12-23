# Transformer Passes Overview

Reflaxe.Elixir uses an ordered set of **AST transformation passes** to bridge the semantic gap between:

- Haxe’s typed AST (imperative / OOP‑friendly shapes) and
- idiomatic Elixir (functional / immutable / pattern‑matching‑first).

This file is the “read me first” for working on passes.

## Where Passes Live

- Pass registry (ordering, enablement, grouping):
  - `src/reflaxe/elixir/ast/transformers/registry/ElixirASTPassRegistry.hx`
- Transformer entrypoint (registry execution):
  - `src/reflaxe/elixir/ast/ElixirASTTransformer.hx`
- Generated ordering snapshot:
  - `docs/05-architecture/TRANSFORM_PASS_REGISTRY_ORDER.md`

## Design Rules (Hard Requirements)

1. **Shape‑based, not name‑based**
   - Do not key transforms on app/domain identifiers (e.g., “todo”, “cancel_edit”).
2. **No band‑aids**
   - Fix the root shape or analysis; do not “skip” or “cap” patterns to hide bugs.
3. **Keep it linear**
   - Prefer one walk + symbol tables/analyzers over repeated full‑tree scans.
4. **Printer stays dumb**
   - Semantic rewrites belong in builder/transformer, not the printer.

## Pass Authoring Checklist

- Add hxdoc to the transformer: WHAT / WHY / HOW / EXAMPLES.
- Keep the transformer under ~2,000 LOC (extract helpers if needed).
- Add/update snapshots when output semantics change.
- Verify the todo‑app boots via QA sentinel (async + deadline).

## Debugging Pass Work

- `-D debug_pass_metrics` — emits when a pass changes the AST.
- `-D debug_ast_pipeline` / `-D debug_ast_transformer` — stage‑level tracing.

