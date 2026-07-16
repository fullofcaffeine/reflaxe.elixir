# PhoenixHx: First-Class Opt-In Stock LiveReact Integration

Status: **active planning record; implementation has not started**

Planning date: 2026-07-16

Planning horizon: **1.x; not a Reflaxe.Elixir 1.0 blocker**

## Beads

The planning graph uses these generated IDs:

- Epic: `haxe.elixir.codex-msb`
- Contract: `haxe.elixir.codex-msb.1`
- Haxe/HXX bindings: `haxe.elixir.codex-msb.2`
- Shared patch ownership: `haxe.elixir.codex-msb.3`
- Setup/check/remove: `haxe.elixir.codex-msb.4`
- Static registry and typed wrapper scaffold: `haxe.elixir.codex-msb.5`
- Live Event Protocol alignment: `haxe.elixir.codex-msb.6`
- Example 12 migration: `haxe.elixir.codex-msb.7`
- Independent example: `haxe.elixir.codex-msb.8`
- Documentation/package/CI gate: `haxe.elixir.codex-msb.9`
- Haxe-authored React follow-up: `haxe.elixir.codex-a06`
- SSR follow-up: `haxe.elixir.codex-8yk`
- Extended capability follow-up: `haxe.elixir.codex-c9w`
- Separate-Haxelib follow-up: `haxe.elixir.codex-mqj`
- Genes dependency migration follow-up: `haxe.elixir.codex-m52`

## Decision Summary

PhoenixHx will provide an opt-in authoring and project-integration layer for
stock `live_react` in this monorepo and, initially, the existing Haxelib. The
recommended namespace is `phoenix.live_react`. Stock LiveReact remains the
runtime owner: PhoenixHx will not copy or fork its Phoenix component, DOM
protocol, LiveView hook, React lifecycle, Vite plugin, SSR engines, slots, or
upload behavior.

PhoenixHx owns the typed Haxe/HXX declarations, app-local typed wrappers,
static registry contract, deterministic setup/check/remove tooling, generated
ownership diagnostics, Live Event Protocol adapter, documentation, examples,
compatibility evidence, and installed-package smoke.

The first supported slice is client-only trusted first-party React islands with
Vite. SSR, slots, uploads, streams, request-selected component names, raw bridge
exposure, Haxe-authored inner React components, and package extraction are
separate follow-ups.

## Current Evidence and Important Deviations

### Observed on `main`

`examples/12-phoenix-chat` already proves the seam:

- a direct-inline HXX app-local wrapper emits a module-qualified
  `LiveReact.react` component call;
- stock LiveReact supplies the hook and Vite plugin;
- a static generated TypeScript registry selects a trusted boundary component;
- a project-local manifest and JavaScript patcher fail closed on ownership
  conflicts and support rerun/check/recovery;
- Vite is the bundler while Genes remains a Haxe-to-JavaScript source compiler;
- Haxe, Mix, TypeScript, React, Vite, Playwright, and fallback evidence exists;
- SSR, slots, uploads, streams, ambient dynamic lookup, and broad bridge access
  are deliberately excluded.

This evidence proves feasibility, not a reusable public product.

### Historical proof records remain isolated

The planning input cited historical project-proof tasks that are intentionally
absent from the main Beads database. This plan does not invent missing
dependency targets or import branch-owned records back into main. Any requested
historical note is applied only inside that independently hydrated history.

Task T7 therefore migrates only the current Phoenix chat/React-island proof on
main. An extra route in example 12 would not count as the independent consumer.

## Product Contract

### Public posture

- Same Git monorepo and same Haxelib initially.
- Opt-in namespace: `phoenix.live_react` unless the contract task finds a
  repository convention that requires an equivalent spelling.
- Primary lifecycle command:

  ```bash
  mix haxe.phoenix.live_react
  mix haxe.phoenix.live_react --check
  mix haxe.phoenix.live_react --remove
  ```

- Greenfield composition:

  ```bash
  mix haxe.gen.project --phoenix --client-mode genes --live-react
  mix haxe.gen.project --phoenix --client-mode plain-js --live-react
  ```

- `--live-react` is orthogonal to `client_mode`; it is not a third client
  mode or a compiler backend.
