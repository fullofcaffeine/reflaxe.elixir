# Reflaxe.Elixir Annotations Reference

Complete guide to using annotations in Reflaxe.Elixir for generating Elixir/Phoenix code.

## Overview

Reflaxe.Elixir uses Haxe metadata annotations to control code generation. Annotations tell the compiler how to transform Haxe classes into specific Elixir modules and patterns.

## Supported Annotations

### @:socket - Phoenix Socket (Channels)

Marks a class as a `Phoenix.Socket` module for Channels.

This is used alongside `@:socketChannels([...])` to declare topic routing. The compiler emits:

- `use Phoenix.Socket`
- `channel "<topic>", <ChannelModule>`
- default `connect/3` and `id/1` definitions if you don’t provide them

**Usage**:
```haxe
@:native("MyAppWeb.UserSocket")
@:socket
@:socketChannels([{topic: "typed:*", channel: server.channels.PingChannel}])
class UserSocket {}
```

### @:socketChannels([...]) - Socket Topic Routing

Declares the `channel/2` routes for a `@:socket` module.

- Each entry must be an object literal `{topic: String, channel: <Haxe type reference>}`.
- The `channel` type is resolved to its fully-qualified Elixir module name at compile time (respects `@:native`).

### @:endpointSockets([...]) - Endpoint Socket Mounts

Adds one or more `socket/3` mounts to a `@:endpoint` module (for example, to mount Channels at `"/socket"`).

**Usage**:
```haxe
@:native("MyAppWeb.Endpoint")
@:endpoint
@:endpointSockets([{path: "/socket", socket: server.infrastructure.UserSocket, session: true}])
class Endpoint {}
```

### @:endpoint({...}) - Endpoint Options

Configures endpoint-level generation options for a `@:endpoint` module.

Current options:

- `liveLongpoll: Bool` (default: `true`)
  - Controls whether the generated LiveView socket mount at `"/live"` emits longpoll transport config.
  - Default output is Phoenix-faithful and includes both websocket and longpoll for LiveView.
  - Set `false` to emit `longpoll: false` for `"/live"`.

**Usage**:
```haxe
@:native("MyAppWeb.Endpoint")
@:endpoint({liveLongpoll: false})
class Endpoint {}
```

### @:controller - Phoenix Controller

Marks a class as a Phoenix controller for handling HTTP requests.

**Basic Usage**:
```haxe
import elixir.types.Term;
import plug.Conn;

@:controller
class UserController {
    public static function index(conn: Conn<Term>, params: Term): Conn<Term> {
        return conn.json({ok: true});
    }
}
```

`@:controller` defines controller modules and actions. Route wiring is usually done in a `@:router` declaration with module-level `final routes = [...]`.

`@:route(...)` still exists for legacy/manual router patterns (see below), but new code should prefer module-level typed route nodes.

### @:router - Phoenix Router Configuration

Marks a class as a Phoenix router for request routing.

**Recommended Usage (module-level `final routes` + static-imported router nodes)**:
```haxe
import reflaxe.elixir.macros.RouterDsl.*;
import controllers.UserController;

typedef UserPathParams = {
  var id:Int;
}

@:native("MyAppWeb.Router")
@:router
final routes = [
  pipeline(browser, [
    plug(accepts, {initArgs: ["html"]}),
    plug(fetch_session)
  ]),
  scope("/", [
    pipeThrough([browser]),
    get("/users/:id", UserController, UserController.show, {
      paramsContract: UserPathParams
    })
  ])
];
```

**Legacy Manual Usage (`@:route`)**:
```haxe
@:router
class LegacyRouter {
  @:route({method: "GET", path: "/users", controller: "controllers.UserController", action: "index"})
  public static function usersIndex(): String {
    return "/users";
  }
}
```

Use module-level `final routes = [...]` for new code. Static-imported router nodes map directly to Phoenix router nesting and enable extra compile-time checks.
For finite router atoms, prefer typed tokens (`browser`, `accepts`, `fetch_session`) over raw strings.
Use `pipelineName("...")` / `plugName("...")` for custom typed names, and `pipelineUnsafe` / `plugUnsafe` only for intentional dynamic/legacy values.
Use `@:routes` as a compatibility surface when migrating existing code.
Use `@:route` only for manual/legacy router glue where string literals are acceptable.

`@:routes` controller string literals (`controller: "..."`) now emit warnings by default.
Set `-D router_strict_typed_refs` to treat them as compile errors and enforce typed refs in CI.

Typed router-node routes with path params (for example `/users/:id`) require `paramsContract` in options.

See the full guide: `docs/04-api-reference/ROUTER_DSL.md`.

### @:schema - Ecto Schema Generation

Generates Ecto.Schema modules for database models.

**Basic Usage**:
```haxe
@:schema("users")
class User {
    @:primary_key
    public var id: Int;
    
    @:field({type: "string", nullable: false})
    public var name: String;
    
    @:field({type: "string", nullable: false})
    public var email: String;
    
    @:field({type: "integer"})
    public var age: Int;
    
    @:timestamps
    public var insertedAt: String;
    public var updatedAt: String;
}
```

**Generated Elixir**:
```elixir
defmodule User do
  use Ecto.Schema
  
  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer
    
    timestamps()
  end
end
```

**Field Annotations**:
- `@:primary_key` - Primary key field
- `@:field({options})` - Regular field with options
- `@:timestamps` - Automatic timestamp fields
- `@:has_many(field, module?, foreign_key?)` - Has many association
- `@:has_one(field, module?, foreign_key?)` - Has one association
- `@:belongs_to(field, module?, foreign_key?)` - Belongs to association
- `@:many_to_many(field, module?, join_through?)` - Many-to-many association

#### Association Validation (Compile-Time)

Reflaxe.Elixir validates common Ecto association shapes at **compile time** to catch relationship mistakes early.

What is validated:

- `@:belongs_to("assoc")`: the schema must declare a local FK field.
  - Default: `<assoc>_id`
  - Override: pass a third string param or an options object with `foreign_key`.
- `@:has_many("assoc")` / `@:has_one("assoc")`: when the target schema type is resolvable, the target schema must declare the FK field back to the source schema.
  - Default: `<source_schema>_id` (from the source class name)
  - Override: pass a third string param or an options object with `foreign_key`.
- `@:many_to_many`: not validated (join table mediated).

Field name equivalence:

- FK checks compare **snake_cased names**, so `userId` and `user_id` are treated as the same field.

Example:

```haxe
@:schema("users")
class User {
  @:field public var id: Int;

  @:has_many("posts")
  public var posts: Array<Post>;
}

@:schema("posts")
class Post {
  @:field public var id: Int;

  // Required by @:belongs_to("user") unless overridden.
  @:field public var userId: Int;

  @:belongs_to("user")
  public var user: User;
}
```

