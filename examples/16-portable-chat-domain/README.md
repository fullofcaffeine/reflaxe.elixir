# 16 - Portable Chat Domain

This example demonstrates the portable-authoring lane: write the chat domain once in Haxe, keep it free of Phoenix/Elixir/JS APIs, then compile it to both Elixir and JavaScript.

It is intentionally not a full Phoenix chat app. For Phoenix wiring, see:

- `examples/12-phoenix-chat/` for hybrid adoption
- `examples/15-phoenix-chat-haxe-first/` for Haxe-authored Phoenix app/router/live/presence

## What this example demonstrates

- `src_haxe/shared/chat/**` contains portable Haxe only.
- `src_haxe/server/**` is a thin Elixir-target demo adapter.
- `src_haxe/client/**` is a thin JS-target demo adapter.
- `build.hxml` compiles both targets.

## Run

```bash
cd examples/16-portable-chat-domain
mix deps.get
mix test
haxe build-js.hxml
node dist/portable_chat_domain.js
```

`mix test` compiles Haxe-authored ExUnit coverage for normalization, rejection,
long previews, transcript order, and the Elixir adapter. The final two commands
execute the same portable domain through JavaScript.

## Key files

- `src_haxe/shared/chat/MessageRules.hx` - validation and formatting rules.
- `src_haxe/shared/chat/Transcript.hx` - immutable transcript operations.
- `src_haxe/server/PortableChatServer.hx` - Elixir compile proof.
- `src_haxe/client/PortableChatClient.hx` - JavaScript compile/run proof.

## Boundary rule

The portable domain does not import `elixir.*`, `phoenix.*`, or `js.*`. Target-specific code belongs in adapters at the edge.

## Generated output quality contract

This example supplies the portable and imperative slices of the
[handwritten-output corpus](../../docs/03-compiler-development/GENERATED_OUTPUT_QUALITY_CORPUS.md).
The generated `MessageRules`, `Transcript`, and `PortableChatServer` modules
are compared with concise handwritten Elixir. Current `StringTools` calls,
three expression IIFEs, and one reducer append are counted and linked to
separate optimization beads. They remain visible because the corpus does not
trade portable Haxe semantics for a prettier snapshot.