- The initial support label is experimental/opt-in.
- No new task in this graph blocks `haxe.elixir.codex-0yn`.

### Meaning of native PhoenixHx React use

A Haxe developer can declare a static React island from supported direct
inline HXX without raw target injection. Haxe types describe server inputs and
event payloads. Generated Elixir remains ordinary Phoenix/HEEx calling stock
`LiveReact.react`. Browser code remains ordinary TypeScript/JavaScript, React,
Vite, and stock LiveReact. Setup and removal are deterministic and owned.

“Native” does not mean rewriting LiveReact in Haxe or Elixir.

## Goals

1. Render a statically named stock LiveReact island through supported Haxe/HXX.
2. Keep all runtime semantics upstream-owned.
3. Add no React/Vite/Node changes unless explicitly enabled.
4. Make setup, check, rerun, recovery, upgrade, and removal fail closed.
5. Use closed app-local Haxe assigns, a static registry, and a trusted boundary
   that narrows native capabilities.
6. Compose Vite with both existing client modes; Vite is the only JavaScript
   bundler in the enabled asset lane.
7. Prove the public integration in the current example 12 plus an independent
   minimal example.
8. Prove source-checkout and installed-package behavior under a checked
   compatibility contract.

## Initial Non-Goals

- porting, vendoring, or forking LiveReact;
- compiler transforms that recognize LiveReact or component names;
- a separate PhoenixHX Hex runtime;
- SSR or production Node worker supervision;
- slots, uploads, streams, or raw bridge capability by default;
- dynamic/request-controlled component lookup;
- a sandbox claim for untrusted React code;
- automatic arbitrary TypeScript-to-Haxe prop conversion;
- a new client mode or compiler backend;
- generic Mix dependency adoption;
- a separate Git repository;
- a 1.0 release dependency;
- broad untested Phoenix/LiveView/LiveReact/React/Node/Vite compatibility.

## Two-Plane Architecture

### PhoenixHx-owned authoring and integration plane

```text
Haxe assigns and event types
  -> app-local @:component wrapper
  -> direct inline HXX
  -> generated ordinary HEEx
  -> stock LiveReact.react
```

PhoenixHx also owns setup/check/remove, static registry generation, generated
ownership metadata, diagnostics, event-contract projection, docs, and evidence.

### Upstream-owned runtime plane

```text
LiveReact.react
  -> upstream DOM/prop protocol
  -> stock ReactHook
  -> static application registry
  -> React createRoot/hydrateRoot
  -> application React component
```

The repository must not copy the hook, renderer, DOM protocol, or Vite plugin.

## HXX and Application Type Boundary

The low-level `phoenix.live_react` declaration maps faithfully to upstream
modules. Strict product prop validation belongs in an app-local discoverable
`@:component` wrapper with closed assigns, a fixed component name, and a fixed
client-only posture. The wrapper emits ordinary inline HXX such as:

```haxe
return <LiveReact.react
  id=${assigns.id}
  name="PreferenceStudio"
  title=${assigns.title}
  density=${assigns.density}
  ssr=${false}
/>;
```

Conceptual generated target:

```elixir
<LiveReact.react
  id={@id}
  name="PreferenceStudio"
  title={@title}
  density={@density}
  ssr={false}
/>
```

No compiler special case or raw Elixir string is justified.

## Static Registry and Trusted Boundary

A schema-versioned project manifest owns integration topology and sorted static
component entries. A signature-owned generated registry imports exact modules
and exports a closed component-name type. Duplicate names, missing modules or
exports, unowned generated paths, and dynamic ambient lookup fail closed.

Starter Haxe and TypeScript/TSX source becomes hand-owned after creation. The
trusted boundary may receive LiveReact's broad bridge, but the inner component
receives only validated public props and semantic callbacks. This is capability
narrowing for trusted first-party code, not a hostile-code sandbox.

## Event Contract

The integration reuses the existing Live Event Protocol normalized model and
explicit LiveView dispatch. It does not introduce another event enum, DSL, or
runtime. Supported closed payloads may produce deterministic TypeScript names,
interfaces, and validators. Unsupported custom codecs require an app-owned
adapter; they are never widened while being called type-safe. Inner React
components receive semantic callbacks rather than raw `pushEvent` by default.