**Configuration / Escape Hatches**

- Default: missing FK fields are **errors** (compilation fails).
- `-D ecto_assoc_warn_only`: downgrade missing-FK errors to **warnings**.
- `-D ecto_no_assoc_validation`: disable association validation globally.
- `@:ecto_no_assoc_validation`: disable association validation for a single `@:schema` class.

**Limitations (By Design)**

- This validation does **not** introspect your database or migrations. Use migrations + runtime constraints
  (`foreign_key_constraint`, etc.) for full DB integrity.
- Cross-schema validation for `@:has_many`/`@:has_one` requires the target schema type to be resolvable in the
  current compilation (e.g. `Array<Post>`).
  - Prefer typed fields (`Array<Post>`, `Post`) so the validator can resolve the target schema reliably.
  - If the target type cannot be inferred from the field type, you can provide a string hint as the second param
    (e.g. `@:has_many("posts", "Post")`) as long as that type is part of the same Haxe compilation.
  - If the target is dynamic/unresolvable/ambiguous, validation skips with a warning.

### @:changeset - Ecto Changeset Validation

Generates Ecto.Changeset modules for data validation.

Notes:

- The generated changeset uses **Ecto** `cast` + `validate_required` by default.
  - This `cast` is `Ecto.Changeset.cast/3` (or `/4`), not a Haxe type cast.
  - It’s the standard Ecto entry point for taking external params (often string-keyed / string values),
    whitelisting permitted fields, and casting them into the schema’s field types.

**Basic Usage**:
```haxe
import ecto.Changeset;
import ecto.Field;

typedef UserParams = {
    ?name: String,
    ?email: String
}

@:native("MyApp.User")
@:schema("users")
@:timestamps
@:changeset(cast(["name", "email"]), validate(["name", "email"]))
class User {
    @:field @:primary_key public var id: Int;
    @:field public var name: String;
    @:field public var email: String;
}
```

`@:schema` auto-injects a typed `changeset<Params>(schema, params)` declaration when one is not present,
so manual `extern` boilerplate is optional.

Optional compatibility path:

```haxe
class User {
    extern public static function changeset(user: User, params: UserParams): Changeset<User, UserParams>;
}
```

**Generated Elixir**:
```elixir
defmodule MyApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    timestamps()
  end

  def changeset(user, params) do
    user
    |> cast(params, [:name, :email])
    |> validate_required([:name, :email])
  end
end
```

Named `@:changeset` config is the recommended form for readability.

Legacy positional form remains supported:
```haxe
@:changeset(["name", "email"], ["name", "email"])
```

For manual changeset pipelines, prefer checked field selectors over raw strings:

```haxe
static function changeset(user:User, params:UserParams):Changeset<User, UserParams> {
    return new Changeset(user, params)
        .validateRequired([
            Field.of((user:User) -> user.name),
            Field.of((user:User) -> user.email)
        ])
        .validateLength(Field.of((user:User) -> user.name), {min: 2, max: 80});
}
```

`Field.of` forces Haxe to type-check the selector, so a typo such as `user.emali` fails during
compilation instead of becoming a bad Ecto field name. It lowers to a schema-typed token that
generates the atom Ecto expects, including camelCase-to-snake_case conversion.

String literals remain accepted for migration and compile to atom fields when passed directly to
changeset APIs. For dynamic runtime strings, use `Field.unsafe<SchemaType>(fieldName)` so atom
creation is visible at the callsite.

**Validation Annotations**:
- `@:validate_required([fields])` - Required field validation
- `@:validate_format(field, pattern)` - Format validation
- `@:validate_length(field, {min, max})` - Length validation
- `@:validate_number(field, {greater_than, less_than})` - Number validation
- `@:unique_constraint(field)` - Unique constraint validation

### @:liveview - Phoenix LiveView

Generates Phoenix LiveView modules for real-time UI.

**Basic Usage**:
```haxe
import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;

typedef UserAssigns = { users: Array<User> }

@:liveview
class UserLive {
    public static function mount(params: Term, session: Term, socket: Socket<UserAssigns>): MountResult<UserAssigns> {
        socket = socket.assign({users: []});
        return Ok(socket);
    }
    
    public static function handleEvent(event: String, params: Term, socket: Socket<UserAssigns>): HandleEventResult<UserAssigns> {
        return NoReply(socket);
    }
    
    public static function render(assigns: UserAssigns): String {
        return "<div>User LiveView</div>";
    }
}
```

Notes:
- Use plain Haxe parameter names (`params`, `session`) unless you prefer `_params` style.
- If a callback parameter is unused, generated Elixir will still follow convention and prefix it with `_`.

**Generated Elixir**:
```elixir
defmodule UserLive do
  use Phoenix.LiveView
  
  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, %{users: []})}
  end
  
  @impl true
  def handle_event(event, params, socket) do
    {:noreply, socket}
  end
  
  @impl true
  def render(assigns) do
    ~H"""
    <div>User LiveView</div>
    """
  end
end
```

### Template / HXX Metadata (Phoenix HEEx)

These annotations control how Reflaxe.Elixir processes HEEx templates authored from Haxe.

Default authoring path for new Phoenix code is strict inline markup:

```haxe
@:liveview
class MyLive {
  public static function render(assigns: MyAssigns): String {
    return <div>${assigns.count}</div>;
  }
}
```

Legacy `hxx('...')` / `HXX.hxx('...')` string templates remain supported for balanced-mode migration code, but should not be used for new app templates.

#### @:allow_heex (Escape Hatch, Avoid)

By default, raw EEx/HEEx markers (`<% ... %>`, `<%= ... %>`) are rejected inside Haxe-authored templates because they bypass the HXX linting surface.

Add `@:allow_heex` to a **class** or **function** to opt in explicitly:

```haxe
@:liveview
class MyLive {
  @:allow_heex
  @:hxx_mode("balanced")
  public static function render(assigns: MyAssigns): String {
    return hxx('<div><%= @count %></div>');
  }
}
```

Global escape hatch (migration only): `-D hxx_allow_raw_heex`.

#### @:hxx_mode (Template Authoring Mode)

Select how strict the template authoring surface should be for a scope (class or function).

```haxe
@:liveview
class MyLive {
  public static function render(assigns: MyAssigns): String {
    return <div>${assigns.count}</div>;
  }
}
```

Most code should not need this metadata. TSX-style inline markup is the default for new templates; `@:hxx_mode(...)` exists for local migration/interop overrides. It controls HXX/HEEx template parsing only. It is not a portable/Elixir-first application profile and it does not switch compiler backends.

Modes:

