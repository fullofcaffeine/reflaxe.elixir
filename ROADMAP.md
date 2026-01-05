# Reflaxe.Elixir Roadmap (v1.1.x)

Reflaxe.Elixir `v1.1.x` is considered **non‑alpha for the documented subset**. This roadmap tracks
near‑term work to harden that subset toward a **1.0 public release**, while continuing to iterate on
explicitly **experimental/opt‑in** surfaces.

Source of truth for “what is production‑ready” is the checklist in `docs/06-guides/PRODUCTION_READINESS.md`.

- **Long‑term vision**: `docs/08-roadmap/vision.md`
- **Curated docs index**: `docs/README.md`
- **Work tracking**: GitHub Issues/Milestones (and `.beads/` for local `bd` workflows)

## Near‑Term Priorities (toward 1.0)

### 1) HXX typing (TSX‑level ergonomics)
- Tighten component prop typing, especially dot‑components and common HEEx helpers.
- Typed slot/`:let` patterns so template usage is typechecked (opt‑in strict mode).
- Typed `phx-hook` names via a shared registry/enum (server + Genes client hooks).

### 2) Tooling & DevX hardening
- Keep Mix tasks, generators, and watchers aligned with the current toolchain (lix‑pinned Haxe, bounded QA sentinel runs).
- Improve failure surfacing (e.g. always show the full compiler output when Haxe compilation fails).
- Ensure docs remain “copy‑paste runnable” for first‑time users.

### 3) CI & release reliability
- CI is Linux + macOS (no Windows lane for now).
- QA Sentinel Smoke stays green (todo‑app boot + Playwright smoke).
- Dogfood stays green (generate a fresh Phoenix app + validate upgrade path).
- Releases are published automatically via semantic versioning (see `docs/10-contributing/RELEASING.md`).

### 4) Performance & transformer simplification
- Reduce reliance on expensive hygiene passes by making key transforms algorithmically bounded.
- Consolidate/merge redundant transformer passes and document ordering guarantees.

## Deferred

- **Haxe 5 support** is intentionally deferred until Haxe 5 stabilizes and provides a consistent TypedExpr.
  A manual smoke script may exist, but Haxe 5 is not part of the current CI contract.

## Status legend

- **Stable**: exercised by CI/tests/examples and covered by the documented subset.
- **Experimental (opt‑in)**: may compile, but expect rough edges and possible breaking changes.
- **Planned**: not implemented yet.