## Setup, Check, and Remove

### Read-only discovery

Discover the Mix project, PhoenixHx/client mode, package root, current bundler,
LiveSocket entry, root layout, watcher and aliases, Vite config, LiveReact Mix
dependency and lock identity, manifest/signatures, static registry, and custom
topology indicators without writing.

### Validation before writes

- marker pairs are absent or uniquely well-formed;
- generated paths are absent or correctly signed;
- package keys are absent, already equal, or integration-owned;
- the desired state leaves exactly one JavaScript bundler;
- LiveSocket and Vite insertion points are unambiguous;
- npm LiveReact resolves to the Mix-owned checkout or a reviewed override;
- registry names are unique and static;
- unsupported options such as SSR reject explicitly;
- every removal target is provably owned.

Any failure reports what was found, what was expected, the affected location,
that no writes occurred, and a safe corrective action.

### Apply

Render and validate the complete plan before publishing. Use shared atomic
marker/signature/package ownership primitives. Update the integration manifest
only as part of a transaction that cannot report partial success.

### Check

Recompute desired state without writing and report dependency, marker,
generated file, registry, source-identity, topology, and capability drift.

### Remove

Remove only owned blocks and files. Retain hand-owned components and unrelated
Vite/React use. Remove package keys only when still exclusively owned. Leave a
compiling base PhoenixHx project or fail before mutation.

## Dependency and Asset Identity

Mix is the canonical resolver for `:live_react`. npm should consume the same
resolved checkout, normally through a project-relative `file:` dependency.
Canaries record the exact source kind and resolved identity. If a supported
topology cannot prove identity, setup/check fails or requires a reviewed
explicit override. It never installs an unrelated npm LiveReact version.

Vite is the sole JavaScript bundler in the enabled lane. Genes may generate ESM
source that Vite consumes. Tailwind remains independent unless a project
explicitly assigns CSS ownership to Vite. Existing unowned asset pipelines are
reported, not rewritten heuristically.

## Genes Dependency Decision

### Observed

- This repository tracks `vendor/genes` as ordinary files at upstream Genes
  0.4.14 plus local No-Dynamic, source-map typing, async-marker, and emission
  changes. `haxe_libraries/genes.hxml` makes `-lib genes` hermetic.
- The sibling `../genes` checkout is `genes-ts` 1.32.0, a renamed and greatly
  expanded compiler: 74 source files versus 25 here and roughly 15,000 added
  source lines. It adds strict TypeScript/TSX, React inline markup, explicit
  async helpers, transactional output, import/dependency plans, richer source
  maps, and a bounded classic-ESM compatibility path.
- `../genes` is a dirty developer checkout containing untracked review bundles.
  A sibling path is unavailable to CI, installed packages, and clean adopters.
- `genes-ts` publishes an MIT Haxelib package and documents both TypeScript and
  classic ESM modes, but its broad change set is not output-compatible by
  assumption; this repository's generated client corpus must prove migration.

### Decision

The initial LiveReact epic does **not** replace Genes and never points to
`../genes`. It must work with the current public `genes` client mode and with
plain JS. React components remain app-owned TSX/JSX in the first slice, so the
new genes-ts React compiler surface is not required.

Create a separate nonblocking P3 task to evaluate replacing the vendored 0.4.14
copy with an exact released `genes-ts` artifact. The preferred long-term shape
is a pinned released dependency plus a repository-controlled compatibility
alias/configuration, not a live sibling checkout. Vendoring a reviewed
genes-ts snapshot remains a fallback only if package installation cannot meet
offline, source/package parity, or deterministic release requirements.

Migration must inventory every local patch, compile all current Genes examples,
compare generated ESM and source maps, preserve both client modes and package
smoke, and document rollback. It is not a prerequisite for client-only
LiveReact. The Haxe-authored inner React follow-up may depend on the migration
only after that task proves the new compiler boundary.

## Versioned Integration Manifest

The initial schema is conceptually `phoenixhx.live-react@1` and records:

- integration schema/version;
- asset mode and package root;
- Mix source kind and resolved LiveReact identity;
- trusted-first-party/client-only feature posture;
- sorted static component entries;
- signature-owned files and marker-owned blocks.

