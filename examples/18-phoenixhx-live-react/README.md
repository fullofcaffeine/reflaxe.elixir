# PhoenixHx + LiveReact

This example proves the complete `plain-js` LiveReact path: Haxe authors the
Phoenix LiveView, its closed props, and one typed browser event; ordinary strict
TypeScript owns the React island; Vite builds it; and stock LiveReact joins the
two at runtime. The signal console is deliberately interactive so browser QA
proves that React mounted and completed a real round trip to Phoenix, not just
that HTML loaded. This client-only example does not use server-rendered React
or hydration.

If those names are unfamiliar, begin with
[Add a React component to a PhoenixHx LiveView](../../docs/02-user-guide/PHOENIX_LIVE_REACT.md).
It explains the parts in plain language, then returns here for the smallest
runnable project.

## Run it locally

From this directory:

```bash
mix setup
mix phx.server
```

Open [http://localhost:4000](http://localhost:4000), then transmit a pulse and
cycle the channel. Both controls should update immediately without a page
reload.

`mix phx.server` is the normal interactive development command for this
example. Its Phoenix endpoint starts the development watchers:

- the Mix Haxe compiler watches server-side Haxe and emits Elixir;
- Vite and Tailwind rebuild the browser assets.

There is intentionally no `mix dev` alias here. The todo app defines one
because it must create and migrate PostgreSQL before starting Phoenix; this
example has no database to prepare. `mix phx.server` is therefore the complete
local flow.

The Phoenix browser packages in `package.json` use `file:deps/...` references.
That makes npm package the JavaScript from the exact Phoenix and LiveView
checkouts selected by Mix instead of resolving unrelated versions from the npm
registry. The checked-in `.npmrc` enables npm's `install-links` mode so those
local packages are installed like application dependencies, without also
installing the contributor-only test and documentation dependencies from the
Phoenix source repositories. Keep these references and `mix.lock` together;
otherwise the browser and BEAM server can load incompatible LiveView protocol
versions even though each side compiles successfully.

The application path is the same for interactive developers and automated
agents. The operational difference is process supervision: a person can own a
foreground server and stop it with Ctrl-C, while an automated run needs a
bounded background process with guaranteed teardown. The repository QA
sentinel provides that supervision—readiness probes, captured logs, a deadline,
Playwright, and cleanup—without changing how the app builds or runs.

## What owns each layer

```text
SignalConsoleIsland.hx
  -> generated Phoenix component and HEEx LiveReact call
  -> static TypeScript registry and trusted prop/event boundary
  -> signal-console.tsx
  -> stock LiveReact pushEvent
  -> SignalConsoleLive.hx on the BEAM
```

- `src_haxe/phoenixhx_live_react_hx/components/live_react/SignalConsoleIsland.hx`
  owns the closed server props and the fixed component name.
- Generated Elixir under `lib/phoenixhx_live_react_hx/**` is checked in as the
  compiler emitted it so reviewers and drift checks inspect the real Phoenix
  target; change its Haxe source instead of editing the `.ex` file.
- `src_haxe/phoenixhx_live_react_hx/live/SignalConsoleEvents.hx` is the single
  event declaration. The Haxe build generates the matching strict TypeScript
  validator and Phoenix dispatcher from it.
- `assets/react-components/signal-console-boundary.tsx` validates the values
  crossing from LiveReact and discards native bridge capabilities that this
  component does not need.
- `assets/react-components/signal-console.tsx` is the application-owned React
  implementation.
- `assets/react-components/registry.generated.ts`, `vite.config.mjs`, and
  `assets/js/live-react-hooks.js` are owned by
  `mix haxe.phoenix.live_react`.

The Haxe wrapper:

```haxe
return <LiveReact.react
  id=${assigns.id}
  name="SignalConsole"
  title=${assigns.title}
  ssr=${false}
/>;
```

produces the ordinary Phoenix target shape:

```heex
<LiveReact.react
  id={@id}
  name="SignalConsole"
  title={@title}
  ssr={false}
/>
```

Haxe provides a typed source boundary and earlier feedback; Phoenix and stock
LiveReact still own rendering, LiveView hook integration, and the React
lifecycle at runtime.

## Genes versus plain JavaScript

LiveReact and Genes solve different problems:

- LiveReact mounts a statically registered React component inside Phoenix
  LiveView.
- Genes compiles browser code authored in Haxe to JavaScript modules.

PhoenixHx remains useful in `plain-js` mode: server modules, typed assigns, and
HEEx wrappers can be Haxe-authored while browser hooks and React components stay
in JavaScript or TypeScript. Choose `plain-js` when there is no browser Haxe to
compile.

Choose `genes` when the browser bootstrap, hooks, event protocol, or React
component is authored in Haxe. This example is intentionally `plain-js`: there
is no `build-client.hxml`, Genes dependency, Haxe browser watcher, or generated
Haxe JavaScript. The todo app provides the separate Genes-first LiveReact proof.
In both modes, Vite is the sole final bundler.

## Verification

Fast server-side and integration checks:

```bash
mix test
mix haxe.phoenix.live_react --check
npm run typecheck
mix assets.build
```

`mix test` first compiles `src_haxe/test/web/PageSmokeTest.hx` to ExUnit, then
checks that Phoenix renders the typed island and accepts the shared event.
`npm run typecheck` checks the application-owned React boundary and generated event
adapter without emitting JavaScript. The Haxe compiler's generated Elixir is
checked in so regeneration drift is reviewable. `mix assets.build` runs the
Haxe server compile, Tailwind, and Vite from the same clean-checkout path used
in release builds; Vite emits source maps.

The real-browser contract is:

```bash
../../scripts/qa-sentinel.sh \
  --app examples/18-phoenixhx-live-react \
  --port 4018 \
  --playwright \
  --e2e-spec "e2e/signal_console.spec.ts" \
  --e2e-workers 1 \
  --async \
  --deadline 900 \
  --verbose
```

Use the printed run ID with:

```bash
../../scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 180
```

That browser test proves React hydrated, a typed React event reached Phoenix,
the server-owned count came back to React, and the native LiveView fallback can
perform the same action without the island.

## Setup, repair, and removal

The [canonical guide](../../docs/02-user-guide/PHOENIX_LIVE_REACT.md#add-livereact-to-a-project)
explains the general workflow. These commands show the exact choices used by
this `plain-js` example.

The checked-in project was created and enabled through public Mix tasks. The
same lifecycle is available to another PhoenixHx application:

```bash
# Enable or repair the managed stock LiveReact/Vite integration
mix haxe.phoenix.live_react --yes

# Verify dependency identity, marker ownership, registry, and generated files
mix haxe.phoenix.live_react --check

# Register compatible application-owned source without overwriting it
mix haxe.gen.live_react SignalConsole \
  --existing \
  --module ./signal-console-boundary \
  --export SignalConsoleBoundary \
  --yes

# Remove only integration-owned files and marker blocks
mix haxe.phoenix.live_react --remove --yes
```

If setup is interrupted, rerun the first command; the task detects and recovers
its transaction before applying new changes. If `--check` reports drift, review
the named file, then rerun setup to restore managed content. Component Haxe and
TypeScript files are application-owned and survive integration or registry
removal.

In this repository checkout, the four stock browser packages are deliberately
application-owned `file:deps/...` values. The setup task accepts and preserves
them, while continuing to own Vite, registry, hook, and Phoenix marker wiring.

## Adding another island

```bash
mix haxe.gen.live_react AnotherPanel --yes
mix haxe.phoenix.live_react --check
```

Review the generated starter files before extending them. Keep the component
name static, keep its public props closed, and treat all browser events as
untrusted input when they return to the server.
