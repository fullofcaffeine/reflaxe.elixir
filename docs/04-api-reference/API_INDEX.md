# User-Facing API Index

This index is the source-of-truth entry point for user-facing APIs in Reflaxe.Elixir.

## Scope

Included in this index:

- Metadata tags used by examples and user-facing guides
- Public runtime/library surfaces under `std/phoenix`, `std/ecto`, `std/elixir`, `std/plug`, `std/exunit`
- User-facing macro/flag references in `docs/04-api-reference`

Not included as primary reference surface:

- Internal compiler pipeline internals under `src/reflaxe/elixir/ast/**` unless directly exposed to users

## Depth Model

- Deep guidance: high-impact surfaces (Phoenix, Ecto, OTP/runtime integration, metadata semantics)
- Concise reference: long-tail APIs, module inventory, and cross-links

## Primary References

- Metadata and annotation semantics: `docs/04-api-reference/ANNOTATIONS.md`
- Router DSL: `docs/04-api-reference/ROUTER_DSL.md`
- Compiler/user feature flags: `docs/04-api-reference/FEATURE_FLAGS.md`
- Macro API usage guidance: `docs/04-api-reference/HAXE_MACRO_APIS.md`
- Phoenix API deep dive: `docs/04-api-reference/PHOENIX_API_REFERENCE.md`
- LiveSocket assign API (consumer + technical): `docs/04-api-reference/LIVE_SOCKET_ASSIGN_API.md`
- Ecto API deep dive: `docs/04-api-reference/ECTO_API_REFERENCE.md`
- Elixir runtime API deep dive: `docs/04-api-reference/ELIXIR_RUNTIME_API_REFERENCE.md`
- Exact OTP 1.0 boundary and runtime evidence: `docs/04-api-reference/OTP_SUPPORT_CONTRACT.md`
- Type-safe OTP child-spec API: `docs/04-api-reference/TYPE_SAFE_CHILD_SPEC.md`
- Built-in and Haxe-authored Mix tasks: `docs/04-api-reference/MIX_TASKS.md`
- API UX backlog and prioritization: `docs/08-roadmap/api-ux-backlog.md`

## LLM Contract: Typed Phoenix DSL Surfaces

Use this section as the concise contract for assistant/tooling retrieval.

- Router DSL (`docs/04-api-reference/ROUTER_DSL.md`):
  - typed tokens are default (`pipeline(browser)`, `plug(accepts)`, `pipeThrough([browser])`)
  - `*Unsafe` constructors are explicit escape hatches for dynamic/legacy values
- OTP child specs (`docs/04-api-reference/TYPE_SAFE_CHILD_SPEC.md`):
  - typed module refs are default (`TypeSafeChildSpec.endpoint(Endpoint)`)
  - `*Unsafe` methods are escape hatches for dynamic/legacy strings
- Existing pure Elixir modules should keep typed callsites by using small extern boundaries:
  - `@:native("...") extern class ... {}`
  - in strict-mode contexts, mark app-local extern boundaries explicitly with `@:unsafeExtern`
- Canonical references:
  - Router DSL: `docs/04-api-reference/ROUTER_DSL.md`
  - Child specs: `docs/04-api-reference/TYPE_SAFE_CHILD_SPEC.md`
  - Interop boundaries: `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md`

## Metadata Tag Index (Examples + User Surface)

