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
haxe build.hxml
elixirc --warnings-as-errors -o _build/elixirc_validate $(find lib -type f -name "*.ex" | sort)
node dist/portable_chat_domain.js
```

## Key files

- `src_haxe/shared/chat/MessageRules.hx` - validation and formatting rules.
- `src_haxe/shared/chat/Transcript.hx` - immutable transcript operations.
- `src_haxe/server/PortableChatServer.hx` - Elixir compile proof.
- `src_haxe/client/PortableChatClient.hx` - JavaScript compile/run proof.

## Boundary rule

The portable domain does not import `elixir.*`, `phoenix.*`, or `js.*`. Target-specific code belongs in adapters at the edge.
