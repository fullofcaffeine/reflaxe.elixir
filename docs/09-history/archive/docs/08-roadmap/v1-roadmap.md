# Reflaxe.Elixir v1.0 PRD and Roadmap

Goal: Idiomatic, AST‑based Haxe→Elixir compilation that generates hand‑quality Elixir for Phoenix/Ecto/OTP with a thin, fast Playwright E2E layer. No app‑specific name heuristics. Deterministic outputs verified by snapshots and a bounded QA sentinel.

## Scope (v1.0)
- AST pipeline only (Builder → Transformer → Printer)
- Phoenix: LiveView, Components, Router, Endpoint, Presence, minimal Channels
- Ecto: Schemas, Changesets, Query DSL (from/where/order_by/preload, join assoc/dynamic, fragment)
- Stdlib: pragmatic native externs (StringBuf, StringTools, Date/Time essentials)
- ExUnit authored in Haxe (ConnTest/LiveViewTest), Playwright smoke in TS

## Acceptance Gates
- [ ] Snapshots green (positive + negative): `make -C test summary` (no unexpected diffs)
- [ ] QA sentinel smoke green within deadline: 
      `scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --playwright --e2e-spec "e2e/*.spec.ts" --e2e-workers 1 --deadline 900`
- [ ] No generated `.ex` edits; only Haxe/std/transform changes
- [ ] No app‑coupled strings or heuristics in transforms
- [ ] No `Dynamic` on new public surfaces (No‑Dynamic policy)
- [ ] Gettext backend modernized (no deprecation warnings)
- [ ] Example warnings reduced; no harmful warnings in CI

## Deliverables
- Compiler passes: hygiene, HEEx, Ecto DSL breadth (pass 1), Presence, minimal Channels
- Example app: todo‑app with typed events/assigns, stable DOM, fast E2E
- CI workflow: bounded sentinel run + artifacts for logs

## CI Strategy (Sentinel)
- Use GitHub Actions to install Haxe/Elixir/Node; cache npm/mix
- Pre‑install Playwright Chromium to keep runs fast
- Run sentinel with serial workers and generous deadline for first runs
- Upload `/tmp/qa-*.log` and the main run log as artifacts

## Non‑Goals (v1.0)
- Full Channels breadth (beyond minimal)
- Advanced Ecto DSL codegen beyond current shapes
- Broad client generation (genes) beyond existing minimal patterns

## Post‑1.0 Roadmap (Sketch)
- Consolidate micro‑passes into domain modules (Collections, PubSub, Ecto, LiveView, Hygiene)
- Extend Ecto DSL (subqueries, select_merge, dynamic/field) with snapshots
- Channels breadth; Typed channel payloads and helpers
- Genes: expand async/await patterns and shared component surfaces

