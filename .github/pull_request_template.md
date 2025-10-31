Title: <concise change summary>

Summary
- What changed and why (WHAT/WHY/HOW in 2–4 bullets)
- Affected areas (builder/transformers/printer/std/test)

Guardrails (must pass before review)
- [ ] No app-coupled heuristics (shape/API-based only). No domain tags/strings.
- [ ] No numeric-suffix locals introduced; variable names are descriptive.
- [ ] No edits to generated `.ex` or snapshot `out/` files.
- [ ] QA sentinel run attached (async, bounded). Include RUN_ID and bounded log peek.
- [ ] If todo-app regressed, fixed at the correct layer (compiler/std/example Haxe) and re-verified.

Validation
- [ ] Focused snapshot(s) for impacted domains compiled. If mismatch-only and semantically correct, intended updated with rationale.
- [ ] Non-blocking sentinel compile + GET / passed (paste RUN_ID and key lines):
  - RUN_ID=
  - Port=
  - Key log: “OK: build + runtime smoke passed with zero warnings (WAE)”
- [ ] (Optional) Playwright smoke passed when relevant.

Notes
- Link to shrimp tasks updated (IDs):
- Any deviations from patterns (and why they remain app-agnostic):

