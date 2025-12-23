# Reflaxe.Elixir Roadmap (Alpha)

Reflaxe.Elixir is **alpha software**: it is usable today (especially for Phoenix/LiveView/Ecto experimentation), but it is **not production‑hardened** yet.

Version `v1.0.x` reflects API/feature stabilization and CI coverage — **not** a promise of production readiness.

- **Long‑term vision**: `docs/08-roadmap/vision.md`
- **Curated docs index**: `docs/README.md`
- **Work tracking**: GitHub Issues/Milestones (and `.beads/` for local `bd` workflows)

## Near‑Term Priorities (post‑1.0)

### 1) Performance + Pass Simplification
- Reduce reliance on `fast_boot` by making expensive hygiene passes algorithmically bounded.
- Consolidate/merge redundant transformer passes and document ordering guarantees.

### 2) Tooling + Scaffolding
- Keep Mix tasks and generators aligned with current flags/toolchain (`lix`, `-D elixir_output`, etc.).
- Provide a minimal greenfield Phoenix scaffold and a gradual adoption path for existing apps.

### 3) Stability + Guardrails
- Expand example coverage and E2E tests (todo‑app QA sentinel + Playwright).
- Tighten policy guardrails (no `Dynamic`/`Any` leaks; no `__elixir__()` in application code).

## Status Legend

- **Supported (Alpha)**: exercised by CI/tests/examples, but not production‑hardened.
- **Experimental**: may compile, but expect rough edges and breaking changes.
- **Planned**: not implemented yet.
