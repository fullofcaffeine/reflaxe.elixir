# LiveView Assign And Stream API (Haxe -> Phoenix)

This page explains the assign and stream authoring styles and when to use each one.

## Why this page exists

Both styles generate normal Phoenix calls at runtime. The choice is about Haxe authoring ergonomics:

- default macro selector style: least code to write
- typed-key style: explicit key tokens and stronger key/value coupling
- typed-stream style: explicit stream-name tokens and stronger name/item coupling

## Quick Choice Guide

| Goal | Haxe API | Phoenix runtime call |
| --- | --- | --- |
| Shortest single-field update | `assign(_.field, value)` | `assign(socket, :field, value)` |
| Phoenix-style multi-field update | `assign({field_a: a, field_b: b})` | `assign(socket, %{field_a: a, field_b: b})` |
| Typed key-token style (optional) | `assignKey(keys.field, value)` | `assign(socket, :field, value)` |
| Set default-if-missing | `assignNew(_.field, fn)` or `assignNewKey(keys.field, fn)` | `assign_new(socket, :field, fn -> ... end)` |
| Update from previous value | `update(_.field, fn)` or `updateKey(keys.field, fn)` | `update(socket, :field, fn prev -> ... end)` |
| Initialize a LiveView stream | `stream(streams.todos, todos)` | `Phoenix.LiveView.stream(socket, :todos, todos)` |
| Mutate a LiveView stream | `streamInsert(streams.todos, todo)` / `streamDelete(streams.todos, todo)` | `Phoenix.LiveView.stream_insert/delete(socket, :todos, todo)` |

## Consumer View

### 1) Default single-field style (`assign(_.field, value)`)

```haxe
socket = socket.assign(_.count, 0);
```

Why this exists:

- Haxe has no built-in typed field-reference literal for typedef fields.
- `_.field` is a compact compile-time selector read by the assign macro.

What you get:

- compile-time field-name validation
- automatic `camelCase -> snake_case` atom conversion
- idiomatic Phoenix `assign/3` output

### 2) Default bulk style (`assign({...})`)

```haxe
socket = socket.assign({
  count: 0,
  search_query: ""
});
```

Why this exists:

- It maps directly to Phoenix `assign(socket, %{...})`.
- It keeps the API close to Phoenix `assign/2` shape.

What you get:

- compile-time field-name validation for each object field
- snake_case atom-key rewrite in generated Elixir

### 3) Optional typed-key style (`assignKey(keys.field, value)`)

```haxe
import phoenix.AssignKeys;

typedef CounterAssigns = { count: Int };

var keys = AssignKeys.of(CounterAssigns);

socket = socket.assignKey(keys.count, 0);
socket = socket.updateKey(keys.count, (n) -> n + 1);
```

Why this exists:

- Some teams want explicit key tokens in function signatures.
- It binds key and value types at the type-token level.

What you get:

- key-specific value typing (`keys.count` enforces `Int`)
- optional better field completion from `keys.<field>`

### Compare the two styles

| Aspect | `assign(_.field, value)` / `assign({...})` | `assignKey(keys.field, value)` |
| --- | --- | --- |
| Setup required | none | one `var keys = AssignKeys.of(MyAssigns)` |
| Code size | shortest | slightly more explicit |
| Runtime mapping | Phoenix-faithful | Phoenix-faithful |
| Key/value typing | field name validated; value typed by call context | explicit key token carries value type |
| Good default for most apps | yes | optional advanced mode |

### 4) Optional typed-stream style (`stream(streams.field, items)`)

```haxe
import phoenix.LiveStreams;

typedef Todo = {
  var id:Int;
  var title:String;
}

typedef TodoAssigns = {
  var todos:Array<Todo>;
}

var streams = LiveStreams.of(TodoAssigns);

socket = socket.stream(streams.todos, todos);
socket = socket.streamInsert(streams.todos, newTodo);
socket = socket.streamDelete(streams.todos, oldTodo);
```

Why this exists:

- Phoenix streams are named atom collections under `assigns.streams`.
- Stream items have a stable shape, and the name/item pairing is easy to mix up in larger apps.
- `LiveStreams.of(...)` keeps the Phoenix primitive visible while giving Haxe completion and type checking.

What you get:

