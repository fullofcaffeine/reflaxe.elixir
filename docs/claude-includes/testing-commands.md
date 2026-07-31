# Essential Testing Commands

The canonical policy is
[Testing Strategy](../03-compiler-development/TESTING_INFRASTRUCTURE.md).
Choose commands by the behavior being changed; do not treat one suite as proof
of every layer.

## 🚀 Feedback-loop Commands

### R0 — Focused Owner
```bash
make -C test test-core__<case>             # One compiler snapshot
npm run test:core                         # One snapshot category
npm run test:stdlib                       # Stdlib compiler shapes
npm run test:regression                   # Focused regressions
```

### R1 — Runtime/Claim Smoke
```bash
npm run test:runtime-smoke                 # Small Haxe -> Elixir -> BEAM path
npm run test:haxe-exunit-stdlib           # Haxe-authored stdlib semantics on BEAM
npm run test:mix-fast                     # Mix/compiler integration
```

### Application Integration
```bash
# Agent-safe, non-blocking, bounded lifecycle
scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --async --deadline 600 --verbose
scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 60
```

### Broad Local Aggregate (Part of R4)
```bash
npm test                                 # Compiler/runtime aggregate; CI owns the complete graph
npm run test:test-feedback-observer      # Advisory selector/timing contract; skips no CI jobs
```

## 🔍 Test Analysis Commands

### Build System
```bash
mix deps.get                              # Install Elixir dependencies
mix compile                               # Standard Elixir compilation
mix format                                # Code formatting
```

### Development Workflow
```bash
# Debugging
mix compile --verbose                     # Verbose compilation output
MIX_ENV=test mix compile --force          # Force recompilation
```

## ⚠️ Critical Test Rules

- Start with the smallest semantic owner; widen using the canonical change map.
- `npm run test:changed` is advisory only until it has reviewed ownership and
  selector-miss evidence.
- Runtime claims require runtime execution; snapshots alone are insufficient.
- Cross-cutting compiler/runtime/runner changes require `npm test`.
- Todo-app validation is required when application/runtime behavior can change
  and must use the agent-safe sentinel lifecycle.
- **Update snapshots only when compiler output legitimately improves**
- **Fix broken tests immediately, don't ignore as "unrelated"**
