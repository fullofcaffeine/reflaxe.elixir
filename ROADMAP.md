# Reflaxe.Elixir Roadmap (v1.1.x)

Reflaxe.Elixir `v1.1.x` is considered **non‑alpha for the documented subset**. This roadmap tracks
near‑term work to harden that subset toward **production readiness**, while continuing to iterate on
explicitly **experimental/opt‑in** surfaces.

Source of truth for “what is production‑ready” is the checklist in `docs/06-guides/PRODUCTION_READINESS.md`.

- **Long‑term vision**: `docs/08-roadmap/vision.md`
- **Curated docs index**: `docs/README.md`
- **Work tracking**: `.beads/` (`bd list`) + GitHub Issues/PRs

## Recently shipped (v1.1)

- **TSX-level HXX typing**: strict components + strict slots, typed `:let`, typed `phx-*` events/hooks (opt-in, exercised in todo-app).
- **DevX hardening**: faster incremental builds, clearer watcher errors (full raw Haxe output), fewer “port already in use” footguns.
- **CI reliability**: Linux + macOS lanes, docs smoke + dogfood, deterministic budgets.
- **Semver releases**: GitHub releases are published automatically via semantic-release (see `docs/10-contributing/RELEASING.md`).

## Near‑term priorities (v1.1.x maintenance)

### 1) Production polish
- Keep docs “copy/paste runnable” for first-time users (install, test, QA sentinel, dogfood).
- Keep the todo-app as a reliable end-to-end showcase (Phoenix boot + Playwright smoke stays green).
- Improve error reporting further where it saves time (compiler diagnostics, Mix integration).

### 2) Compiler maintainability
- Continue consolidating transformer passes where safe, documenting ordering guarantees and invariants.
- Prefer “shape-derived” transforms over name heuristics, and keep new transforms fully documented (hxdoc WHAT/WHY/HOW/EXAMPLES).

### 3) CI & release reliability
- Keep CI green on Linux + macOS (Windows is intentionally out of scope for now).
- Ensure QA Sentinel Smoke + dogfood lanes remain representative and bounded (no hangs).
- Keep release automation “boring”: tags + GitHub releases + CHANGELOG always in sync.

## Future (not 1.1.x)

### Haxe 5 support (deferred)
- Haxe 5 is intentionally deferred until it stabilizes and provides a consistent TypedExpr.
- A smoke script may exist, but Haxe 5 is not part of the current CI contract.

## Status legend

- **Stable**: exercised by CI/tests/examples and covered by the documented subset.
- **Experimental (opt‑in)**: may compile, but expect rough edges and possible breaking changes.
- **Planned**: not implemented yet.