- default / `@:hxx_mode("tsx")`: strict typed authoring and the default path for new code. Disallows raw `<% ... %>` escape hatches, disallows legacy string-template markers (`#{...}`, `<if { ... }>` / `<for { ... }>`), and rejects `hxx('...')` / `HXX.block('...')` usage in that scope. Supports typed TSX control tags (`<if ${...}>`, `<for ${item in items}>`) and typed spread attrs in tag position (`{assigns.attrs}` / `{@assigns.attrs}`). The metadata form is only needed to override an enclosing/global non-TSX mode.
- `@:hxx_mode("balanced")`: compatibility behavior; inline markup is available, but legacy template strings are allowed. Raw `<% ... %>` requires `@:allow_heex` (or `-D hxx_allow_raw_heex` during migration). Use this only for migration modules or legacy test fixtures.
- `@:hxx_mode("metal")`: allows raw `<% ... %>` without `@:allow_heex` (discouraged; emits warnings).

`metal` is scoped to HXX/HEEx template authoring. It is not an application-wide Reflaxe.Elixir profile; use `portable` or `Elixir-first` terminology for that source-authoring decision.

Precedence:

- Function-level `@:hxx_mode(...)` overrides class-level `@:hxx_mode(...)`.

#### Inline Markup Controls

Inline markup (`return <div>...</div>`) is rewritten into a canonical template entrypoint and lowered to `~H` by the compiler.

Controls:

- `@:hxx_no_inline_markup`: opt out for a module.
- `-D hxx_no_inline_markup`: opt out globally.
- `@:hxx_inline_markup`: force-enable for non-Phoenix modules (default scope is Phoenix-facing modules like `@:liveview`, `@:component`, etc).
- `@:hxx_legacy`: deprecated migration-only escape hatch. It forces the legacy rewrite path (wrap markup payload in `HXX.hxx("...")`), emits a warning, and is rejected in TSX mode.

#### Strictness Toggles (Local Metadata)

Most HXX strict checks can be enabled either globally (via `-D ...`) or locally (via `@:...` metadata on the class or function).

Available strictness annotations:

- `@:hxx_strict_components` (global: `-D hxx_strict_components`)
- `@:hxx_strict_slots` (global: `-D hxx_strict_slots`)
- `@:hxx_strict_html` (global: `-D hxx_strict_html`)
- `@:hxx_strict_phx_hook` (global: `-D hxx_strict_phx_hook`)
- `@:hxx_strict_phx_events` (global: `-D hxx_strict_phx_events`)
- `@:hxx_strict_attr_values` (global: `-D hxx_strict_attr_values`)
- `@:hxx_allow_string_fallback` (global: `-D hxx_allow_string_fallback`)

### @:presence - Phoenix Presence

Transforms a class into a Phoenix.Presence module for real-time presence tracking across distributed nodes.

**Purpose**: Phoenix Presence is a distributed presence tracking system that allows you to:
- Track who's online in real-time across multiple server nodes
- Synchronize user state (e.g., "typing", "editing", "idle") across all connected clients
- Handle node failures gracefully with CRDT-based conflict resolution
- Build collaborative features like "users currently viewing this page" or "users editing this document"

**How It Works**:
1. The `@:presence` annotation tells the compiler to inject `use Phoenix.Presence, otp_app: :your_app`
2. Implementing `PresenceBehavior` generates topic-aware helpers such as `trackWithSocket`, `list`, and `getByKey`
3. Presence data is automatically synchronized across all nodes in your cluster
4. Each key gets one or more metadata entries, depending on how many processes track it

**Basic Usage**:
```haxe
import phoenix.PresenceBehavior;
import phoenix.PresenceKey;
import phoenix.PresenceTopic;

@:native("TodoAppWeb.Presence")
@:presence
class TodoPresence implements PresenceBehavior {}

// From a LiveView callback:
var topic = PresenceTopic.of("users");
var key = PresenceKey.of(Std.string(user.id));
socket = TodoPresence.trackWithSocket(socket, topic, key, {
    onlineAt: Date.now().getTime(),
    userName: user.name,
    status: "active"
});

var onlineUsers = TodoPresence.list(topic);
```

**Generated Elixir**:
```elixir
defmodule TodoAppWeb.Presence do
  use Phoenix.Presence, otp_app: :todo_app
end

# From the generated LiveView:
TodoAppWeb.Presence.track(self(), "users", to_string(user.id), %{
  online_at: online_at,
  user_name: user.name,
  status: "active"
})

online_users = TodoAppWeb.Presence.list("users")
```

**Common Use Cases**:
- **Online Users List**: Show who's currently online in a chat or collaboration app
- **Typing Indicators**: Show when someone is typing in real-time
- **Collaborative Editing**: Track who's editing which part of a document
- **Live Cursors**: Show other users' cursor positions in collaborative tools
- **User Status**: Display user status (active, away, busy) across the app

**Best Practices**:
1. **Single Presence Entry Per User**: Use one presence entry with all state, not multiple entries
2. **Update, Don't Track/Untrack**: Use `update` to change state instead of untrack/track cycles
3. **Minimal Metadata**: Keep presence metadata small for efficient synchronization
4. **Topic Organization**: Use meaningful topic names like "users", "document:123", etc.

### @:genserver - OTP GenServer

Generates OTP GenServer modules for stateful processes.

**Basic Usage**:
```haxe
import elixir.types.Term;
import elixir.types.GenServerCallbackResults.HandleCallResult;
import elixir.types.GenServerCallbackResults.InitResult;

@:genserver
class Counter {
    private var count: Int = 0;
    
    public static function init(_args: Term): InitResult<Int> {
        return Ok(0);
    }
    
    public static function handle_call(msg: String, _from: Term, state: Int): HandleCallResult<Int, Int> {
        return switch (msg) {
            case "get": Reply(state, state);
            case "increment": Reply(state + 1, state + 1);
            case _: Reply(state, state);
        };
    }
}
```

**Generated Elixir**:
```elixir
defmodule Counter do
  use GenServer
  
  def init(_args) do
    {:ok, 0}
  end
  
  def handle_call("get", _from, state) do
    {:reply, state, state}
  end
  
  def handle_call("increment", _from, state) do
    {:reply, state + 1, state + 1}
  end
  
  def handle_call(_, _from, state) do
    {:reply, "unknown", state}
  end
end
```

### @:migration - Ecto Migration (Experimental)

