# `src_shared/shared/` (todo-app)

This folder contains Haxe modules intended to be used from **both** compilation targets:

- **Server**: Haxe → Elixir (Phoenix LiveView / controllers / channels)
- **Client**: Haxe → JavaScript via **genes** (Phoenix JS hooks / channels client)

The goal is a single source of truth at client/server boundaries without losing idiomatic output
on either side.

This folder is a Haxe classpath boundary, not the target Elixir namespace. A
shared protocol may be imported by both targets from `src_shared`, but generated
app-facing Elixir should still target `TodoApp.*` / `TodoAppWeb.*` modules and
Phoenix-native paths unless `Shared.*` is deliberately part of the Elixir API.
See the [Phoenix output model](../../../../docs/05-architecture/PHOENIX_OUTPUT_MODEL.md).

## What belongs here

- **Boundary types**: `typedef` shapes for payloads (JSON-like maps/objects)
  - Example: `shared.TodoTypes.Todo`, `shared.TodoTypes.User`
- **Stable names** for boundary strings
  - LiveView: `shared.liveview.EventName`, `shared.liveview.HookName`
  - Channels: protocol topics + event names
- **Shared LiveView protocols** for cross-boundary events
  - Hook events: `shared.liveview.HookEvents`
  - Repeated template events with `phx-value-*` params: `shared.liveview.TodoEvents`
  - Form events whose params should decode into typed payloads, such as
    `TodoEvent.CreateTodo(payload:CreateTodoForm)`
- **Shared channel protocols** (typed encode/decode)
  - Example: `shared.channels.PingProtocol`

## LiveView protocol example

Put the protocol in `src_shared/shared/liveview/` when both the template/server boundary and any client-side code
should agree on event names or payload shapes. The todo-app uses `TodoEvents` for two cases:

```haxe
@:liveEventProtocol
enum TodoEvent {
	@:templateEvent
	ToggleTodo(id:Int);

	@:submitEvent("todo")
	CreateTodo(payload:CreateTodoForm);
}
```

The create form remains normal Phoenix markup after compilation:

```haxe
<form phx-submit=${TodoEvents.CreateTodoEvent}>
	<input type="text" name="todo[title]" value="" />
</form>
```

The server binds the protocol with `@:liveEvents(TodoEvent)` and handles the typed payload:

```haxe
static function handleCreateTodo(
	payload:CreateTodoForm,
	socket:Socket<TodoLiveAssigns>
):HandleEventResult<TodoLiveAssigns> {
	return NoReply(createTodoFromForm(payload, socket));
}
```

The raw Phoenix/Elixir equivalent is still the familiar `handle_event/3`
shape: the event name is a string, `params` is a map, form fields are nested
under `"todo"`, and the handler decodes the boundary values before calling app
logic.

```elixir
def handle_event("toggle_todo", %{"id" => id_param}, socket) do
  case Integer.parse(id_param) do
    {id, ""} ->
      {:noreply, toggle_todo_status(id, socket)}

    _ ->
      {:noreply, socket}
  end
end

def handle_event("create_todo", %{"todo" => todo_params}, socket) do
  payload = %{
    title: Map.get(todo_params, "title"),
    description: Map.get(todo_params, "description"),
    priority: Map.get(todo_params, "priority"),
    due_date: Map.get(todo_params, "due_date"),
    tags: Map.get(todo_params, "tags")
  }

  if is_binary(payload.title) and payload.title != "" do
    {:noreply, create_todo_from_form(payload, socket)}
  else
    {:noreply, socket}
  end
end
```

PhoenixHx keeps that same runtime model. The protocol macro generates event
constants, HXX event-name checks, Phoenix-shaped param reads, primitive parsing,
and the explicit dispatcher call so the Haxe handler receives `id:Int` or
`payload:CreateTodoForm` instead of hand-reading string keys at every call site.
That is the UX win: one shared declaration gives editor completion, fewer
duplicated event/key strings, generated decode boilerplate, and compile-time
feedback when a handler, template event, or payload field drifts.

Keep direct PhoenixHx for smaller one-off events. In this app, edit/save still uses `EventName.SaveTodo` and
explicit param reads, which is shorter and clearer for that local flow.

## What should *not* belong here

- Code that can only run on one target **unless** it is either:
  - implemented for both targets, or
  - clearly documented as target-specific and never referenced from the other build.

## Build defines you’ll see

- Server build (`build-server.hxml`):
  - `-lib reflaxe.elixir` (supplies the `elixir` target marker)
  - `-D elixir_output=...` (selects the Elixir target output dir)
- Client build (`build-client.hxml`):
  - `-lib genes-ts` (exact-pinned JS/TypeScript generator)
  - `-lib phoenix_js` (typed Phoenix JS externs)

In shared code, you’ll sometimes see:
- `#if elixir` guards

Why:
- `elixir` is supplied by the server target library and is absent from the Genes client build.
- `reflaxe_runtime` is reserved for compiler-development HXML files and should not be
  used to select an application target.

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
