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
- A separate `/crema` invitation surface that proves a frontend-quality workflow without replacing the chat app

## Run

```bash
cd examples/12-phoenix-chat
mix setup
mix phx.server
```

Open `http://localhost:4000` for chat or `http://localhost:4000/crema` for the
project-local Crema invitation proof.

## Tests

Compile Haxe-authored ExUnit tests and run:

```bash
cd examples/12-phoenix-chat
mix test
npm run typecheck
npm run test:frontend
npm run test:binding
npm run test:crema-tokens
```

The example includes a Haxe-authored ExUnit test:

- `examples/12-phoenix-chat/src_haxe/test/live/ChatStateTest.hx`
- `examples/12-phoenix-chat/src_haxe/test/web/ReactIslandLiveTest.hx`
- `examples/12-phoenix-chat/src_haxe/test/web/CremaInviteLiveTest.hx`

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

## Project-local Crema invitation proof

`/crema` is the native half of Cafetera's first wireframe-to-design proving
slice. It is deliberately a second route inside the existing application: the
original chat identity, build, debugging path, and React binding remain intact.
The page does not establish a public Crema schema or a generic PhoenixHx theme.

The same accepted low-fidelity flow was explored through two proposal-level
visual directions before native implementation:

| Direction | Visual premise | Disposition |
| --- | --- | --- |
| **Field Notes Atelier** | Archival paper, dark botanical ink, vermilion marks, editorial serif display type, offset rules, and a working-ledger composition | Implemented as the current proposal; owner visual selection remains pending |
| **Signal Bloom** | Near-black field, celadon diagrams, electric orange signals, soft geometric type, and animated botanical network forms | Retained as the alternative design-concept proposal |

Those concepts preserve the same purpose, information hierarchy, invitation
form, working-density choice, native fallback, responsive priorities, and
accessibility requirements. A concept does not select itself because an agent
described or rendered it. The Cafetera workspace keeps the current disposition
candidate and every dependent design record at proposal authority until the
owner explicitly selects a direction.

### Native ownership and effect boundary

- `CremaInviteLive.hx` owns LiveView form state, validation, status rendering,
  and the server-side boundary for the existing exact preference event.
- `PreferenceStudio` owns only trusted browser-local draft interaction. Its
  public inputs and event remain `title`, `density`, and one exact
  `preference_changed` payload.
- Caf's project-local token CML owns the proposed semantic values.
  `assets/css/crema-tokens.css` is their deterministic target projection, pinned
  at `sha256:f9e622ab1acae8120dbc1595d6bcadc4a50e2bb0b6657933b26b526f3539ef28`.
  `app.css` owns selector use, native font-stack mapping, layout, responsive
  behavior, and derived shades; neither file claims the browser loaded them.
- The submitted invitation is an in-memory conformance demonstration. The
  success state explicitly stops before storage, email, provider mutation, or
  any other external effect.
- The handwritten Phoenix router and layouts remain ordinary native scaffold
  source. The LiveView itself stays Haxe-authored and lowers through default
  direct inline HXX to native HEEx.

### Quality and recovery evidence

The existing bounded sentinel now exercises chat, the Crema form, the trusted
React event, the native fallback, an axe accessibility scan, and mobile/tablet/
desktop overflow checks. It attaches full-page screenshots at 390, 768, and
1440 pixels for owner visual review. Native Haxe, Mix, TypeScript, Vitest, Vite,
Playwright, and source-map output remain the evidence owners; this README and
the Caf CML do not turn a past green run into timeless runtime truth.

Removing `CremaInviteLive`, its `/crema` route, tests, generated token CSS, and
the `.crema-*` CSS returns byte-for-byte to the prior chat surface. Removing
only the React island leaves the native LiveView controls and invitation form
useful. Promotion to a reusable Craft or Crema kit requires another
product/target, stable fields, measured second-use leverage, and owner
disposition.

### Initial leverage measurement

These timings are directional rather than a controlled benchmark because the
two slices proved different risks. They are retained so the reuse claim can be
challenged instead of inferred from generated volume.

| Observed slice | Elapsed time | Correction rounds | Reusable result |
| --- | ---: | ---: | --- |
| First handwritten Phoenix/Vite/stock-`live_react` binding and island proof (`haxe.elixir.codex-cf4`) | about 52 minutes from task start to close, plus a 4-minute HXX correction | 1 post-close technical correction | Closed registry and contracts, idempotent binding, fallback, native tests, and recovery path |
| Crema second surface reusing that exact binding (`haxe.elixir.codex-9ae`) | about 21 minutes from task creation to the first fully browser-green sentinel | 1 automated accessibility correction; owner visual selection/corrections pending | Distinct branded route, form flow, reused island contract, responsive screenshots, accessibility and removal proof |

The result is promising evidence that the native binding paid rent on its
second use, not proof that every Craft surface will be faster. The stronger
claim remains gated on another product or renderer preserving the semantic
records without web-native fields and reducing owner-visible effort again.

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

The Haxe component wrapper uses direct inline HXX with a normal source root around the fully
qualified `LiveReact.react` Phoenix component. That source root satisfies Haxe's XML lexer while
the HXX lowerer emits the module-qualified component as ordinary HEEx. The remote component remains
explicit, no legacy HXX mode is enabled, and there is no HXX runtime.

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
