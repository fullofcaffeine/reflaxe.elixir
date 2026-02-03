# `src_haxe/shared/` (todo-app)

This folder contains Haxe modules intended to be used from **both** compilation targets:

- **Server**: Haxe → Elixir (Phoenix LiveView / controllers / channels)
- **Client**: Haxe → JavaScript via **genes** (Phoenix JS hooks / channels client)

The goal is a single source of truth at client/server boundaries without losing idiomatic output
on either side.

## What belongs here

- **Boundary types**: `typedef` shapes for payloads (JSON-like maps/objects)
  - Example: `shared.TodoTypes.Todo`, `shared.TodoTypes.User`
- **Stable names** for boundary strings
  - LiveView: `shared.liveview.EventName`, `shared.liveview.HookName`
  - Channels: protocol topics + event names
- **Shared wire protocols** (typed encode/decode)
  - Example: `shared.channels.PingProtocol`

## What should *not* belong here

- Code that can only run on one target **unless** it is either:
  - implemented for both targets, or
  - clearly documented as target-specific and never referenced from the other build.

## Build defines you’ll see

- Server build (`build-server.hxml`):
  - `-D elixir_output=...` (selects the Elixir target output dir)
  - `-D reflaxe_runtime` (required by Reflaxe targets; also used as a stable “Elixir build” signal)
- Client build (`build-client.hxml`):
  - `-lib genes` (JS generator)
  - `-lib phoenix_js` (typed Phoenix JS externs)

When shared code truly needs target-specific behavior (e.g. crypto primitives), prefer:
- an implementation per target (same API), or
- moving that helper into `server/` or `client/` packages.