| Tag | Purpose | Primary Reference |
|---|---|---|
| `@:appName` | Configure OTP app/module naming | `ANNOTATIONS.md` |
| `@:application` | OTP Application module generation | `ANNOTATIONS.md` |
| `@:behaviour` | Behavior contract definition | `ANNOTATIONS.md` |
| `@:build` | Build-macro hook | `ANNOTATIONS.md` |
| `@:callback` | Required behavior callback | `ANNOTATIONS.md` |
| `@:changeset` | Changeset generation/config | `ANNOTATIONS.md` |
| `@:channel` | Phoenix Channel module | `ANNOTATIONS.md` |
| `@:component` | Phoenix component module + entrypoints | `ANNOTATIONS.md` |
| `@:controller` | Phoenix controller module | `ANNOTATIONS.md` |
| `@:elixirIdiomatic` | Idiomatic enum/result shape preference | `ANNOTATIONS.md` |
| `@:endpoint` | Phoenix endpoint module | `ANNOTATIONS.md` |
| `@:endpointSockets` | Endpoint socket mount declarations | `ANNOTATIONS.md` |
| `@:exunit` | ExUnit test module marker | `ANNOTATIONS.md` |
| `@:field` | Ecto schema field marker | `ANNOTATIONS.md` |
| `@:from` | Implicit conversion into type | `ANNOTATIONS.md` |
| `@:genserver` | Experimental GenServer module generation; outside the 1.0 OTP promise | `ANNOTATIONS.md`, `OTP_SUPPORT_CONTRACT.md` |
| `@:gettext` | Gettext integration surface marker | `ANNOTATIONS.md` |
| `@:has_many` | Ecto has_many association marker | `ANNOTATIONS.md` |
| `@:hxx_mode` | HXX mode selection | `ANNOTATIONS.md` |
| `@:hxx_no_inline_markup` | Disable inline-markup rewrite | `ANNOTATIONS.md` |
| `@:impl` | Protocol implementation marker | `ANNOTATIONS.md` |
| `@:keep` | Prevent DCE elimination | `ANNOTATIONS.md` |
| `@:liveview` | Phoenix LiveView module | `ANNOTATIONS.md` |
| `@:migration` | Ecto migration class marker | `ANNOTATIONS.md` |
| `@:mixTask` | Optional Haxe authoring surface for an ordinary `Mix.Task` module | `ANNOTATIONS.md`, `MIX_TASKS.md` |
| `@:module` | Module macro convenience marker | `ANNOTATIONS.md` |
| `@:native` | Explicit Elixir module/function naming | `ANNOTATIONS.md` |
| `@:optional` | Optional contract/typedef field marker | `ANNOTATIONS.md` |
| `@:optional_callback` | Optional behavior callback | `ANNOTATIONS.md` |
| `@:overload` | Alternate typing signatures | `ANNOTATIONS.md` |
| `@:phoenixWebModule` | Generate `AppWeb` helper module | `ANNOTATIONS.md` |
| `@:phxHookNames` | Hook-name registry metadata | `ANNOTATIONS.md` |
| `@:presence` | Phoenix Presence module | `ANNOTATIONS.md` |
| `@:presenceTopic` | Default presence topic metadata | `ANNOTATIONS.md` |
| `@:primary_key` | Schema primary key marker | `ANNOTATIONS.md` |
| `@:private` | Private API surface marker | `ANNOTATIONS.md` |
| `@:protocol` | Protocol definition marker | `ANNOTATIONS.md` |
| `@:query` | Reserved/experimental query marker | `ANNOTATIONS.md` |
| `@:repo` | Ecto repository config marker | `ANNOTATIONS.md` |
| `@:route` | Legacy/manual route metadata | `ROUTER_DSL.md` |
| `@:router` | Phoenix router module | `ANNOTATIONS.md` |
| `@:routes` | Typed route declarations | `ROUTER_DSL.md` |
| `@:schema` | Ecto schema module | `ANNOTATIONS.md` |
| `@:slot` | Component slot metadata | `ANNOTATIONS.md` |
| `@:socket` | Phoenix socket module | `ANNOTATIONS.md` |
| `@:socketChannels` | Socket topic routing metadata | `ANNOTATIONS.md` |
| `@:supervisor` | Experimental supervisor marker; restart/failure behavior is outside the 1.0 OTP promise | `ANNOTATIONS.md`, `OTP_SUPPORT_CONTRACT.md` |
| `@:template` | Template binding metadata | `ANNOTATIONS.md` |
| `@:test` | ExUnit test method marker | `ANNOTATIONS.md` |
| `@:timestamps` | Schema timestamps marker | `ANNOTATIONS.md` |
| `@:to` | Implicit conversion from type | `ANNOTATIONS.md` |
| `@:use` | Behavior-use convention marker in examples | `ANNOTATIONS.md` |
| `@:validate_format` | Changeset format validation metadata | `ANNOTATIONS.md` |
| `@:validate_length` | Changeset length validation metadata | `ANNOTATIONS.md` |
| `@:validate_number` | Changeset numeric validation metadata | `ANNOTATIONS.md` |
| `@:validate_required` | Changeset required-field metadata | `ANNOTATIONS.md` |
| `@:virtual` | Virtual schema field marker | `ANNOTATIONS.md` |

## Runtime Module Inventory (Concise)

### Phoenix Surface (`std/phoenix`)

Core:

- `std/phoenix/Phoenix.hx`
- `std/phoenix/Component.hx`
- `std/phoenix/ToFormOptions.hx`
- `std/phoenix/LiveSession.hx`
- `std/phoenix/Params.hx`
- `std/phoenix/LiveSocket.hx`
- `std/phoenix/Channel.hx`
- `std/phoenix/Presence.hx`
- `std/phoenix/PresenceBehavior.hx`
- `std/phoenix/PresenceModule.hx`
- `std/phoenix/PhoenixFlash.hx`
- `std/phoenix/PubSub.hx`
- `std/phoenix/PubSubShim.hx`
- `std/phoenix/SafePubSub.hx`
- `std/phoenix/Token.hx`
- `std/phoenix/JS.hx`

Opt-in stock LiveReact interop:

- `std/phoenix/live_react/LiveReact.hx`
- `std/phoenix/live_react/LiveReactReload.hx`
- `vendor/phoenix_shared/src/phoenix/live_react/LiveReactEventProtocol.hx`

