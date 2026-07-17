# PhoenixHx: First-Class Opt-In Stock LiveReact Integration

Status: **active implementation record; initial child slices are underway**

Planning date: 2026-07-16

Contract frozen: 2026-07-17 by `haxe.elixir.codex-msb.1`

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
public namespace is `phoenix.live_react`. Stock LiveReact remains the
runtime owner: PhoenixHx will not copy or fork its Phoenix component, DOM
protocol, LiveView hook, React lifecycle, Vite plugin, SSR engines, slots, or
upload behavior.

PhoenixHx owns the typed Haxe/HXX declarations, app-local typed wrappers,
static registry contract, deterministic setup/check/remove tooling, generated
ownership diagnostics, Live Event Protocol adapter, documentation, examples,
compatibility evidence, and installed-package smoke.

The filesystem mutation/recovery layer and thin Mix/bootstrap entrypoints remain
handwritten Elixir because they must work when Haxe compilation is missing or
broken. Above that ring-0 boundary, production surfaces should be authored in
Haxe when practical. Their checked-in generated Elixir is a product artifact:
it must be idiomatic, readable, byte-stable, warnings-as-errors clean, and good
enough to accept in a handwritten code review. Raw target injection and manual
edits to generated output are not quality escape hatches.

The planned first support slice is client-only trusted first-party React islands
with Vite. SSR, slots, uploads, streams, request-selected component names, raw
bridge exposure, Haxe-authored inner React components, and package extraction
are separate follow-ups.

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

### Setup/check/remove slice implemented (`haxe.elixir.codex-msb.4`)

The first reusable lifecycle slice is implemented but remains an internal,
experimental building block for the later consumer and package gates:

- `mix haxe.phoenix.live_react` now plans and atomically publishes the checked
  client-only LiveReact/Vite wiring; `--check` is network-free and read-only;
  `--remove` deletes only marker-, signature-, package-key-, and lock-owned
  state;
- the task supports the exact fixture matrix of root/`assets` package roots and
  the existing Genes/plain-JS client modes, while ambiguous/custom topology
  fails before writes;
- Mix remains the canonical LiveReact resolver and npm receives a relative
  `file:` reference to that checkout. Lock resolution may change only the
  `:live_react` entry, and removal preserves unrelated later lock changes;
- the project generator composes `--live-react` after the ordinary Phoenix
  scaffold instead of defining another client mode;
- focused tests exercise idempotency, deleted generated-file recovery,
  malformed markers, unowned collisions, dependency/checkout drift, exact
  source and lock restoration, retained hand-owned imports, both package-root
  shapes, unsupported SSR, and a real external Mix consumer lifecycle;
- emitted Mix/config files pass `mix format --check-formatted`, and emitted
  JavaScript/Vite files pass `node --check`. This is a concrete gate for the
  handwritten-like generated-source requirement, not a claim that later typed
  island or example output already exists.

Installed-package parity, the independent second consumer, browser behavior,
and the cross-platform compatibility matrix remain owned by `.msb.8` and
`.msb.9`. This slice does not make the LiveReact integration a shipped public
feature.

### Historical proof records remain isolated

The planning input cited historical project-proof tasks that are intentionally
absent from the main Beads database. This plan does not invent missing
dependency targets or import branch-owned records back into main. Any requested
historical note is applied only inside that independently hydrated history.

Task T7 therefore migrates only the current Phoenix chat/React-island proof on
main. An extra route in example 12 would not count as the independent consumer.

## Contract Freeze and Evidence Ledger

The contract task audited the current compiler, scaffold, local proof, event
model, vendored Genes lane, and the exact LiveReact checkout used by example 12.
The following distinctions are deliberate: an observed project proof is not a
public support claim, and a proposed implementation remains unverified until
its child task closes.

