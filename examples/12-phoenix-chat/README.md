# 12 - Phoenix Chat (LiveView + Presence)

Realtime chat example authored in Haxe and compiled to Phoenix LiveView + Presence modules.

This example is intentionally **hybrid by design**: Haxe generates the app feature logic, while a small Phoenix scaffold remains hand-authored Elixir.

New to PhoenixHx LiveReact? Read the
[beginner guide](../../docs/02-user-guide/PHOENIX_LIVE_REACT.md) before the
application-specific details below. It explains what LiveView, LiveReact,
React, Vite, and Genes each do without assuming knowledge of this example.

## What this example covers

- LiveView callbacks (`mount/3`, `handle_event/3`, `handle_info/2`)
- Presence-backed online user list and count
- PubSub message fanout for chat messages
- Haxe->JS client boot hook (`AutoScroll`) for LiveView
- Strict TSX template authoring in Haxe for LiveView render code
- One closed, client-only React island through stock pinned `live_react` and Vite
- A native LiveView fallback that preserves the same preference behavior when the island is removed

## Run

```bash
cd examples/12-phoenix-chat
mix setup
mix phx.server
```

Open `http://localhost:4000`.

`mix phx.server` is the normal local development command for this example. Its Phoenix endpoint
starts the Haxe client, Vite, and Tailwind watchers declared in `config/dev.exs`; there is no separate
`mix dev` alias here. Automated checks use the sentinel below only to give that same app path a
deadline, readiness probes, captured logs, and guaranteed teardown.

## Tests

Compile Haxe-authored ExUnit tests and run:

```bash
cd examples/12-phoenix-chat
mix test
npm run typecheck
npm run test:frontend
mix haxe.phoenix.live_react --check
```

The example includes a Haxe-authored ExUnit test:

- `examples/12-phoenix-chat/src_haxe/test/live/ChatStateTest.hx`
- `examples/12-phoenix-chat/src_haxe/test/web/ReactIslandLiveTest.hx`

The bounded browser proof is the local async form of the same
sentinel/Playwright path used by CI:

```bash
scripts/qa-sentinel.sh \
  --app examples/12-phoenix-chat \
  --port 4012 \
  --playwright \
  --e2e-spec "e2e/*.spec.ts" \
  --e2e-workers 1 \
  --async \
  --deadline 900 \
  --verbose
```

Run that command from the repository root, then inspect its bounded result:

```bash
scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 180
```

## Architecture

This app demonstrates a practical migration/adoption shape for Phoenix apps.

### Hybrid by design

- The Haxe compiler is configured to emit into `lib/phoenix_chat_hx`.
  - `examples/12-phoenix-chat/build.hxml` sets `-D elixir_output=lib/phoenix_chat_hx`.
  - `examples/12-phoenix-chat/mix.exs` configures `target_dir: "lib/phoenix_chat_hx"` for the `:haxe` compiler.
- Mix still boots a normal Phoenix app module.
  - `examples/12-phoenix-chat/mix.exs` sets `mod: {PhoenixChat.Application, []}`.
- Phoenix scaffold modules in `lib/phoenix_chat*.ex` and `lib/phoenix_chat_web/**` provide conventional boot/runtime wiring.
- Haxe-generated modules in `lib/phoenix_chat_hx/**` provide feature logic and typed LiveView behavior.

This is the repository's isolated ownership example. The generated root has its own
`lib/phoenix_chat_hx/_GeneratedFiles.json`, while handwritten Phoenix modules remain outside that
root. Compiler publication, formatting, stale deletion, and Mix clean still use the same hashed
ownership protocol as in-place output; isolation changes only the physical review boundary. The
example compile, runtime Mix tests, and sentinel browser path exercise this layout. See
[Generated Output Ownership](../../docs/02-user-guide/GENERATED_OUTPUT_OWNERSHIP.md).

### Why this approach exists

- It keeps the app runnable as a conventional Phoenix project.
- It shows incremental adoption: teams can move features to Haxe without rewriting framework glue first.
- It keeps boundaries obvious:
  - Phoenix boot/web wiring remains standard Elixir.
  - App feature behavior is authored in Haxe and generated to Elixir.

### Source-of-truth boundaries

- Haxe source-of-truth:
  - `examples/12-phoenix-chat/src_haxe/phoenix_chat_hx/**`
  - `examples/12-phoenix-chat/src_haxe/client/**`
