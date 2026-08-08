# Support Matrix

This page describes what toolchain versions Reflaxe.Elixir is **known to work with**.

## CI‑tested versions (source of truth)

Our GitHub Actions CI runs primarily on **Ubuntu**, plus a macOS smoke job. CI currently tests:

- Full suite (primary toolchain, Ubuntu):
  - Node.js: `22.14.0`
  - Haxe: `4.3.7`
  - Elixir: `1.18.3`
  - Erlang/OTP: `27.2`

- Minimum toolchain smoke (compat check, Ubuntu):
  - Node.js: `22.14.0`
  - Elixir: `1.14.x`
  - Erlang/OTP: `25.x`
  - Parses the complete checked-in generated corpus with Elixir 1.14, compiles and executes focused
    stdlib and OTP contracts, then runs `npm run test:mix-fast`.
  - The primary toolchain independently proves that the checked-in corpus matches current compiler
    output; neither environment's green result substitutes for the other compatibility claim.
  - Note: `npm run test:mix-fast` feature-detects newer Mix flags (e.g. `--stale`) to stay compatible with Elixir `1.14`.

- macOS smoke (bounded):
  - Node.js: `22.14.0`
  - Haxe: `4.3.7`
  - Elixir: `1.18.3`
  - Erlang/OTP: `27.2`
  - Compiles and executes the same focused stdlib and OTP contracts, then runs
    `npm run test:mix-fast` to cover filesystem/process behavior and the Mix compiler path on macOS.
    Platform compatibility does not repeat the primary toolchain's full compiler-conformance corpus.

The first corrected hosted run of these focused lanes (`30735021490`, commit `195fa5c9a`) completed
the macOS smoke in 5m 30s and the minimum-toolchain smoke in 7m 23s. The latter parsed all 267 tracked
generated fixtures with none missing. These timings describe CI feedback speed; the support claims
still come from the independent contracts listed above, not from duration or from another lane being
green.

Additionally, the **QA Sentinel Smoke** workflow boots the todo-app on Ubuntu (Postgres + Phoenix) and runs a small Playwright suite.

Phoenix coverage:

- `examples/todo-app` pins Phoenix `~> 1.7.24` and is exercised via the QA sentinel workflow (boot + Playwright smoke).
- The runnable Phoenix/Ecto examples use the primary Elixir `1.18.3` / OTP `27.2` toolchain. Their
  current security-patched dependency graph requires Elixir `1.16+` (notably Swoosh `1.26.3`).
  This does not raise the compiler's Elixir `1.14+` minimum: the minimum-toolchain job validates the
  compiler and runtime libraries, while application dependencies set their own higher requirements.

## Experimental LiveReact rows

PhoenixHx's LiveReact support is optional and still experimental. Here,
**tested** has a deliberately narrow meaning: the exact versions in one row
passed that row's named build, server, and browser checks together. A green row
does not silently promise that another Phoenix, LiveView, React, or Genes
version will work.

All three browser-tested applications currently use React and ReactDOM
`19.1.0`, Vite `7.2.7`, and stock LiveReact at Git revision
`055e80e6a4e6d009df5e229eb39e7f85f03fea22`.

| Tested consumer | Browser source | Phoenix / Phoenix HTML / LiveView | What the row proves |
| --- | --- | --- | --- |
| `examples/12-phoenix-chat` | Haxe/Genes bootstrap with a handwritten TSX React component | `1.7.24` / `4.3.0` / `0.20.17` | A richer chat app mounts React, completes a typed event, keeps Presence working, and retains its LiveView fallback. |
| `examples/18-phoenixhx-live-react` | Plain TypeScript; Genes is not used | `1.8.9` / `4.3.0` / `1.2.8` | A small independent project installs the integration, mounts React, completes one event round trip, and retains its LiveView fallback. |
| `examples/todo-app` | Haxe through Genes | `1.7.24` / `3.3.4` / `0.20.17` | The flagship app adds a React island without losing create, edit, complete, delete, or fallback behavior. |
| Installed GitHub Release package (Haxelib-compatible ZIP) | No browser is started | dependency stubs for `1.8.9` / `4.3.0` / `1.2.8` | A clean installed archive exposes the setup and component commands, restores files on removal, and compiles the same HXX wrapper as the source checkout. This row does **not** claim browser compatibility for the stubs. |

The two Genes rows declare Genes `1.37.0` from exact temporary pull-request
commit `697943b1c10b72309d815b0f6a5605d7c5c2a53b`. That makes today's tests
repeatable; it is not a claim that the commit is a final upstream release. The
plain-TypeScript row demonstrates that installing LiveReact does not require
Genes when the browser component is not authored in Haxe.

The machine-readable [LiveReact compatibility data](live-react-compatibility.json)
contains the full toolchain, dependency identity, package layout, capability
limits, and exact CI evidence owner for every row. CI checks that file against
the actual lockfiles, manifests, and browser jobs. Server-side React rendering, slots, uploads,
streams, request-selected component names, a broad raw browser bridge, and
isolation for untrusted React code remain outside the current PhoenixHx
integration.

Windows is not currently tested and is outside the supported 1.0 operating-system contract. This is
an explicit scope boundary, not a claim that the compiler cannot work there.

## Haxe 5 preview strategy

Haxe `5.x` is treated as a preview toolchain for this repository. The CI source of truth remains Haxe `4.3.7`; Haxe 5 is available through a local smoke command:

```bash
npm run test:haxe5
```

That smoke switches Lix to `HAXE5_VERSION` (default: `nightly`), restores the previous `.haxerc` afterward, then runs:

- snapshot compilation with `COMPARE_INTENDED=0`
- generated Elixir syntax validation
- `npm run test:mix-fast`

Snapshot intended-output diffs are intentionally disabled for Haxe 5. Haxe 5 can produce different typed AST / `TypedExpr` shapes for equivalent source programs, and those differences can cascade into harmless generated-output ordering or helper-shape drift. Until Haxe 5 becomes part of the supported CI matrix, this repo should not maintain a separate Haxe 5 `intended/` baseline or normalize Haxe 5-only diffs in the compiler pipeline.

The policy is:

- Haxe `4.3.7` snapshots are the golden generated-output contract.
- Haxe 5 preview validation proves the compiler still accepts the suite and emits parseable Elixir.
- If a Haxe 5 run exposes a semantic bug, fix the shared compiler behavior and cover it with the normal Haxe `4.3.7` snapshot/runtime suites when possible.
- Revisit separate Haxe 5 baselines only when Haxe 5 is stable enough to become a CI-supported toolchain.

## Minimum versions (documented)

These are the minimum versions we **document and test** for repository tooling and generated code:

- Haxe `4.3.7` (the golden typed-AST and generated-output contract)
- Node `22.14.0+` for the supported repository/Lix tooling path
- Elixir `1.14+` for the compiler and generated runtime
- Erlang/OTP `25+` for the compiler and generated runtime
- Elixir `1.16+` for the checked-in Phoenix/Ecto examples' current dependency graph

Later Haxe `4.x` versions may work, but CI does not sweep them and this page does not imply their
typed AST is byte-for-byte equivalent to `4.3.7`. Haxe 5 remains preview-only as described above.

If you need support for a specific older version, open an issue and include your constraints.

## What is *not* tested (yet)

- Phoenix `1.6.x` and earlier
- Haxe `5.x` in CI (local preview smoke only; see the Haxe 5 preview strategy above)
- Windows

If you run successfully on other versions, please report it so we can expand the matrix.