Marks a Haxe migration (built on `std/ecto/Migration.hx`) so the compiler can process it.

  > **Status (Experimental)**: Runnable via **opt-in `.exs` emission**.
  >
  > Ecto executes migrations from `priv/repo/migrations/*.exs`. Reflaxe.Elixir can emit runnable
  > migrations when you compile **only** your `@:migration` classes with:
  >
  > - `-D ecto_migrations_exs` (switch output extension to `.exs` + enable migration rewrite)
  > - `-D elixir_output=priv/repo/migrations`
  >
  > Each migration must declare a stable timestamp (used for the filename ordering):
  > `@:migration({timestamp: "YYYYMMDDHHMMSS"})`.

**Supported subset for runnable `.exs` emission** (`-D ecto_migrations_exs`)

The `.exs` rewrite pass currently supports a focused, safe subset of the typed DSL:

- `createTable("table")` with a fluent chain of:
  - `.addColumn("name", ColumnType.*(...), ?options)`
  - `.addReference("column", "referenced_table", ?options)`
  - `.addForeignKey("column", "referenced_table", ?options)` (alias for `addReference`)
  - `.addTimestamps()`
  - `.addIndex(["col", ...], ?options)` (supports `unique: true`)
  - `.addUniqueConstraint(["col", ...], ?name)`
  - `.addCheckConstraint("name", "sql expression")`
  - `.addId()` (default id only; custom primary keys are not supported yet in `.exs` mode)
- `dropTable("table")` in `down()`

Limitations (current)
- Table/column names must be **string literals** in `.exs` mode.
- `alterTable`, `execute`, `createIndex`, `dropIndex`, and custom `createTable` options are not rewritten yet.
  Keep these migrations as hand-written Elixir when you need advanced DSL features.

**Basic Usage**:
```haxe
import ecto.Migration;
import ecto.Migration.ColumnType;

  @:migration({timestamp: "20240101120000"})
  class CreateUsersTable extends Migration {
    public function new() {}

    public function up(): Void {
        createTable("users")
            .addId()
            .addColumn("name", ColumnType.String(), {nullable: false})
            .addColumn("email", ColumnType.String(), {nullable: false})
            .addColumn("age", ColumnType.Integer)
            .addTimestamps()
            .addIndex(["email"], {unique: true});
    }
    
    public function down(): Void {
        dropTable("users");
    }
}
```

### @:template - Phoenix Template

Generates Phoenix HEEx template modules.

**Basic Usage**:
```haxe
import phoenix.types.Assigns;

typedef CardAssigns = { user: User };

@:template
class UserTemplate {
    public function user_card(assigns: Assigns<CardAssigns>): String {
        return """
        <div class="user-card">
            <h3>{assigns.user.name}</h3>
            <p>{assigns.user.email}</p>
        </div>
        """;
    }
}
```

**Generated Elixir**:
```elixir
defmodule UserTemplate do
  use Phoenix.Component
  
  def user_card(assigns) do
    ~H"""
    <div class="user-card">
      <h3><%= @user.name %></h3>
      <p><%= @user.email %></p>
    </div>
    """
  end
end
```

### @:protocol - Elixir Protocol

Defines polymorphic behavior through protocols.

**Basic Usage**:
```haxe
import elixir.types.Term;

@:protocol
class Stringable {
    @:callback
    public function toString(data: Term): String {
        throw "Protocol function must be implemented";
    }
}
```

**Generated Elixir**:
```elixir
defprotocol Stringable do
  @doc "Convert data to string representation"
  def to_string(data)
end
```

### @:impl - Protocol Implementation

Implements a protocol for a specific type.

**Basic Usage**:
```haxe
@:impl("Stringable", "User")
class UserStringable {
    public function toString(user: User): String {
        return 'User: ${user.name}';
    }
}
```

**Generated Elixir**:
```elixir
defimpl Stringable, for: User do
  def to_string(user) do
    "User: #{user.name}"
  end
end
```

### @:behaviour - Elixir Behavior

Defines callback contracts for modules.

**Basic Usage**:
```haxe
import haxe.functional.Result;

typedef ProcessorConfig = { ?batchSize: Int }
typedef ProcessorState = { processedCount: Int }

@:behaviour
class DataProcessor {
    @:callback
    public function init(config: ProcessorConfig): Result<ProcessorState, String> {
        throw "Callback must be implemented";
    }
    
    @:callback
    public function process(data: elixir.types.Term): elixir.types.Term {
        throw "Callback must be implemented";
    }
    
    @:optional_callback
    public function cleanup(): Void {
        // Optional cleanup
    }
}
```

**Generated Elixir**:
```elixir
defmodule DataProcessor do
  @callback init(config :: any()) :: {:ok, any()} | {:error, String.t()}
  @callback process(data :: any()) :: any()
  
  @optional_callbacks cleanup: 0
  @callback cleanup() :: :ok
end
```

## Annotation Combinations

Some annotations can be used together:

- `@:schema` + `@:changeset` - Data model with validation
- `@:liveview` + `@:template` - LiveView with template rendering
- `@:controller` + `@:route` - Controller with route definitions
- `@:behaviour` + `@:genserver` - GenServer implementing behavior
- `@:application` + `@:appName` - OTP Application with configurable module names
- `@:appName` + Any annotation - App name configuration is compatible with all annotations

## Annotation Conflicts

The following combinations are mutually exclusive:

- `@:genserver` and `@:liveview` - Choose one behavior type
- `@:schema` and `@:migration` - Schema is runtime, migration is compile-time
- `@:protocol` and `@:behaviour` - Different polymorphism approaches

### @:application - OTP Application Module

Marks a class as an OTP Application module that defines a supervision tree.

**Basic Usage**:
```haxe
import elixir.Atom;
import elixir.otp.Application;
import elixir.otp.Supervisor.ChildSpecFormat;
import elixir.otp.Supervisor.SupervisorExtern;
import elixir.otp.Supervisor.SupervisorOptions;
import elixir.otp.Supervisor.SupervisorStrategy;
import elixir.otp.TypeSafeChildSpec;
import elixir.types.Term;
import my_app.infrastructure.Endpoint;
import my_app.infrastructure.PubSub;
import my_app.infrastructure.Repo;
import my_app.infrastructure.Telemetry;

@:application
@:native("MyApp.Application")
class MyApp {
    public static function start(type: ApplicationStartType, args: ApplicationArgs): ApplicationResult {
        // Define children for supervision tree
        var children:Array<ChildSpecFormat> = [
            TypeSafeChildSpec.moduleRef(Repo),
            TypeSafeChildSpec.pubSub(PubSub),
            TypeSafeChildSpec.telemetry(Telemetry),
            TypeSafeChildSpec.endpoint(Endpoint)
        ];
        
        // Start supervisor with children
        var opts:SupervisorOptions = {
            strategy: SupervisorStrategy.OneForOne,
            max_restarts: 3,
            max_seconds: 5
        };
        return SupervisorExtern.startLink(children, opts);
    }
    
    public static function config_change(changed: Term, new_config: Term, removed: Term): Term {
        // Handle configuration changes
        return Atom.fromString("ok");
    }
}
```

