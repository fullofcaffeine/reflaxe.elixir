# 12 - Phoenix Chat (LiveView + Presence)

Realtime chat example authored in Haxe and compiled to Phoenix LiveView + Presence modules.

This example is intentionally **hybrid by design**: Haxe generates the app feature logic, while a small Phoenix scaffold remains hand-authored Elixir.

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

## Tests

Compile Haxe-authored ExUnit tests and run:

```bash
cd examples/12-phoenix-chat
mix test
npm run typecheck
npm run test:frontend
npm run test:binding
```

The example includes a Haxe-authored ExUnit test:

- `examples/12-phoenix-chat/src_haxe/test/live/ChatStateTest.hx`
- `examples/12-phoenix-chat/src_haxe/test/web/ReactIslandLiveTest.hx`

The bounded browser proof is the same command used by CI:

```bash
scripts/qa-sentinel.sh \
  --app examples/12-phoenix-chat \
  --port 4012 \
  --playwright \
  --e2e-spec "e2e/presence.spec.ts" \
  --e2e-workers 1 \
  --deadline 900 \
  --verbose
```

Run that command from the repository root.

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

## Project-local Vite + `live_react` proof

This example is the first bounded proof of a PhoenixHx application using stock `live_react`. It is
deliberately project-local: it proves the native seam before PhoenixHx promotes a reusable scaffold
mode. `live-react-binding.json` pins the PhoenixHx baseline and the exact upstream `live_react`
revision. `scripts/apply-live-react-binding.mjs` validates that closed manifest and manages only
explicit marker blocks, exact package values, and files carrying its generated signature.

The binding fails closed when markers are missing or duplicated, a package key has a conflicting
owner, or a generated file lacks its signature. Running it twice must be byte-identical, and deleting
its generated TypeScript contract/registry must be recoverable without touching hand-owned source:

```bash
npm run bind:live-react
npm run bind:live-react:check
```

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

The Haxe component wrapper emits a fully qualified `LiveReact.react` Phoenix component. Because a
remote component is the wrapper's root, it uses the documented explicit `HXX.hxx(...)` fallback in
one bounded location; the surrounding LiveView continues to use direct inline HXX. The output is
ordinary HEEx and there is no HXX runtime.

The handwritten TypeScript implementation is intentional for this first proof: it isolates the
Phoenix/React boundary from code-generation risk. A Genes-generated implementation of the same
closed contract is a later conformance variant, not a prerequisite for this slice.

### Removal and promotion gates

- Remove the React island and the useful LiveView controls remain.
- Remove the Vite/`live_react` binding and the original Phoenix/Haxe application path remains.
- Keep using the stock pinned dependency unless a measured repeated gap survives the wrapper and an
  upstream contribution attempt.
- Promote this project-local binding into PhoenixHx scaffolding only after a second real consumer
  proves the same asset mode, rerun ownership, clean-checkout recovery, and native debug path.
- Delete the generator if a small handwritten binding is clearer and no second component reuses it.

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
- Playwright smoke for two-session presence is at `examples/12-phoenix-chat/e2e/presence.spec.ts`.
