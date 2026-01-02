# Todo App Development Roadmap

## Current: Genes ES6 Module Compilation

As of **2026-01-02**, the todo-app client build uses **Genes** to generate split ES6 modules from Haxe.

**Why this is the canonical setup**
- ✅ Split, readable ES module output (better than a single generated blob)
- ✅ Compatible with esbuild and Phoenix’s asset pipeline
- ✅ Keeps LiveView Hooks 100% Haxe-authored while preserving Phoenix’s JS bootstrap

**How it’s wired**
- `build-client.hxml` enables Genes via `--macro genes.Generator.use()`.
- Output entry module: `assets/js/hx_app.js` (imports `client.Boot` and calls `Boot.main()`).
- Supporting modules are emitted under `assets/js/client/**` and `assets/js/genes/**`.

## Historical: Standard Haxe JS Compilation

Before Genes, the todo-app used Haxe’s standard JavaScript target (`-js`) to generate a single output file. This was simple and stable, but produced less idiomatic JS and made client-side output harder to navigate.

## Notes / Options

- To compare against the standard Haxe JS generator, you can compile with `-D genes.disable` (see the Genes docs).