| Kind | Evidence | Consequence |
| --- | --- | --- |
| Observed | `RepoDiscovery.hx` excludes compiler source, compiler std, `haxe_libraries`, and dependency caches from app component discovery. `HeexAssignsTypeLinterTransforms.hx` validates module-qualified props only against unambiguous discovered app `@:component` declarations. | A `std/phoenix/live_react` declaration can name the upstream module faithfully, but strict product props belong in a discoverable app-local wrapper. No compiler exception is allowed. |
| Observed | Example 12's app-local `ReactComponents.hx` uses direct inline HXX and emits an ordinary module-qualified `<LiveReact.react ...>` call. | The HXX-to-LiveReact seam is already feasible; the product work is reusable ownership, typing, lifecycle, and packaging. |
| Observed | `HaxePhoenixScaffold` recognizes only `genes` and `plain-js`. The current Genes lane emits JavaScript source that the example's Vite build consumes. | `--live-react` composes after the existing scaffold. Vite is not a third `client_mode`, and Genes is not a second bundler. |
| Observed | The local binder checks markers, signatures, package keys, a static registry, source identity, reruns, and recovery, but remains project-specific. Current scaffold writes are atomic per file rather than one filesystem-atomic multi-file transaction. | Shared patch primitives must validate the whole plan before writes and provide staged publication plus rollback/recovery semantics. The project-local JavaScript binder is evidence, not reusable product code. |
| Observed | `LiveEventProtocolModel.hx` already owns normalized wire names, payload fields/kinds, a deterministic manifest, and a hash. | React event contracts adapt this model. A second event enum, DSL, decoder runtime, or independent string registry is rejected. |
| Observed | The pinned LiveReact checkout exposes `LiveReact.react`, `LiveReact.Reload.vite_assets`, `LiveReact.Test.get_react`, `getHooks`, `useLiveReact`, `Link`, and the stock Vite plugin. Its browser bridge is intentionally broad. | PhoenixHx may declare stable public surfaces honestly, but must not copy their implementation or pass the raw bridge into the default inner component type. Open test/helper shapes must not receive false precision. |
| Observed | Example 12 currently pins one LiveReact Git revision independently in Mix and npm, and both pins identify revision `055e80e6a4e6d009df5e229eb39e7f85f03fea22`. | This proves one project-local identity match. The reusable tool instead makes Mix canonical and points npm at the resolved Mix checkout so the two sides cannot drift independently. |
| Observed | `haxe_libraries/genes.hxml` uses the repository's vendored Genes copy; a sibling checkout is not a clean-build or package dependency. | The initial integration supports current `genes` and `plain-js`. Released `genes-ts` adoption stays in the nonblocking migration task. |
| Unknown until implementation | Cross-platform package-root discovery, crash-safe rollback, installed-package template availability, and the ecosystem version matrix have not yet been proven. | Those claims remain gates in `.msb.3`, `.msb.4`, `.msb.8`, and `.msb.9`; this contract does not advertise them as shipped. |

### Frozen decision table

| Topic | Frozen decision | Rejected interpretation |
| --- | --- | --- |
| Repository and package | Implement in this monorepo and initially ship in the existing Haxelib as an opt-in surface. | A new repository, a PhoenixHx-owned Hex runtime, or an immediate companion-Haxelib split. |
| Haxe namespace | `phoenix.live_react`; the low-level owner is `phoenix.live_react.LiveReact`, mapped to upstream module `LiveReact`. | App-specific namespaces or a compiler-recognized pseudo component. |
| Lifecycle CLI | `mix haxe.phoenix.live_react` applies; `--check` is read-only; `--remove` removes owned state. `--check` and `--remove` are mutually exclusive. | A project-local Node script as the public interface or a command that writes during check. |
| Generator composition | `mix haxe.gen.project --phoenix --live-react`, optionally with either existing `--client-mode genes` or `--client-mode plain-js`. | `live-react` as a client mode, authoring profile, compiler backend, or semantic switch. |
| Initial browser/runtime slice | Trusted first-party, statically named, client-only islands with `ssr=false`, stock React, stock LiveReact, and Vite. | SSR, slots, uploads, streams, ambient/dynamic lookup, hostile-code sandboxing, or broad default bridge access. |
| Strict type owner | A discoverable app-local `@:component` wrapper with closed assigns, a literal registry name, and fixed client-only policy. | Claiming that the low-level std declaration validates arbitrary application props. |
| Registry | A generated, signature-owned, statically imported registry from a closed project manifest. Starter business files become hand-owned after creation. | Runtime globs, request-selected modules, overwriting edited starters, or deleting business source during removal. |
| Events | Project existing Live Event Protocol normalized model and explicit server dispatch; TypeScript projection only for honestly representable closed payloads. | A second event system or widening unsupported codecs/open payloads to `any`, `unknown`, or `Dynamic` while claiming safety. |
| Runtime ownership | Stock LiveReact owns the Phoenix component, DOM protocol, hook, React lifecycle, Vite plugin, SSR, slots, and uploads. | Porting, vendoring, copying, or forking upstream runtime behavior. |
| Dependency identity | Mix resolves `:live_react`; npm consumes that exact checkout via a project-relative `file:` reference in supported topologies. | Independently choosing a semver, tarball, branch, or revision on the npm side. |
| Asset ownership | Vite is the sole JavaScript bundler when enabled. Genes may emit ESM source for Vite; Tailwind remains an independent CSS lane. | Simultaneous Vite and esbuild JavaScript pipelines or treating Genes as another bundler. |
| Mutation safety | Whole-plan read/validate/render first, signature/marker ownership, staged per-file atomic publication, rollback on reported publication failure, and deterministic check/recovery. | Best-effort mutation, warning through an ownership conflict, or claiming power-loss-level multi-file filesystem atomicity. |
| Compatibility status | Experimental 1.x until two independent consumers and installed-package smoke pass; support is only the checked matrix rows. | A Reflaxe.Elixir 1.0 blocker or broad ecosystem compatibility inferred from one canary. |
| Genes | Keep the hermetic vendored Genes lane for this epic and support plain JS; migrate reviewed improvements through `haxe.elixir.codex-m52`. | Depending on `../genes`, silently switching generated output, or blocking client-only LiveReact on genes-ts migration. |
| Promotion/split | Promote only after example 12, an independent minimal project, installed-package smoke, and focused CI. Consider a separate Haxelib only after independent cadence/adoption evidence. | Counting another example-12 route as the second consumer or splitting for aesthetics alone. |

