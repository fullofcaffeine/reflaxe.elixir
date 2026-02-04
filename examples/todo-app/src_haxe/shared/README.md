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

In shared code, you’ll sometimes see:
- `#if (elixir || reflaxe_runtime)` guards

Why:
- `elixir` is the obvious signal when compiling with the Elixir target.
- `reflaxe_runtime` is a stable signal in this repo’s tooling/harness for “Elixir build context”
  (including some snapshot/interop compiles) where `elixir` may not be defined yet.

Rule of thumb:
- Prefer writing truly portable code in `shared/` with no `#if`.
- If you need a target-specific branch, keep the *API* identical on both sides and document why.

When shared code truly needs target-specific behavior (e.g. crypto primitives), prefer:
- an implementation per target (same API), or
- moving that helper into `server/` or `client/` packages.

## Example: `AvatarTools.gravatarUrl/2`

`shared.AvatarTools.gravatarUrl(email, size)` is used by server-rendered LiveView templates
and is also safe to call from the genes client build.

- It uses `haxe.crypto.Md5.encode/1` as the single shared API across targets.
- In Elixir builds, Reflaxe.Elixir overrides `haxe.crypto.Md5` to delegate to BEAM-native `:crypto`
  (so we keep idiomatic/fast output without changing the Haxe call sites).

As a rule, avoid `#if elixir ... else return null` in `shared/` unless the helper is truly
server-only and cannot sensibly be implemented on the client.
