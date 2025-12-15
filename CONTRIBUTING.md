# Contributing

Thanks for your interest in contributing to Reflaxe.Elixir.

This repository is a compiler (Haxe → Elixir) and includes:

- the compiler implementation (`src/`)
- target stdlib overrides (`std/`)
- snapshot + integration tests (`test/`)
- example projects (`examples/`)

## Quick Start

```bash
npm install
npm test
```

## Development Commands

```bash
# Full test suite (snapshots + Mix task tests)
npm test

# Compile-check every example under examples/
npm run test:examples

# Guard rails (name heuristics, numeric suffix rules, etc.)
npm run ci:guards
```

## Todo App Runtime Check (Required)

When validating the Phoenix todo-app, never run `mix phx.server` in the foreground.
Use the non-blocking QA sentinel with a deadline:

```bash
scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --async --deadline 600 --verbose
scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 600
```

## Compiler/Stdlib Source Of Truth

Please do not patch generated `.ex` outputs to change behavior.
Make behavior changes in the canonical sources instead:

- compiler pipeline: `src/reflaxe/elixir/**`
- stdlib sources: `std/_std/*.hx` and `std/*.cross.hx`

## Design Guidelines

- No app-specific heuristics in compiler transforms.
- Avoid band-aids/workarounds; fix root causes.
- Prefer precise types (avoid introducing `Dynamic` unless unavoidable at boundaries).

## More Docs

- Documentation index: `docs/README.md`
- Compiler contributor docs: `docs/03-compiler-development/`