- `Array<T>` fields become `LiveStreamName<TAssigns, T>` tokens.
- `streamInsert` and `streamDelete` require the item type paired with the selected stream.
- generated output uses normal Phoenix calls: `Phoenix.LiveView.stream(socket, :todos, todos)`, `stream_insert`, and `stream_delete`.

Raw `phoenix.Phoenix.LiveView.stream(socket, "todos", todos)` remains available for direct Phoenix interop and older code. Prefer typed stream tokens for app-owned stream names.

### Do I need `@:build(...)`?

Usually, no.

- If you use default assign APIs (`assign`, `assignNew`, `update`, bulk `assign({...})`), you do not need `@:build(...)`.
- If you use typed keys, prefer `AssignKeys.of(MyAssigns)` first.
- `@:build(phoenix.macros.AssignKeysBuilder.build(MyAssigns))` is still supported when you explicitly want a dedicated static key class.

### Do I need `LiveSocket<T>`?

Usually, no.

- In callbacks, `socket: Socket<TAssigns>` can call assign helpers directly.
- `LiveSocket<TAssigns>` remains available as an explicit wrapper if you prefer wrapper-style helper signatures or pipe-oriented code.

## Technical View

### `assign` arity model

`assign` is implemented as one macro entrypoint with an optional value:

- `assign(fieldOrUpdates, ?value)`

Dispatch rules:

- `value` omitted + object literal -> validate fields + emit bulk assign map
- `value` omitted + non-literal map value -> pass through to `phoenix.Component.assign(socket, updates)`
- `value` provided + first arg is `_.field` -> validate field + emit atom key
- `value` provided + first arg is not `_.field` -> pass through to `phoenix.Component.assign(socket, key, value)`

Source:

- `std/phoenix/SocketAssignExtensions.hx`
- `std/phoenix/LiveSocket.hx`
- `std/phoenix/macros/AssignMacro.hx`

### Why not `@:overload` on `assign`?

This API needs syntax-shape dispatch (`_.field` vs object literal), not only type-based overload selection. Macro dispatch is the right fit here.

`@:overload` is still used where it fits (for example `phoenix.Component.assign` extern signatures).

### `merge({...})` status

`merge({...})` remains as a backward-compatible alias. Prefer `assign({...})` for clearer Phoenix parity.

### Typed-key lowering details

`assignKey` / `assignNewKey` / `updateKey` are macro-based too.

- When the key expression is field-shaped (`keys.count`, `MyKeys.count`), the compiler emits a direct atom key (`:count`) for clean Phoenix output.
- When the key is a computed token expression, the compiler passes that token expression through.

### Key generation details

Typed-key mode has two generation options:

- preferred:
  - `phoenix.AssignKeys.of(MyAssigns)`
- optional static-class mode:
  - `@:build(phoenix.macros.AssignKeysBuilder.build(MyAssigns))`

Both use the same key normalization (`camelCase -> snake_case`) and produce `AssignKey<TAssigns, TValue>` tokens.

Source:

- `std/phoenix/AssignKeys.hx`
- `std/phoenix/types/AssignKey.hx`
- `std/phoenix/macros/AssignKeysBuilder.hx`
- `std/phoenix/macros/AssignKeysSupport.hx`

### Stream generation details

Typed-stream mode is generated on demand:

- `phoenix.LiveStreams.of(MyAssigns)` reads list-shaped assigns fields.
- `Array<T>` fields become `LiveStreamName<MyAssigns, T>` tokens.
- Non-list fields are ignored because Phoenix streams are collection-oriented.
- Field names use the same `camelCase -> snake_case` atom normalization as assign keys.

Source:

- `std/phoenix/LiveStreams.hx`
- `std/phoenix/types/LiveStreamName.hx`
- `std/phoenix/macros/LiveStreamMacro.hx`

### Error behavior summary

- `assign(_.missingField, value)` -> compile-time error (unknown assigns field)
- `assign({missing_field: value})` -> compile-time error (unknown assigns field)
- `assignKey(keys.count, "x")` when `count` is `Int` -> compile-time type error
- `assign(nonLiteralMap)` -> forwarded to Phoenix assign/2 runtime call
- `streamInsert(streams.todos, "x")` when `todos` is `Array<Todo>` -> compile-time type error

## See Also

- `docs/02-user-guide/haxe-for-phoenix.md`
- `docs/07-patterns/PHOENIX_LIVEVIEW_PATTERNS.md`
- `docs/04-api-reference/PHOENIX_API_REFERENCE.md`