- Scaffold source-of-truth:
  - `examples/12-phoenix-chat/lib/phoenix_chat/application.ex`
  - `examples/12-phoenix-chat/lib/phoenix_chat.ex`
  - `examples/12-phoenix-chat/lib/phoenix_chat_web.ex`
  - `examples/12-phoenix-chat/lib/phoenix_chat_web/**`

## Public PhoenixHx LiveReact lifecycle

The [canonical guide](../../docs/02-user-guide/PHOENIX_LIVE_REACT.md) teaches
the general setup and removal flow. This section records only how the chat
example applies it and which chat files remain application-owned.

This example now exercises the same public Mix tasks that a PhoenixHx user installs. The
"lifecycle" is the repeatable setup, verification, repair, component-registration, and removal of
the generic LiveReact/Vite wiring. It is not the lifetime of a React component in the browser.

The lifecycle task owns only infrastructure it can safely reproduce: Vite configuration, the
LiveReact hook module, the static component registry, and explicit marker blocks in Phoenix files.
It also validates the `live_react` npm reference recorded in `phoenixhx-live-react.json`. The chat
behavior,
`PreferenceStudio` boundary and component, closed wire contract, Haxe wrapper, and native LiveView
fallback remain application-owned. This split lets setup repair generated wiring without rewriting
the feature itself.

```bash
# Enable or repair stock LiveReact and Vite wiring.
mix haxe.phoenix.live_react --yes

# Verify dependency identity, marker ownership, registry, and generated files.
mix haxe.phoenix.live_react --check

# Adopt this existing application-owned component in the static registry.
mix haxe.gen.live_react PreferenceStudio \
  --existing \
  --module ./preference-studio-boundary \
  --export PreferenceStudioBoundary \
  --yes

# Remove only setup-owned files and settings; application-owned component source survives.
# The app returns to its Phoenix esbuild lane, so the native controls still run.
mix haxe.phoenix.live_react --remove --yes
```

Setup is transactional and fails closed when ownership is ambiguous. If setup is interrupted, run
the first command again; it recovers the pending transaction before applying changes. If `--check`
reports drift, inspect the named file before rerunning setup. Repeating setup on a current project is
byte-identical.

Mix selects the canonical stock LiveReact Git checkout at the exact revision recorded in
`mix.lock`. npm then consumes that same checkout through `file:deps/live_react`; it does not resolve
an independent tarball that can drift from the BEAM dependency. The checked-in `.npmrc` asks npm to
install the local checkout as an application dependency rather than pulling its contributor-only
development tree. Keep `mix.lock`, `package.json`, and `package-lock.json` together when updating the
revision.

The lifecycle applies the same identity rule to Phoenix's browser packages. `phoenix`,
`phoenix_html`, and `phoenix_live_view` must be the exact versions supplied by the resolved Mix
checkouts, or project-relative `file:deps/...` references to those checkouts. A mismatch can let the
page render while every LiveView click fails because the browser and server speak different protocol
versions. If `--check` reports one, run `mix deps.get`, use the exact version or `file:` repair shown
in the error, run `npm install`, rebuild the assets, and check again. The lifecycle checks the
declaration; `npm install` is what updates an already-populated `node_modules` directory.

Vite is the one JavaScript bundler in this mode. The Haxe/Genes client compilation remains a source
compiler and Tailwind remains the CSS build lane; neither is presented as a second JS bundler.
Phoenix and browser debugging remain ordinary `mix`, Vite, TypeScript, and React workflows.

### Closed island boundary

`PreferenceStudio` is fixed in a generated component registry. Its portable public surface is only:

- inputs: `title` and the closed density enum `calm | focused | dense`;
- event: `preference_changed` with exactly one `density` field;
- limits: 512 encoded input bytes and 64 encoded event bytes.

The TypeScript boundary rejects unknown fields, invalid enum values, and oversized JSON before it
invokes the trusted upstream bridge. The Haxe server independently validates the event. Raw
`pushEvent`, upload, slot, stream, and component-name lookup capabilities are not exposed to the
inner component type. SSR, slots, uploads, and stream props are disabled for this first proof.

This wrapper is a correctness and ergonomics boundary for first-party components; it is not a
sandbox for untrusted React code. Stock `live_react` still owns the runtime bridge.

Phoenix adds an empty `value` field to native button events. The fallback therefore uses a separate,
closed native event adapter that accepts exactly `density` plus that empty framework-owned field,
then lowers to the same preference behavior. It does not widen the React event contract.