It has deterministic key ordering, no machine-local paths, explicit schema
migration behavior, and no claim to be a universal cross-language prop schema.

## Compatibility and Release Policy

The checked matrix distinguishes tested, compatible-by-contract, experimental,
and unsupported combinations. It records Reflaxe.Elixir/PhoenixHx, Haxe,
Elixir/OTP, Phoenix, LiveView, exact LiveReact source identity, React/ReactDOM,
Vite, Node posture, package-root topology, client mode, and SSR status.

The integration stays experimental until both consumers and installed-package
smoke pass. A separate Haxelib is considered only after real evidence of an
independent compatibility/release cadence, package-size impact, multiple
adopters, or separate maintainership. Package separation does not require a
new Git repository.

## Implementation Phases

1. Freeze ownership, API, CLI, manifest, compatibility, and Genes boundaries.
2. Add API-faithful Haxe/HXX declarations and shared patch primitives.
3. Implement setup/check/remove and the static registry/wrapper scaffold.
4. Align typed events with Live Event Protocols.
5. Migrate the current example 12 local binder.
6. Add an independent minimal consumer through public commands.
7. Publish implementation-time docs, compatibility evidence, package smoke,
   and focused CI.

## Required Evidence

- HXX positive snapshots and honest negative fixtures;
- marker/signature/package/atomicity setup lifecycle tests;
- Genes and plain-JS canonical project fixtures;
- exact Mix/npm LiveReact identity checks;
- deterministic registry and starter ownership tests;
- Live Event Protocol Haxe/TypeScript contract tests;
- strict TypeScript/React/Vite/source-map evidence;
- Haxe-authored ExUnit and bounded Playwright fallback evidence;
- source-checkout and installed-package setup/check/remove smoke;
- both examples in `examples/qa-manifest.json` with named runtime/E2E coverage;
- path hygiene, docs links, Beads lint/dependency sanity, and latest CI.

Snapshots prove generated shape, not runtime behavior. Two passing examples
prove only their named compatibility matrix, not arbitrary ecosystem support.

## Blocking Graph

```text
haxe.elixir.codex-msb.1
├── haxe.elixir.codex-msb.2
└── haxe.elixir.codex-msb.3
    └── haxe.elixir.codex-msb.4

haxe.elixir.codex-msb.2 + haxe.elixir.codex-msb.4
    └── haxe.elixir.codex-msb.5

haxe.elixir.codex-msb.5
    └── haxe.elixir.codex-msb.6

haxe.elixir.codex-msb.4 + .5 + .6
    ├── haxe.elixir.codex-msb.7
    └── haxe.elixir.codex-msb.8

haxe.elixir.codex-msb.7 + haxe.elixir.codex-msb.8
    └── haxe.elixir.codex-msb.9
```

Deferred follow-ups `haxe.elixir.codex-a06`, `haxe.elixir.codex-8yk`,
`haxe.elixir.codex-c9w`, `haxe.elixir.codex-mqj`, and
`haxe.elixir.codex-m52` are discovered from the epic and do not block it or
Reflaxe.Elixir 1.0.

## Cross-Cutting Invariants

1. Stock LiveReact owns runtime behavior.
2. No compiler special case or new backend/profile is introduced.
3. Non-enabled projects receive no React/Vite/Node changes.
4. Vite is the one bundler; Genes remains a source compiler when selected.
5. Mix and npm resolve one LiveReact identity.
6. Component names and registry membership are static and reviewable.
7. App-local wrappers own strict props and product policy.
8. Default boundaries narrow capabilities and make no sandbox claim.
9. Existing Live Event Protocols remain the sole PhoenixHx event model.
10. Setup/check/remove are atomic, idempotent, reversible, and fail closed.
11. Example 12 and the independent example are genuinely separate consumers.
12. Installed-package behavior must match source checkout.
13. No task in this graph blocks the 1.0 readiness epic.
14. No local sibling path or machine-local absolute path is part of the ABI.

## Rollout

Ship only after the implementation graph closes, initially as experimental and
opt-in in the existing Haxelib. Projects that do not enable it remain
unchanged. Preserve manual integration for unsupported topologies. Promote
status only after two consumers, package smoke, compatibility evidence, and
focused CI. Deferred capabilities remain explicitly unsupported until their
own tasks close.
