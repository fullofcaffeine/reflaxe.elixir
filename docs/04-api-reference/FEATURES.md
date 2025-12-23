# Feature Support Matrix (Alpha)

Reflaxe.Elixir is **alpha software**. The goal of this document is to be honest and useful: it describes what is *currently* supported by the compiler + stdlib + tooling, and what is still experimental.

If you’re evaluating the project, also read:
- `docs/06-guides/KNOWN_LIMITATIONS.md`
- `docs/06-guides/SUPPORT_MATRIX.md`
- `examples/README.md`

## ✅ Supported (Alpha)

### Core Haxe → Elixir compilation
- **AST pipeline**: TypedExpr → ElixirAST → transformer passes → printer (no string-concat codegen).
- **Deterministic output**: stable codegen for snapshot‑covered constructs.
- **Type mapping**: Haxe types mapped to idiomatic Elixir typespecs where feasible.
- **Pattern matching & guards**: switch/match shapes compiled to `case` + guards.
- **Exceptions**: `try/rescue/catch/after` shapes supported.

### Phoenix (server)
- **LiveView**: `mount/3`, `handle_event/3`, `handle_info/2`, typed assigns patterns, and `render/1` integration.
- **HEEx/HXX**: HXX templates compile to idiomatic `~H""" ... """` with helper support.
- **Router DSL**: Haxe authoured routers compile to `Phoenix.Router` shapes.
- **Controllers**: basic controller/action compilation and routing integration.
- **Presence / PubSub**: supported through framework externs and example coverage.

### Ecto
- **Schemas**: `Ecto.Schema` generation via `@:schema` and field metadata.
- **Changesets**: `@:changeset` generation for common `cast/3` + `validate_required/2` patterns.
- **Migrations (experimental)**: typed migration DSL compiles, but is not yet wired into Ecto’s executable runner (`priv/repo/migrations/*.exs` + `mix ecto.migrate`).

### OTP
- **GenServer**: typed callback surfaces and child spec generation patterns.
- **Supervision**: supervisor trees and registry patterns used in examples.

### Tooling & workflow
- **Mix integration**: `mix compile` support via `Mix.Tasks.Compile.Haxe` and watchers for dev.
- **Haxe compile server**: managed `haxe --wait` lifecycle (opt‑out via `HAXE_NO_SERVER=1`).
- **Source maps**: optional `.ex.map` generation for error tracing back to Haxe.
- **Guardrails**: CI checks for `Dynamic`/`Any`/`untyped` and `__elixir__()` leaks in application code.

### JavaScript (client)
- **Standard Haxe→JS**: use Haxe’s JS target for client code (see todo‑app hooks).
- **Async/await macro support**: available for modern JS output where used by examples/tests.

## 🧪 Experimental / In Flux

- **Project generator (`mix haxe.gen.project`)**: still being refreshed post‑`v1.0.x`; prefer guides + examples if output doesn’t match current flags/toolchain.
- **Performance profiles (`fast_boot`)**: opt‑in development profile that trades some late hygiene for faster iteration on very large modules.
- **Advanced Router/LiveView ergonomics**: improvements land incrementally; expect some churn.

## 🧷 Known Limitations (read this first)

This project prioritizes *idiomatic output* and *typed surfaces* over “just compile at any cost”. The sharp edges are tracked in:
- `docs/06-guides/KNOWN_LIMITATIONS.md`

## How to Verify Locally

From repo root:

```bash
# Full test suite (snapshots + Mix validation)
npm test

# Compile-check every example under examples/
npm run test:examples

# Todo-app integration smoke (non-blocking; includes Playwright)
scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --playwright --e2e-spec "e2e/*.spec.ts" --async --deadline 900 --verbose
```
