# PhoenixHx + LiveReact

This example proves the complete client-only LiveReact path: Phoenix renders a
statically named React island through a Haxe-authored wrapper, Genes compiles
the Haxe browser bootstrap, and Vite mounts the hand-owned React component.
The signal console is deliberately interactive so browser QA proves hydration,
not just that the HTML page loaded.

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
example. Its Phoenix endpoint starts all three development watchers:

- the Mix Haxe compiler watches server-side Haxe and emits Elixir;
- `mix haxe.watch` compiles the Genes browser entry to stable JavaScript;
- Vite and Tailwind rebuild the browser assets.

There is intentionally no `mix dev` alias here. The todo app defines one
because it must create and migrate PostgreSQL before starting Phoenix; this
example has no database to prepare. `mix phx.server` is therefore the complete
local flow.

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
  -> static TypeScript registry and trusted prop boundary
  -> signal-console.tsx
  -> React state and browser interaction
```

- `src_haxe/phoenixhx_live_react_hx/components/live_react/SignalConsoleIsland.hx`
  owns the closed server props and the fixed component name.
- Generated Elixir under `lib/phoenixhx_live_react_hx/**` is compiler output;
  change its Haxe source instead of editing the `.ex` file.
- `src_haxe/client/Boot.hx` is browser code compiled through Genes. It publishes
  the shared hook table and an E2E boot marker.
- `assets/react-components/signal-console-boundary.tsx` validates the values
  crossing from LiveReact and discards native bridge capabilities that this
  component does not need.
- `assets/react-components/signal-console.tsx` is the hand-owned React
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
component is authored in Haxe. This example is intentionally Genes-first:
`src_haxe/client/Boot.hx` is compiled by Genes, while the inner React component
remains hand-owned TSX to demonstrate that the choices can be mixed. Genes is
the source compiler and Vite is the sole final bundler.

## Verification

Fast server-side and integration checks:

```bash
mix test
mix haxe.phoenix.live_react --check
mix assets.build
```

`mix test` first compiles `src_haxe/test/web/PageSmokeTest.hx` to ExUnit, then
checks that Phoenix renders the typed island boundary. `mix assets.build`
compiles the Genes client before Vite so it also works from a clean checkout.

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

That browser test proves Genes booted, React hydrated, the pulse count changes,
and the channel control advances.

## Adding another island

```bash
mix haxe.gen.live_react AnotherPanel --yes
mix haxe.phoenix.live_react --check
```

Review the generated starter files before extending them. Keep the component
name static, keep its public props closed, and treat all browser events as
untrusted input when they return to the server.