**Generated Elixir**:
```elixir
defmodule MyApp.Application do
  @moduledoc false
  
  use Application
  
  @impl true
  def start(_type, _args) do
    children = [
      MyApp.Repo,
      {Phoenix.PubSub, name: MyApp.PubSub},
      MyAppWeb.Endpoint
    ]
    
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
  
  @impl true
  def config_change(changed, _new, removed) do
    MyAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
```

**Key Features**:
- Automatically adds `use Application` directive
- Transforms child specifications into proper OTP format
- Supports typed module references via `TypeSafeChildSpec.*`
- Adds `@impl true` annotations for callbacks
- Supports config_change callback for hot reloading

**Child Specification Guidance**:
- Preferred: typed `TypeSafeChildSpec` methods (`moduleRef`, `pubSub`, `endpoint`, `telemetry`, etc.)
- Dynamic/manual escape hatch: explicit `TypeSafeChildSpec.*Unsafe(...)` methods
- Supervisor options are converted to keyword lists in generated Elixir

See canonical child-spec docs: `docs/04-api-reference/TYPE_SAFE_CHILD_SPEC.md`.

### @:elixirIdiomatic - Idiomatic Elixir Pattern Generation

Marks a user-defined enum to generate idiomatic Elixir patterns instead of literal patterns.

**Basic Usage**:
```haxe
@:elixirIdiomatic
enum UserOption<T> {
    Some(value: T);
    None;
}

@:elixirIdiomatic  
enum ApiResult<T, E> {
    Ok(value: T);
    Error(reason: E);
}
```

**Generated Elixir (with @:elixirIdiomatic)**:
```elixir
defmodule UserOption do
  @type t() ::
    {:ok, term()} |
    :error

  def some(arg0), do: {:ok, arg0}
  def none(), do: :error
end

defmodule ApiResult do
  @type t() ::
    {:ok, term()} |
    {:error, term()}

  def ok(arg0), do: {:ok, arg0}
  def error(arg0), do: {:error, arg0}
end
```

**Generated Elixir (without @:elixirIdiomatic)**:
```elixir
defmodule UserOption do
  @type t() ::
    {:some, term()} |
    :none

  def some(arg0), do: {:some, arg0}
  def none(), do: :none
end
```

**Key Differences**:
- **Idiomatic patterns**: `{:ok, value}` / `:error` (standard Elixir conventions)
- **Literal patterns**: `{:some, value}` / `:none` (direct translation from Haxe)

**When to Use @:elixirIdiomatic**:
- When integrating with Elixir libraries that expect standard `:ok` / `:error` patterns
- When building APIs that should follow BEAM ecosystem conventions
- When you want your Haxe enums to feel natural to Elixir developers

**Standard Library Behavior**:
Standard library types always use idiomatic patterns regardless of annotation:
- `haxe.ds.Option<T>` → Always generates `{:ok, value}` / `:error`
- `haxe.functional.Result<T,E>` → Always generates `{:ok, value}` / `{:error, reason}`

### @:using - Automatic Static Extensions

Automatically applies static extension methods to a type, making them globally available wherever the type is used.

**Basic Usage**:
```haxe
// Define extension methods
class ResultTools {
    public static function isOk<T, E>(result: Result<T, E>): Bool {
        return switch (result) {
            case Ok(_): true;
            case Error(_): false;
        }
    }
    
    public static function map<T, U, E>(result: Result<T, E>, transform: T -> U): Result<U, E> {
        return switch (result) {
            case Ok(value): Ok(transform(value));
            case Error(error): Error(error);
        }
    }
}

// Apply extensions automatically to the type
@:using(haxe.functional.Result.ResultTools)
enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}
```

**Usage Anywhere**:
```haxe
import haxe.functional.Result;

class UserService {
    static function validateUser(data: String): Result<User, String> {
        var result = parseUser(data);
        // Extensions automatically available - no 'using' needed
        if (result.isOk()) {
            return result.map(user -> enrichUser(user));
        }
        return result;
    }
}
```

**Comparison with `using` Keyword**:

| Pattern | Scope | Control | Maintenance |
|---------|-------|---------|-------------|
| **`@:using` metadata** | Global (automatic) | Set once on type | Low maintenance |
| **`using` keyword** | Per-file (explicit) | Manual per file | Higher maintenance |

**Example with `using` keyword**:
```haxe
// Without @:using metadata on Result type
import haxe.functional.Result;
import haxe.functional.ResultTools;
using haxe.functional.ResultTools; // Required in each file

class UserService {
    static function validateUser(data: String): Result<User, String> {
        var result = parseUser(data);
        return result.isOk() ? result.map(enrichUser) : result;
    }
}
```

**When to Use @:using**:
- **Core data types** (Option, Result, List) that always need their extension methods
- **Domain types** where extensions are fundamental to the type's usage
- **Library development** where you want extensions to be automatically available

**When to Use `using` Instead**:
- **Large projects** where explicit imports provide better clarity
- **Selective extension usage** where only some files need the extensions  
- **Testing environments** where you want precise control over available methods

**Real-World Examples**:
```haxe
// Haxe standard library pattern
@:using(haxe.ds.Option.OptionTools)
enum Option<T> {
    Some(value: T);
    None;
}

// Domain validation pattern
@:using(models.Email.EmailTools)
abstract Email(String) from String {
    public function new(value: String) this = value;
}

class EmailTools {
    public static function getDomain(email: Email): String {
        return email.toString().split("@")[1];
    }
    
    public static function isValidDomain(email: Email, domain: String): Bool {
        return email.getDomain().toLowerCase() == domain.toLowerCase();
    }
}
```

### @:repo - Ecto Repository Configuration

Configures an Ecto repository with typed database adapter settings and automatically generates companion modules.

**Purpose**: The `@:repo` annotation provides a type-safe way to configure Ecto repositories. It replaces the need for manual PostgrexTypes modules by automatically generating them based on the repository configuration.

**Basic Usage**:
```haxe
import ecto.DatabaseAdapter;

@:native("TodoApp.Repo")
@:repo({
    adapter: Postgres,
    json: Jason,
    extensions: [],
    poolSize: 10
})
extern class Repo {
    // Repository methods are provided by externs
}
```

**Generated Elixir (Repo module)**:
```elixir
defmodule TodoApp.Repo do
  use Ecto.Repo, otp_app: :todo_app, adapter: Ecto.Adapters.Postgres
end
```

**Generated Elixir (Companion PostgrexTypes module)**:
```elixir
:"Elixir.Postgrex.Types".define(TodoApp.PostgrexTypes, [], [{:json, Jason}])
```

