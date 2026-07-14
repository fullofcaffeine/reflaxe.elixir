# Type-Safe OTP Child Specs (`TypeSafeChildSpec`)

## Summary

Use `elixir.otp.TypeSafeChildSpec` when building supervision trees in Haxe.

- Preferred path: typed module references (`TypeSafeChildSpec.endpoint(Endpoint)`).
- Escape hatch: explicit `*Unsafe` variants for intentional dynamic/legacy strings.

This page is the canonical reference for child-spec APIs used by app modules and tutorials.

This API's stable promise is compile-time module checking, standard child-spec output, and booting the
documented application shapes. It does not promise every supervisor restart, crash, or shutdown
scenario. See the [OTP Support Contract](OTP_SUPPORT_CONTRACT.md) for that boundary.

## Why This Exists

Supervision trees are critical app wiring. Raw strings are easy to mistype and hard to refactor safely.

`TypeSafeChildSpec` keeps Phoenix/OTP shapes familiar while adding compile-time checks for module references.

## Haxe Input

```haxe
import elixir.Atom;
import elixir.otp.Supervisor.ChildSpecFormat;
import elixir.otp.TypeSafeChildSpec;
import phoenix_chat_hx.infrastructure.DNSCluster;
import phoenix_chat_hx.infrastructure.Endpoint;
import phoenix_chat_hx.infrastructure.PubSub;
import phoenix_chat_hx.infrastructure.Telemetry;
import phoenix_chat_hx.presence.ChatPresence;

var children:Array<ChildSpecFormat> = [
  TypeSafeChildSpec.telemetry(Telemetry),
  TypeSafeChildSpec.moduleWithConfig(DNSCluster, [{key: "query", value: dnsClusterQuery}]),
  TypeSafeChildSpec.pubSub(PubSub),
  TypeSafeChildSpec.moduleRef(ChatPresence),
  TypeSafeChildSpec.endpoint(Endpoint)
];
```

## Generated Elixir Shape

```elixir
children = [
  PhoenixChatWeb.Telemetry,
  {DNSCluster, [query: dns_cluster_query]},
  {Phoenix.PubSub, name: PhoenixChat.PubSub},
  PhoenixChatWeb.Presence,
  PhoenixChatWeb.Endpoint
]
```

## Why the Compiler Emits This

Typed child-spec methods resolve class/extern module references at compile time and then emit standard
OTP child-spec forms (`Module`, `{Module, kw}`, or full spec maps). Elixir/OTP owns the runtime
behavior; Reflaxe.Elixir's 1.0 evidence covers documented application boot, not arbitrary supervision
failure policy.

## Typed vs Unsafe APIs

| Goal | Preferred Typed API | Unsafe Escape Hatch |
|---|---|---|
| PubSub child | `TypeSafeChildSpec.pubSub(PubSub)` | `TypeSafeChildSpec.pubSubUnsafe("MyApp.PubSub")` |
| Endpoint child | `TypeSafeChildSpec.endpoint(Endpoint)` | `TypeSafeChildSpec.endpointUnsafe("MyAppWeb.Endpoint")` |
| Telemetry child | `TypeSafeChildSpec.telemetry(Telemetry)` | `TypeSafeChildSpec.telemetryUnsafe("MyAppWeb.Telemetry")` |
| Generic module ref | `TypeSafeChildSpec.moduleRef(MyModule)` | `TypeSafeChildSpec.moduleRefUnsafe("MyApp.MyModule")` |
| Module + config | `TypeSafeChildSpec.moduleWithConfig(MyModule, config)` | `TypeSafeChildSpec.moduleWithConfigUnsafe("MyApp.MyModule", config)` |
| Module + args | `TypeSafeChildSpec.moduleWithArgs(MyModule, args)` | `TypeSafeChildSpec.moduleWithArgsUnsafe("MyApp.MyModule", args)` |
| Repo child | `TypeSafeChildSpec.repo(Repo, config)` | `TypeSafeChildSpec.repoUnsafe("MyApp.Repo", config)` |
| Worker child | `TypeSafeChildSpec.worker(WorkerModule, args)` | `TypeSafeChildSpec.workerUnsafe("MyApp.Worker", args)` |
| Supervisor child | `TypeSafeChildSpec.supervisor(SupervisorModule, args, opts)` | `TypeSafeChildSpec.supervisorUnsafe("MyApp.Supervisor", args, opts)` |
| Simple child | `TypeSafeChildSpec.simple(Module)` | `TypeSafeChildSpec.simpleUnsafe("MyApp.Module")` |

Use `*Unsafe` only when values are intentionally dynamic or migration glue.

## Pure Elixir Modules: Typed Boundary Pattern

When a module is intentionally hand-written in Elixir, keep Haxe callsites typed with a tiny extern wrapper:

```bash
mix haxe.gen.extern MyApp.PubSub --boundary --package my_app.infrastructure --out src_haxe
```

```haxe
package my_app.infrastructure;

@:native("MyApp.PubSub")
@:unsafeExtern // Explicit app-level boundary in strict mode contexts.
extern class PubSub {}
```

Then use it normally:

```haxe
TypeSafeChildSpec.pubSub(PubSub);
```

## Migration Guide

Old style:

```haxe
TypeSafeChildSpec.endpointUnsafe("MyAppWeb.Endpoint");
TypeSafeChildSpec.pubSubUnsafe("MyApp.PubSub");
```

Preferred style:

```haxe
TypeSafeChildSpec.endpoint(Endpoint);
TypeSafeChildSpec.pubSub(PubSub);
```

If you cannot add a typed wrapper yet, keep `*Unsafe` temporarily and document why.

## Method Reference

- Typed: `pubSub`, `repo`, `endpoint`, `telemetry`, `worker`, `supervisor`, `simple`, `moduleRef`, `moduleWithConfig`, `moduleWithArgs`
- Escape hatch: corresponding `*Unsafe` methods
- Additional helpers: `taskSupervisor`, `registry`, `fromMap`

## Related Docs

- `docs/04-api-reference/ELIXIR_RUNTIME_API_REFERENCE.md`
- `docs/04-api-reference/OTP_SUPPORT_CONTRACT.md`
- `docs/04-api-reference/ANNOTATIONS.md`
- `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md`
- `docs/06-guides/PHOENIX_CHAT_TUTORIAL_HAXE_FIRST.md`
- `examples/15-phoenix-chat-haxe-first/README.md`