### HXX and native ownership

The Haxe component wrapper uses direct inline HXX with a normal source root around the fully
qualified `LiveReact.react` Phoenix component. That source root satisfies Haxe's XML lexer while
the HXX lowerer emits the module-qualified component as ordinary HEEx. The remote component remains
explicit, no legacy HXX mode is enabled, and there is no HXX runtime.

This is a Genes-mode application because its browser boot hook is authored in Haxe and compiled to
`assets/js/hx_app.js`. The `PreferenceStudio` React component itself is intentionally handwritten
strict TypeScript/TSX. Genes is required for browser code authored in Haxe, not merely because
LiveReact is installed; Vite remains the sole final JavaScript bundler. The todo app is the separate
Genes-authored React-component proof.

### Removal and ownership gates

- Remove the React island and the useful LiveView controls remain.
- Remove lifecycle-owned Vite/LiveReact wiring and the app restores its Phoenix esbuild lane, so the
  native Phoenix/Haxe controls still run from a clean build. The task retains application-owned component
  source and dependencies that source still imports.
- Keep using the stock pinned dependency unless a measured repeated gap survives the wrapper and an
  upstream contribution attempt.
- Do not add a second project-local installer. Setup, check, recovery, component registration, and
  removal all go through the public Mix tasks above.

## How This Differs From todo-app

`examples/todo-app` and `examples/12-phoenix-chat` have different goals.

### 12-phoenix-chat goal

- Demonstrate a focused realtime feature set (LiveView + Presence + PubSub) in a small app.
- Demonstrate incremental Haxe adoption in an otherwise standard Phoenix structure.
- Keep Phoenix scaffold modules explicit and easy to inspect.

### todo-app goal

- Demonstrate end-to-end Haxe-driven application code at larger scope.
- Use Haxe for a much broader slice of server code (`TodoApp` / `TodoAppWeb` modules), plus client hooks.
- Serve as the primary integration canary (Ecto + LiveView + Playwright + QA sentinel).

### Practical difference in generation model

- `12-phoenix-chat`:
  - Generated server modules are namespaced under `lib/phoenix_chat_hx/**`.
  - Scaffold runtime modules under `lib/phoenix_chat*.ex` + `lib/phoenix_chat_web/**` remain hand-authored.
- `todo-app`:
  - The generated server surface is broader and maps more directly into app/web module namespaces.
  - It still remains a normal Phoenix project, but with a much larger Haxe-authored surface area.

## Key Haxe files

- `examples/12-phoenix-chat/src_haxe/phoenix_chat_hx/live/AppLive.hx`
- `examples/12-phoenix-chat/src_haxe/phoenix_chat_hx/live/AppLiveTypes.hx`
- `examples/12-phoenix-chat/src_haxe/phoenix_chat_hx/presence/ChatPresence.hx`
- `examples/12-phoenix-chat/src_haxe/client/Boot.hx`

## Haxe -> generated Elixir examples

Haxe Presence module:

```haxe
@:native("PhoenixChatWeb.Presence")
@:presence
class ChatPresence implements PresenceBehavior {}
```

Generated Elixir shape:

```elixir
defmodule PhoenixChatWeb.Presence do
  use Phoenix.Presence,
    otp_app: :phoenix_chat,
    pubsub_server: PhoenixChat.PubSub
end
```

Haxe LiveView render excerpt (default typed TSX mode):

```haxe
public static function render(assigns: AppLiveAssigns): String {
  return <div class="panel">
    <div class="badge">${assigns.online_user_count}</div>
  </div>;
}
```

Generated Elixir shape:

```elixir
def render(assigns) do
  ~H"""
  <div class="panel">
    <div class="badge"><%= @online_user_count %></div>
  </div>
  """
end
```

## Notes

- This example uses strict TSX inline markup by default in `AppLive.hx`.
- Template expressions are real Haxe expressions (`${...}`), so syntax/type errors are caught by the Haxe typer.
- For detailed template authoring guidance, see `docs/02-user-guide/INLINE_MARKUP.md` and `docs/02-user-guide/HXX_SYNTAX_AND_COMPARISON.md`.
- For the most complete end-to-end app (Ecto + tests + Playwright), see `examples/todo-app/README.md`.
- Playwright smoke covers the native LiveView fallback, two-session Presence, and the React island at `examples/12-phoenix-chat/e2e/*.spec.ts`.