**Configuration Options**:
```haxe
typedef RepoConfig = {
    var adapter: DatabaseAdapter;      // Required: Postgres, MySQL, SQLite3, etc.
    @:optional var json: JsonLibrary;  // Optional: Jason, Poison, None (default: Jason)
    @:optional var extensions: Array<PostgresExtension>; // Optional: PostgreSQL extensions
    @:optional var poolSize: Int;      // Optional: Connection pool size
}
```

**Supported Database Adapters**:
- `Postgres` - PostgreSQL via Ecto.Adapters.Postgres
- `MySQL` - MySQL via Ecto.Adapters.MyXQL
- `SQLite3` - SQLite via Ecto.Adapters.SQLite3
- `SQLServer` - SQL Server via Ecto.Adapters.Tds
- `InMemory` - In-memory adapter for testing

**JSON Libraries**:
- `Jason` - Fast JSON library (recommended)
- `Poison` - Alternative JSON library
- `None` - No JSON support

**PostgreSQL Extensions** (when using Postgres adapter):
- `HStore` - Key-value store
- `PostGIS` - Geographic objects
- `UUID` - UUID data type
- `LTREE` - Hierarchical tree-like data
- `Citext` - Case-insensitive text

**Key Features**:
- **Type-safe configuration**: Compile-time validation of adapter settings
- **Automatic PostgrexTypes generation**: No need for manual PostgrexTypes modules
- **Framework-agnostic**: Works with any Elixir application, not just Phoenix
- **Clean separation**: Repository configuration separate from implementation

**Why @:repo is Important**:
- **Eliminates boilerplate**: No more empty PostgrexTypes classes
- **Type safety**: Configuration errors caught at compile time
- **Convention over configuration**: Sensible defaults for common cases
- **Automatic wiring**: The compiler handles module generation and registration

**Migration from Manual Configuration**:

Before (manual PostgrexTypes):
```haxe
// Repo.hx
@:native("TodoApp.Repo")
extern class Repo {}

// PostgrexTypes.hx (code smell - empty class)
@:native("TodoApp.PostgrexTypes")
@:dbTypes({json: "Jason"})
class PostgrexTypes {}
```

After (typed @:repo):
```haxe
// Repo.hx only - PostgrexTypes generated automatically
@:native("TodoApp.Repo")
@:repo({
    adapter: Postgres,
    json: Jason
})
extern class Repo {}
```

### @:appName - Configurable Application Names

Configures the application name for Phoenix applications, enabling reusable code across different projects.

**Basic Usage**:
```haxe
import elixir.types.Term;

@:application
@:appName("BlogApp")
@:native("BlogApp.Application")
class BlogApp {
    public static function start(type: Term, args: Term): Term {
        var appName = getAppName(); // Returns "BlogApp"
        
        var children = [
            {
                id: '${appName}.Repo',
                start: {module: '${appName}.Repo', "function": "start_link", args: []}
            },
            {
                id: "Phoenix.PubSub",
                start: {
                    module: "Phoenix.PubSub", 
                    "function": "start_link",
                    args: [{name: '${appName}.PubSub'}]
                }
            },
            {
                id: '${appName}Web.Endpoint', 
                start: {module: '${appName}Web.Endpoint', "function": "start_link", args: []}
            }
        ];

        var opts = {strategy: "one_for_one", name: '${appName}.Supervisor'};
        return Supervisor.startLink(children, opts);
    }
}
```

**Generated Elixir**:
```elixir
defmodule BlogApp.Application do
  @moduledoc false
  
  use Application
  
  @impl true
  def start(_type, _args) do
    children = [
      %{id: "BlogApp.Repo", start: %{module: "BlogApp.Repo", function: "start_link", args: []}},
      %{id: "Phoenix.PubSub", start: %{module: "Phoenix.PubSub", function: "start_link", args: [%{name: "BlogApp.PubSub"}]}},
      %{id: "BlogAppWeb.Endpoint", start: %{module: "BlogAppWeb.Endpoint", function: "start_link", args: []}}
    ]
    
    opts = %{strategy: "one_for_one", name: "BlogApp.Supervisor"}
    Supervisor.start_link(children, opts)
  end
end
```

**Key Features**:
- **Dynamic Module Names**: Use `${appName}` string interpolation for configurable module references
- **Framework Compatibility**: Works with any Phoenix application naming convention
- **Compatible with All Annotations**: Can be combined with any other annotation type
- **Reusable Code**: Write once, use in multiple projects with different names
- **No Hardcoding**: Eliminates hardcoded "TodoApp" references in generated code

**Common Patterns**:
- PubSub modules: `'${appName}.PubSub'` → `"BlogApp.PubSub"`
- Web modules: `'${appName}Web.Endpoint'` → `"BlogAppWeb.Endpoint"`  
- Supervisor names: `'${appName}.Supervisor'` → `"BlogApp.Supervisor"`
- Repository modules: `'${appName}.Repo'` → `"BlogApp.Repo"`

**Why @:appName is Important**:
- Phoenix applications require app-specific module names (e.g., "BlogApp.PubSub", "ChatApp.PubSub")
- Without @:appName, all applications would hardcode "TodoApp" references
- Enables creating reusable Phoenix application templates
- Makes project renaming and rebranding straightforward

### @:exunit - ExUnit Test Module

Marks a class as an ExUnit test module for unit and integration testing.

**Purpose**: ExUnit is Elixir's built-in testing framework. The `@:exunit` annotation transforms your class into a proper ExUnit test module with all the testing capabilities.

**Basic Usage**:
```haxe
import exunit.TestCase;
import exunit.Assert.*;

@:exunit
class UserTest extends TestCase {
    @:test
    function testUserCreation(): Void {
        var user = new User("Alice", 30);
        assertEqual("Alice", user.name);
        assertEqual(30, user.age);
    }
    
    @:test
    function testUserValidation(): Void {
        var user = new User("", -5);
        assertFalse(user.isValid());
    }
}
```

**Generated Elixir**:
```elixir
defmodule UserTest do
  use ExUnit.Case
  
  test "user creation" do
    user = User.new("Alice", 30)
    assert user.name == "Alice"
    assert user.age == 30
  end
  
  test "user validation" do
    user = User.new("", -5)
    assert not user.is_valid()
  end
end
```

### ExUnit Test Annotations

These annotations work within `@:exunit` classes to provide full testing capabilities:

#### @:test - Mark Test Method

**Purpose**: Identifies a method as a test case that should be executed by ExUnit.

**How it works**: Test method names are automatically cleaned up:
- `testUserLogin` → `test "user login"`
- `testCreateOrder` → `test "create order"`
- `shouldValidateEmail` → `test "should validate email"`

