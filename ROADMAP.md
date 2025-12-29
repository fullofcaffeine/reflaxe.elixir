# Reflaxe.Elixir Roadmap (v1.1+)

Reflaxe.Elixir is currently **alpha** overall. This roadmap tracks what’s next as we expand coverage,
harden experimental features, and improve ergonomics on the path to “exit alpha”.

See `docs/06-guides/PRODUCTION_READINESS.md` for the exit criteria and checklist.

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

### 4) Toolchain Compatibility
- **Haxe 4.3.x** remains the baseline for snapshot comparisons and release CI.
- **Haxe 5 preview/nightly** runs as a *non‑gating smoke* job: compile + Elixir syntax validation only
  (`COMPARE_INTENDED=0`) until Haxe 5 TypedExpr deltas stabilize enough for meaningful diffs.

## Status Legend

- **Stable**: exercised by CI/tests/examples and covered by the documented subset.
- **Experimental (opt‑in)**: may compile, but expect rough edges and possible breaking changes.
- **Planned**: not implemented yet.
