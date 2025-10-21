Phoenix E2E, Environments, and QA Sentinel

Overview
- Primary tests are written in Haxe and compiled to idiomatic ExUnit (ConnTest/LiveViewTest).
- A thin Playwright (JS) layer provides real‑browser smoke/regression checks.
- QA Sentinel orchestrates non‑blocking build → boot → readiness → optional E2E.

Environments
- dev: fast iteration; PORT optional; secret_key_base allows env override or fallback.
- test: SQL Sandbox enabled; dedicated todo_app_test DB; optional env override for secret.
- e2e: dedicated todo_app_e2e DB; server: true; PORT from env; optional env secret.
- prod: strict runtime config in config/runtime.exs — SECRET_KEY_BASE/PORT required.

QA Sentinel
- Layers
  - Layer 1: Haxe snapshot tests (outside sentinel) — make -C test summary.
  - Layer 2: Compiler→Phoenix runtime — Haxe build, deps, compile, boot, GET / + log scan.
  - Layer 3: App E2E (browser) — optional Playwright run against the running server.
- Flags
  - --env NAME (dev|test|e2e|prod). If --playwright set and --env omitted, defaults to e2e.
  - --reuse-db (non‑dev): skip drop; ensure create + migrate for faster local runs.
  - --seeds PATH: run seeds after migrations (e.g., priv/repo/seeds.e2e.exs).
  - --playwright + --e2e-spec "e2e/*.spec.ts": run Playwright; sentinel sets BASE_URL.

Usage
- Keep‑alive (local E2E):
  - scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4011 --keep-alive -v
  - BASE_URL=http://localhost:4011 npx -C examples/todo-app playwright test e2e/<spec>.ts
- One‑shot E2E (CI‑style):
  - scripts/qa-sentinel.sh --app examples/todo-app --playwright --e2e-spec "e2e/*.spec.ts" --deadline 600

Testing Strategy
- Testing Trophy: emphasize Phoenix integration (ExUnit) + thin E2E.
- Selectors: prefer role/label/text (user perspective). Use data-testid only when necessary.

Secrets
- dev/test/e2e: allow env overrides with safe fallback.
- prod: required via config/runtime.exs — no fallbacks.

