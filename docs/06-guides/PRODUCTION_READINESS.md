# Production Readiness (Non‑Alpha Criteria)

Reflaxe.Elixir `v1.0.x` is **alpha software**: it is feature‑complete enough to build real Phoenix apps, but it is not yet **production‑hardened**.

This page defines what “non‑alpha / production‑ready” means for this project and provides an actionable checklist to get there.

Related docs:
- [Known Limitations](KNOWN_LIMITATIONS.md)
- [Support Matrix (CI toolchains)](SUPPORT_MATRIX.md)
- [Production Deployment](PRODUCTION_DEPLOYMENT.md)
- [Security Policy](../../SECURITY.md)
- [Releasing](../../RELEASING.md)

---

## What “non‑alpha” means here

“Non‑alpha” does **not** mean “bug‑free”. It means:

1. **Correctness first**: the compiler reliably preserves semantics for the documented subset of Haxe and framework integrations.
2. **Stable output contracts**: generated Elixir is idiomatic and does not depend on example‑specific hacks.
3. **Upgrades are predictable**: changes follow a clear versioning policy and are backed by tests.
4. **Operationally safe**: recommended defaults do not require fragile local setup and CI catches regressions early.

---

## Exit criteria checklist

### A) Compiler correctness + semantics

- [ ] The documented language subset in `docs/02-user-guide/` matches reality (no “it compiles but breaks at runtime” surprises for covered features).
- [ ] The AST pipeline (Builder → Transformer → Printer) has no known “shape corruption” classes of bugs without regression coverage.
- [ ] Snapshot suites cover the highest‑risk transforms (pattern matching, control‑flow rewrites, macro‑expanded Phoenix constructs).
- [ ] No correctness fixes are landing as runtime `.ex` band‑aids; behavior changes come from `src/` or `std/` sources (see root `AGENTS.md`).

### B) Framework integration quality (Phoenix/Ecto/OTP)

- [ ] Todo‑app remains a “real Phoenix app” and stays green under the QA sentinel (boot + Playwright) without manual steps.
- [ ] LiveView multi‑session updates are tested (PubSub broadcast + handle_info wiring).
- [ ] Ecto schema/changeset flows are exercised by examples and tests.
- [ ] Migrations are either **production‑ready** (documented subset + tests) or explicitly **experimental** and opt‑in (clearly labeled).
- [ ] OTP surfaces (GenServer/Supervisor/Registry) have snapshot + Mix/runtime validation.

### C) Output quality (idiomatic Elixir)

- [ ] No systematic Elixir warnings in generated app code under normal builds (unused vars, underscored vars used, etc.).
- [ ] No app code *requires* `__elixir__()` / raw injection to function (escape hatches remain optional, not the happy path).
- [ ] Generated code is readable: stable naming, minimal compiler‑generated “bridge variables”, and documented when unavoidable.

### D) Tooling + developer experience

- [ ] “Getting started” path works end‑to‑end (install → compile → run a Phoenix app) using the documented guides:
  - [Phoenix (New App)](PHOENIX_NEW_APP.md)
  - [Phoenix (Existing App)](PHOENIX_GRADUAL_ADOPTION.md)
- [ ] CI covers both a modern toolchain and a minimum supported toolchain (see [Support Matrix](SUPPORT_MATRIX.md)).
- [ ] Experimental tooling (e.g., source mapping) is clearly labeled and does not affect the default UX.
- [ ] Performance budgets are documented and met on the reference apps (see [Performance Guide](PERFORMANCE_GUIDE.md)).

### E) Release process + security posture

- [ ] `CHANGELOG.md` is maintained for user‑visible changes.
- [ ] Release workflow produces usable source artifacts and runs verification first.
- [ ] A basic security process exists (see [SECURITY.md](../../SECURITY.md)).

---

## When we’ll remove the Alpha warning

We should remove the “Alpha software” banner from the root README only when:

- The checklist above is substantially complete (or explicitly waived with justification), **and**
- The CI history shows stability across multiple releases, **and**
- The docs no longer require “tribal knowledge” to build and run the examples.

Until then, `v1.0.x` remains the “API stabilized, not production‑hardened” line (see `ROADMAP.md`).
