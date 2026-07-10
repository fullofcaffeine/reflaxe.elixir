# Production Hardening and Stable Graduation

> [!IMPORTANT]
> This page is a readiness checklist, not a declaration that stable graduation has happened.
> Reflaxe.Elixir is currently on the pre-1.0 (`v0.x`) release line, and graduation is not approved.
> [Versioning & Stability](VERSIONING_AND_STABILITY.md) is the canonical current status.

This page defines the evidence expected before the project can claim stable graduation and provides
an actionable checklist for keeping the documented subset production-capable as the compiler and
framework layers evolve.

Related docs:
- [Versioning & Stability](VERSIONING_AND_STABILITY.md)
- [Known Limitations](KNOWN_LIMITATIONS.md)
- [Support Matrix (CI toolchains)](SUPPORT_MATRIX.md)
- [Production Deployment](PRODUCTION_DEPLOYMENT.md)
- [Security Policy](../../SECURITY.md)
- [Releasing](../../RELEASING.md)

---

## What readiness means here

Readiness does **not** mean “bug-free”. It means:

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
- [ ] Upgrade path is validated on a fresh generator-created Phoenix app (see [Dogfooding](DOGFOODING.md)).
- [ ] CI covers both a modern toolchain and a minimum supported toolchain (see [Support Matrix](SUPPORT_MATRIX.md)).
- [ ] Experimental tooling (e.g., source mapping) is clearly labeled and does not affect the default UX.
- [ ] Performance budgets are documented and met on the reference apps (see [Performance Guide](PERFORMANCE_GUIDE.md)).

### E) Release process + security posture

- [ ] `CHANGELOG.md` is maintained for user‑visible changes.
- [ ] Release workflow produces usable source artifacts and runs verification first.
- [ ] A basic security process exists (see [SECURITY.md](../../SECURITY.md)).

---

## Current status and historical labels

The root README describes stability in terms of the **documented subset** and calls out experimental/opt‑in
features explicitly. The goal is that the public entrypoints never over‑promise “works everywhere”.

The current release line and graduation state are generated from `release/manifest.json` and summarized
in [Versioning & Stability](VERSIONING_AND_STABILITY.md).

**Historical note (superseded July 2026):** earlier planning drafts used `v1.0.x` for an
“API stabilized” milestone and `v1.1.x` for a “non-alpha” milestone. Those version lines were never
shipped. The actual public lineage remained `v0.x`, so those labels are planning history rather than
release claims.