```haxe
@:test
function testCalculation(): Void {
    assertEqual(4, 2 + 2);
}
```

#### @:describe - Group Related Tests

**Purpose**: Groups related tests together in describe blocks for better organization and readability.

**Why use it**: 
- Improves test output readability
- Allows running specific groups of tests
- Provides logical structure to test suites

```haxe
@:describe("User validation")
@:test
function testEmailFormat(): Void {
    assertTrue(User.isValidEmail("test@example.com"));
    assertFalse(User.isValidEmail("invalid-email"));
}

@:describe("User validation")
@:test
function testAgeRange(): Void {
    assertTrue(User.isValidAge(25));
    assertFalse(User.isValidAge(-1));
}
```

Generates:
```elixir
describe "User validation" do
  test "email format" do
    assert User.is_valid_email("test@example.com")
    assert not User.is_valid_email("invalid-email")
  end
  
  test "age range" do
    assert User.is_valid_age(25)
    assert not User.is_valid_age(-1)
  end
end
```

#### @:async - Run Tests Asynchronously

**Purpose**: Marks tests to run concurrently with other async tests for faster test execution.

**When to use**: For tests that don't share state or resources and can safely run in parallel.

```haxe
@:async
@:test
function testIndependentCalculation(): Void {
    var result = complexCalculation();
    assertNotNull(result);
}
```

**Note**: If any test in a module is marked `@:async`, the entire module becomes async: `use ExUnit.Case, async: true`

#### @:tag - Tag Tests for Selective Execution

**Purpose**: Tags tests for conditional execution, allowing you to include or exclude specific tests.

**Common uses**:
- Skip slow tests in CI: `@:tag("slow")`
- Mark integration tests: `@:tag("integration")`
- Flag external dependencies: `@:tag("external")`
- Multiple tags supported: `@:tag("slow") @:tag("database")`

```haxe
@:tag("slow")
@:test
function testDatabaseMigration(): Void {
    Database.runMigrations();
    assertTrue(Database.isReady());
}

@:tag("integration")
@:tag("external")
@:test
function testThirdPartyAPI(): Void {
    var response = ExternalAPI.fetch();
    assertNotNull(response);
}
```

Run with tags:
```bash
mix test --only slow           # Run only slow tests
mix test --exclude integration # Skip integration tests
mix test --only tag:external   # Run only external tests
```

#### @:setup - Run Before Each Test

**Purpose**: Executes setup code before each test in the module to ensure clean state.

```haxe
@:setup
function prepareDatabase(): Void {
    Database.beginTransaction();
    insertTestData();
}
```

#### @:setupAll - Run Once Before All Tests

**Purpose**: Executes expensive one-time setup before any tests in the module run.

```haxe
@:setupAll
function startServices(): Void {
    TestServer.start();
    Database.createTestDatabase();
}
```

#### @:teardown - Run After Each Test

**Purpose**: Executes cleanup code after each test to prevent test interference.

```haxe
@:teardown
function cleanupDatabase(): Void {
    Database.rollbackTransaction();
    clearTempFiles();
}
```

#### @:teardownAll - Run Once After All Tests

**Purpose**: Executes final cleanup after all tests in the module complete.

```haxe
@:teardownAll
function stopServices(): Void {
    TestServer.stop();
    Database.dropTestDatabase();
}
```

**Complete ExUnit Example**:
```haxe
@:exunit
class TodoTest extends TestCase {
    @:setupAll
    function startApp(): Void {
        TodoApp.start();
    }
    
    @:setup
    function beginTransaction(): Void {
        Database.beginTransaction();
    }
    
    @:describe("Todo CRUD")
    @:test
    function testCreateTodo(): Void {
        var todo = Todo.create("Buy milk");
        assertNotNull(todo.id);
    }
    
    @:describe("Todo CRUD")
    @:async
    @:test
    function testUpdateTodo(): Void {
        var todo = Todo.create("Buy milk");
        todo.update({completed: true});
        assertTrue(todo.completed);
    }
    
    @:tag("slow")
    @:test
    function testBulkImport(): Void {
        var todos = Todo.bulkImport(largeDataset);
        assertEqual(10000, todos.length);
    }
    
    @:teardown
    function rollback(): Void {
        Database.rollbackTransaction();
    }
    
    @:teardownAll
    function stopApp(): Void {
        TodoApp.stop();
    }
}
```

## Additional User-Facing Metadata

The sections above cover the core Phoenix/Ecto/OTP annotations. This section closes the remaining user-facing metadata used across examples and stdlib surfaces, especially tags that are context-sensitive or commonly confused.

### @:component - Class Scope vs Function Scope

`@:component` has two distinct roles:

- **Class-level `@:component`** marks a module as a Phoenix component module.
  - The compiler keeps/emits the module even when direct callsites are not obvious to Haxe DCE.
  - Component-specific template/assigns handling is enabled for this module context.
- **Function-level `@:component`** marks specific static functions as discoverable component entrypoints.
  - These functions participate in dot-component resolution (`<.name ...>`) and typed props/slots validation.

```haxe
@:native("MyAppWeb.CoreComponents")
@:component
class CoreComponents {
  @:component
  public static function button(assigns:ButtonAssigns):String {
    return <button class={@class}>{@inner_content}</button>;
  }
}
```

Why both are needed:

- The class tag answers: "is this a component module?"
- The function tag answers: "which functions are component entrypoints?"

If strict component checks are enabled (`-D hxx_strict_components`), missing/ambiguous function-level component definitions become compile errors.

### @:channel - Phoenix Channel Module

Marks a module as a Phoenix channel callback module and enables channel-oriented transformation behavior.

```haxe
@:native("MyAppWeb.PingChannel")
@:channel
class PingChannel {
  public static function join(topic:String, payload:Term, socket:Term):JoinResult {
    return Ok(socket);
  }
}
```

### @:phoenixWebModule - `AppWeb` Helper Module

Generates the Phoenix Web helper module (for `use AppWeb, :controller | :html | :live_view | ...`).

```haxe
@:native("MyAppWeb")
@:phoenixWebModule
class MyAppWeb {}
```

Use this when you need typed ownership of the app web namespace module itself.

### @:native - Scope Semantics

`@:native` is valid at multiple scopes and meaning changes by scope:

- **Class-level**: pins generated module name.
- **Function-level**: pins emitted function name for explicit interop with an existing Elixir API.

```haxe
@:native("MyAppWeb.UserLive")
@:liveview
class UserLive {
  public static function handleEvent(event:String, params:Term, socket:Socket<UserAssigns>):HandleEventResult<UserAssigns> {
    return NoReply(socket);
  }
}
```