## Product Contract

### Public posture

- Same Git monorepo and same Haxelib initially.
- Opt-in namespace: `phoenix.live_react`.
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
- The lifecycle task's initial public options are setup by default, mutually
  exclusive `--check` and `--remove`, `--yes` for noninteractive apply/remove,
  `--warn-only` for non-destructive advisory findings only, and an explicit
  project-relative `--package-root` override. Ownership, identity, or malformed
  marker failures remain fatal in every mode. Unsupported SSR flags reject.
- The initial support label is experimental/opt-in.
- No new task in this graph blocks `haxe.elixir.codex-0yn`.

### Initial topology contract

The implementation targets canonical PhoenixHx projects with an existing Mix
project, a standard LiveSocket entry, and one detected npm package root. The
candidate matrix is the two existing client modes crossed with a root or
`assets/` package root. A combination becomes supported only after its exact
fixture row passes setup, check, rerun, recovery, remove, compile, and package
smoke; untested rows remain experimental rather than implied support.

An explicitly supplied `--package-root` must be project-relative, remain inside
the project after symlink resolution, and contain the selected `package.json`.
Multiple candidate roots, custom bundler ownership, ambiguous hook construction,
or hand-owned Vite configuration outside a checked shape produces a read-only
manual-integration report. The tool must not guess.

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

The low-level `phoenix.live_react.LiveReact` declaration maps faithfully to the
upstream `LiveReact` module and its `react` component entry point. Optional
`Reload` or `Test` declarations are allowed only when their upstream public
shape can be represented honestly; open helper results stay open rather than
receiving invented fields.

Compiler std and dependency roots are intentionally excluded from app component
discovery. Strict product prop validation therefore belongs in an app-local
discoverable `@:component` wrapper with closed assigns, a fixed component name,
and a fixed client-only posture. The wrapper emits ordinary inline HXX such as:

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
- npm LiveReact resolves to the Mix-owned checkout through the checked
  project-relative `file:` reference;
- registry names are unique and static;
- unsupported options such as SSR reject explicitly;
- every removal target is provably owned.

Any failure reports what was found, what was expected, the affected location,
that no writes occurred, and a safe corrective action.

### Apply

Render and validate the complete plan before publishing. Use shared atomic
marker/signature/package ownership primitives. Stage every new file and retain
the original content needed to roll back each owned target before the first
rename. Publish each file with an atomic same-filesystem replace, then publish
the manifest last. If a reported publication step fails, restore already
published targets and report recovery/check commands; never report success for
a partial state. This is a tool-level rollback contract, not a claim that a
multi-file update survives process kill, kernel failure, or power loss as one
filesystem transaction. A later `--check` and rerun must deterministically
recover any such externally interrupted state.

### Check

Recompute desired state without writing and report dependency, marker,
generated file, registry, source-identity, topology, and capability drift.

### Remove

Remove only owned blocks and files. Retain hand-owned components and unrelated
Vite/React use. Remove package keys only when still exclusively owned. Leave a
compiling base PhoenixHx project or fail before mutation.

## Dependency and Asset Identity

Mix is the canonical resolver for `:live_react`. The task resolves the dependency
through the Mix project and lock, then derives a portable identity:

- Git: normalized repository identity plus the resolved full commit;
- Hex: package, resolved version, and lock checksum;
- path: project-relative normalized path plus the dependency package version;
- any other source: unsupported until the contract gains an explicit identity
  algorithm and tests.

Each PhoenixHx release carries a checked default LiveReact Mix declaration in
its compatibility data. Apply behaves as follows:

1. an absent dependency is proposed/added using that checked default;
2. an existing dependency with a supported resolved identity is retained;
3. an existing conflicting or unverified dependency is reported and left
   untouched;
4. dependency resolution must produce a lock identity before setup can report
   success or publish the completed integration.

If Mix resolution needs intermediate project-file changes, those files belong
to the same rollback journal as the other owned edits. A failed resolution may
leave ordinary ignored download/cache data, but tracked project files are
restored. `--check` is network-free and never resolves or fetches dependencies;
it reports a missing/stale lock as drift.