Channels and wire types:

- `std/phoenix/channels/JoinResult.hx`
- `std/phoenix/channels/ReplyResult.hx`
- `std/phoenix/channels/TypedChannelServer.hx`

Template/HXX:

- `std/phoenix/hxx/HeexTemplate.hx`
- `std/phoenix/hxx/H.hx`
- `std/phoenix/hxx/ast/HeexNode.hx`
- `std/phoenix/hxx/ast/HeexAttr.hx`
- `std/phoenix/hxx/HXX2.hx` (deprecated compatibility alias; prefer `HeexTemplate`)

Types and registries:

- `std/phoenix/types/Assigns.hx`
- `std/phoenix/types/AssignKey.hx`
- `std/phoenix/types/Socket.hx`
- `std/phoenix/types/Slot.hx`
- `std/phoenix/types/Flash.hx`
- `std/phoenix/types/FlashMessage.hx`
- `std/phoenix/types/RouteParams.hx`
- `std/phoenix/types/HXXTypes.hx`
- `std/phoenix/types/HXXComponentRegistry.hx`
- `std/phoenix/types/HtmlComponent.hx`

Testing:

- `std/phoenix/test/Conn.hx`
- `std/phoenix/test/ConnTest.hx`
- `std/phoenix/test/LiveView.hx`
- `std/phoenix/test/LiveViewMountResult.hx`
- `std/phoenix/test/LiveViewTest.hx`

### Ecto Surface (`std/ecto`)

- `std/ecto/Schema.hx`
- `std/ecto/Changeset.hx`
- `std/ecto/Field.hx`
- `std/ecto/ChangesetApi.hx`
- `std/ecto/ChangesetBridge.hx`
- `std/ecto/Repository.hx`
- `std/ecto/DatabaseAdapter.hx`
- `std/ecto/Migration.hx`
- `std/ecto/Migrator.hx`
- `std/ecto/Query.hx`
- `std/ecto/TypedQuery.hx`
- `std/ecto/TypedQueryInstanceMacros.hx`
- `std/ecto/TypedQueryMacrosBridge.hx`
- `std/ecto/Params.hx`
- `std/ecto/test/Sandbox.hx`

### Elixir Runtime Surface (`std/elixir`)

Core modules:

- `std/elixir/Atom.hx`, `std/elixir/Kernel.hx`, `std/elixir/Enum.hx`, `std/elixir/List.hx`, `std/elixir/Tuple.hx`
- `std/elixir/ElixirMap.hx`, `std/elixir/ElixirString.hx`, `std/elixir/ElixirEnum.hx`
- `std/elixir/Agent.hx`, `std/elixir/Application.hx`, `std/elixir/GenServer.hx`,
  `std/elixir/Process.hx`, `std/elixir/Task.hx`, `std/elixir/TaskSupervisor.hx`
- `std/elixir/DateTime.hx`, `std/elixir/System.hx`, `std/elixir/Regex.hx`, `std/elixir/Stream.hx`
- `std/elixir/File.hx`, `std/elixir/Path.hx`, `std/elixir/IO.hx`, `std/elixir/Code.hx`, `std/elixir/Module.hx`
- `std/elixir/Registry.hx`, `std/elixir/Node.hx`, `std/elixir/HttpClient.hx`, `std/elixir/Jason.hx`
- `std/elixir/ErlangCrypto.hx`, `std/elixir/ErlangMath.hx`

OTP helpers:

- `std/elixir/otp/Application.hx`
- `std/elixir/otp/Supervisor.hx`
- `std/elixir/otp/TypeSafeChildSpec.hx`

Typed wrappers (`std/elixir/types`):

- `AgentRef.hx`, `Atom.hx`, `ExitReason.hx`, `GenServerCallbackResults.hx`, `GenServerOption.hx`, `GenServerRef.hx`
- `MessageQueueData.hx`, `MonitorInfo.hx`, `Pid.hx`, `Priority.hx`, `ProcessDictionary.hx`, `ProcessFlag.hx`, `ProcessInfo.hx`
- `Reference.hx`, `RegistryKey.hx`, `RegistryOptions.hx`, `Result.hx`, `TaskRef.hx`, `TaskResult.hx`, `Term.hx`, `TermDecoder.hx`

### Plug and ExUnit

- Plug: `std/plug/Conn.hx`, `std/plug/CSRFProtection.hx`
- ExUnit: `std/exunit/Assert.hx`, `std/exunit/TestCase.hx`

## Acceptance Checklist For Docs Changes

- Add/update relevant tag semantics in `ANNOTATIONS.md`
- Add/update deep-dive page for affected namespace
- Ensure index links resolve (`npm run guard:docs-links`)
- For new metadata usage in examples, add contextual first-use comments in the example file