In `@:liveview` modules, exact Haxe-style callback names normalize automatically:
`handleEvent`, `handleInfo`, `handleParams`, and `handleAsync` emit Phoenix's canonical snake_case names.
Prefer `@:native` for compatibility with existing Elixir APIs; avoid using it to mask naming-model bugs in transforms.

### @:module - Module Macro Convenience

Used with the module macro pipeline to reduce boilerplate for utility-style static modules.

```haxe
@:module
class StringUtils {
  public static function slugify(input:String):String {
    return input.toLowerCase();
  }
}
```

### @:build - Compile-Time Macro Hook

Runs a build macro for the annotated type.

Compatibility Phoenix router pattern (legacy helper generation):

```haxe
@:router
@:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())
@:routes([...])
class AppRouter {}
```

For new routers, prefer module-level `final routes = [...]` instead of requiring a build macro.
Use `@:build` only for deterministic codegen/setup tasks.

### @:field / @:primary_key / @:timestamps / @:virtual

Field-level schema shaping metadata:

- `@:field`: include property in schema field emission.
- `@:primary_key`: mark field as PK.
- `@:timestamps`: enable timestamp fields.
- `@:virtual`: non-persisted schema field (e.g., password confirmation).

```haxe
@:schema("users")
class User {
  @:field @:primary_key public var id:Int;
  @:field public var email:String;
  @:virtual @:field public var password:String;
}
```

### Validation Metadata (Changeset)

These tags are usually declared inside a `@:changeset` module/class:

- `@:validate_required([...])`
- `@:validate_format(field, pattern)`
- `@:validate_length(field, opts)`
- `@:validate_number(field, opts)`

They map to standard Ecto validation pipeline calls.

### @:slot - Component Slot Contract

Marks component assigns fields as slot contracts for typed slot validation:

```haxe
typedef CardAssigns = {
  var title:String;
  @:slot @:optional var action:Slot<CardActionAssigns>;
  @:slot var inner_block:Slot<Term, CardLet>;
}
```

### @:hxx_no_inline_markup - Disable Inline Markup Rewrite

Opt out of inline-markup rewrite for a module:

```haxe
@:hxx_no_inline_markup
class LegacyTemplateHelpers {}
```

Use when migrating legacy template strings or when explicit control of rewrite entrypoints is needed.

### @:phxHookNames - Hook Registry for Typed `phx-hook`

Registers compile-time hook names (typically enum abstract constants) used by strict hook validation.

```haxe
@:phxHookNames
enum abstract HookName(String) from String to String {
  var AutoFocus = "AutoFocus";
  var CopyToClipboard = "CopyToClipboard";
}
```

### @:supervisor - OTP Supervisor Module

Marks a module as a supervisor surface so child-spec normalization and supervisor-oriented behavior can be applied.

### @:callback / @:optional_callback

Used inside `@:behaviour` contracts:

- `@:callback`: required callback.
- `@:optional_callback`: optional callback.

### @:use vs @:using

- `@:using(...)` is Haxe metadata for static extension attachment and is documented above.
- `@:use(...)` appears in behavior-oriented examples as a contract/intention marker (for "this module uses this behavior").
  - Treat `@:use` as an example-level convention unless a specific library macro consumes it in your build.

### @:gettext

Marks a module as the Gettext integration surface for the app web namespace.

### @:keep

Haxe DCE retention metadata. Use when declarations are referenced indirectly (framework callbacks, generated route wiring, reflective/macro paths) and might otherwise be removed.

Why this matters in Phoenix/OTP code:

- Phoenix and OTP often resolve callbacks/modules by convention or runtime wiring (`Application.start/2`, `ErrorHTML`, `ErrorJSON`, route/endpoint wiring).
- Those paths are not always visible as direct Haxe callsites, so Haxe DCE can incorrectly prune them without `@:keep`.

Typical pattern:

```haxe
@:native("MyApp.Application")
@:application
class MyApp {
  @:keep
  public static function start(type:ApplicationStartType, args:ApplicationArgs):ApplicationResult {
    // Called by OTP runtime callback dispatch, not by direct Haxe call.
    ...
  }
}
```

### @:from / @:to / @:overload / @:private / @:optional

Frequently-used Haxe metadata in user-facing extern/abstraction layers:

- `@:from`: implicit cast into type/abstract.
- `@:to`: implicit cast from type/abstract.
- `@:overload`: additional typing signatures for one emitted implementation.
- `@:private`: hides helper members from public API surface.
- `@:optional`: optional field/member in typedef/config contracts.

### @:presenceTopic

Optional presence helper metadata to provide a default topic for presence operations and reduce repeated string literals.

Presence topics and keys are still Elixir strings at runtime. Prefer `PresenceTopic.of(...)` and `PresenceKey.of(...)` in Haxe code when the value is an app-owned concept; raw strings remain accepted for dynamic Phoenix interop.

When set on a `@:presence` class implementing `PresenceBehavior`, the macro also generates fixed-topic helpers:

- `trackSimple(key, meta)`
- `updateSimple(key, meta)`
- `untrackSimple(key)`
- `listSimple()`

Prefer explicit topic helpers (`trackWithSocket(socket, topic, key, meta)`, `list(topic)`, `getByKey(topic, key)`) when the topic is dynamic, such as per-room chat or per-tenant resources. In that case, build the topic with `PresenceTopic.of("room:" + roomId)` so the Haxe API still records the value's purpose.

### @:query (Status)

`@:query` appears in examples as a forward-looking marker/commentary for typed query DSL direction.

- **Current status**: reserved/experimental in example narrative.
- Do not rely on `@:query` as a stable codegen contract unless your version explicitly documents implementation support.

### Router Metadata Cross-Reference

Module-level `final routes = [...]`, `@:routes`, and `@:route` are documented in detail in `docs/04-api-reference/ROUTER_DSL.md`.

- Prefer module-level `final routes = [...]` for typed modern router declarations.
- Use `@:routes` for compatibility during migration of existing routers.
- Use `@:route` for manual/backward-compatible route metadata patterns (function-by-function route declarations, often with string controller/action literals).

### Related Reference Pages

- `docs/04-api-reference/ROUTER_DSL.md`
- `docs/04-api-reference/FEATURE_FLAGS.md`
- `docs/04-api-reference/HAXE_MACRO_APIS.md`
- `docs/04-api-reference/API_INDEX.md`

## Usage Guidelines

1. **One primary annotation per class** - Choose the main purpose of your class
2. **Use compatible combinations** - Leverage synergistic annotations together
3. **Avoid conflicts** - The compiler will error on incompatible combinations
4. **Follow conventions** - Use standard Phoenix/Ecto patterns for better integration

For more examples, see the `examples/` directory in the project repository.