npm consumes the actual Mix checkout through a project-relative `file:` entry,
normally the relative path from the selected package root to
`deps/live_react`. Setup and check resolve that path, require it to name the same
checkout Mix selected, and inspect the lockfile rather than accepting a matching
display string. The manifest stores the portable Mix identity and relative npm
reference, never an absolute resolved path. Missing locks, an independently
pinned npm tarball/Git/registry package, a path escaping the project, or an
unprovable source fails closed in check mode and cannot be reported as a
successful apply. A future override needs a separately reviewed identity rule;
`--warn-only` cannot bypass this check.

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
- At the 2026-07-17 audit, `../genes` was a developer checkout rather than a
  pinned release input. Any sibling path is unavailable to CI, installed
  packages, and clean adopters regardless of its later working-tree state.
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

The initial schema identifier is frozen as `phoenixhx.live-react@1`. Its logical
shape is:

```json
{
  "schema": "phoenixhx.live-react@1",
  "integrationVersion": "<tool version>",
  "assetMode": "vite",
  "packageRoot": "assets",
  "liveReact": {
    "mixSourceKind": "git",
    "resolvedIdentity": "<portable lock identity>",
    "npmReference": "file:../deps/live_react"
  },
  "runtimePolicy": {
    "trustedFirstPartyOnly": true,
    "ssr": false,
    "slots": false,
    "uploads": false,
    "streams": false,
    "rawBridgeDefault": false
  },
  "components": [
    {
      "name": "PreferenceStudio",
      "module": "./preference-studio-boundary",
      "export": "PreferenceStudioBoundary"
    }
  ],
  "managed": {
    "files": [],
    "markers": []
  }
}
```

Keys and component entries are rendered deterministically. All paths are
slash-normalized project-relative paths without `..`; the file records
ownership and integration topology, not machine-local resolution results or a
universal Haxe-to-TypeScript prop schema. An unknown newer schema refuses to
write. An older schema changes only through an explicit, tested migration that
first validates its prior signatures and ownership; setup never silently
reinterprets it.

## Compatibility and Release Policy

The checked matrix uses four statuses with narrow meanings:

- `tested`: that exact row passed the checked source/package/runtime gates;
- `compatible-by-contract`: an explicitly bounded range is justified by public
  upstream contracts plus at least one tested boundary row;
- `experimental`: planned or partially evidenced, but not a support promise;
- `unsupported`: rejected or known not to satisfy the initial contract.

Every row records Reflaxe.Elixir/PhoenixHx, Haxe, Elixir/OTP, Phoenix, LiveView,
the exact LiveReact source identity, React/ReactDOM, Vite, Node posture,
package-root topology, client mode, asset mode, and SSR/capability posture. The
matrix must link the commands or CI evidence that earned its status.

The current example-12 evidence is recorded only as a project-local proof:

| Evidence row | Known values | Status |
| --- | --- | --- |
| Example 12 local binder | Phoenix `1.7.24`; LiveView `0.20.17`; LiveReact Git commit `055e80e6a4e6d009df5e229eb39e7f85f03fea22`; React/ReactDOM `19.1.0`; Vite `7.2.7`; root package; Genes source mode; client-only | `experimental` project proof, not the reusable product matrix |

The task does not infer Haxe, Elixir/OTP, Node, other package-root, or other
version support from that row. `.msb.9` must record the exact tested toolchain
and package-smoke rows before promotion.

The integration stays experimental until both consumers and installed-package
smoke pass. A separate Haxelib is considered only after real evidence of an
independent compatibility/release cadence, package-size impact, multiple
adopters, or separate maintainership. Package separation does not require a
new Git repository.

## Implementation Phases

1. **Complete (2026-07-17):** freeze ownership, API, CLI, manifest,
   compatibility, and Genes boundaries.
2. **Complete (2026-07-17):** API-faithful Haxe/HXX declarations and shared
   patch ownership/recovery primitives are integrated and verified.
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
- checked-in generated Elixir review, byte-stable regeneration,
  warnings-as-errors, and handwritten-output quality evidence for each
  Haxe-owned production module;
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
15. Haxe-owned production output must remain idiomatic and handwritten-like;
    bootstrap/recovery infrastructure stays handwritten Elixir where it must
    operate without a working Haxe compiler.

## Rollout

Ship only after the implementation graph closes, initially as experimental and
opt-in in the existing Haxelib. Projects that do not enable it remain
unchanged. Preserve manual integration for unsupported topologies. Promote
status only after two consumers, package smoke, compatibility evidence, and
focused CI. Deferred capabilities remain explicitly unsupported until their
own tasks close.
