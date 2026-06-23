# 📝 Todo App - Full-Stack Haxe with Phoenix LiveView

End-to-end reference app showcasing Reflaxe.Elixir in a real Phoenix LiveView application:

- **Server**: Haxe → Elixir (LiveView + Ecto + PubSub)
- **Client**: Haxe → JavaScript (LiveView hooks + progressive enhancement)
- **E2E tests**: Playwright

## 🌟 Features

### Backend (Haxe → Elixir)
- Todo CRUD + typed LiveView assigns
- Ecto schemas + migrations
- Optional demo login + profile (session-based)
- Optional GitHub OAuth login (env-configured)
- Users directory + status toggle (LiveView)
- Tag filtering + search + sorting
- PubSub broadcasts so multiple sessions update live
- Bulk actions (complete all / delete completed)

Note on “multiple instances”:
- The default Phoenix PubSub in this example broadcasts **within a single Phoenix node**.
- Live updates propagate across multiple **browser sessions** connected to the same server process.
- If you run multiple `mix phx.server` instances, you’ll only get cross-instance sync if you also configure node clustering / distributed PubSub.

### Frontend (Haxe → JavaScript)
- LiveView hooks authored in Haxe (progressive enhancement)
- Keyboard shortcuts + small UX helpers
- Optional offline/connection-state behaviors

The client is intentionally kept “thin”: most logic stays on the server (LiveView), with JS as an enhancement layer.

## 🚀 Quick Start

### Prerequisites
- Elixir 1.14+
- Phoenix 1.7+
- PostgreSQL
- Node.js 16+
- Haxe 4.3+

### Installation

```bash
# From examples/todo-app

# 1) One‑time setup (deps, DB, tools, client build)
mix setup

# 2) Start the app with watchers (after first‐time setup)
mix dev
```

Visit `http://localhost:4000` to see the app.

### Command Guide (Recommended)

- `mix dev` (best default): runs `ecto.create`, `ecto.migrate`, then starts Phoenix with watchers.
- `mix phx.server` (fast restart): starts Phoenix with the same dev watchers, but does not run DB create/migrate.
- `mix assets.build && mix compile` (one-shot build): builds client assets and compiles server code without starting the server/watchers.

### Troubleshooting

#### `ERROR 42703 (undefined_column) column t0.organization_id does not exist`

Your local dev database is missing the latest migrations (org/tenancy adds `organization_id`).

```bash
mix ecto.migrate
# or, if you want a clean slate:
mix ecto.reset
```

Tip: prefer `mix dev` over `mix phx.server` because `mix dev` runs `ecto.create` + `ecto.migrate` first.

#### Haxe port conflicts / slow first compile

- Dev uses `mix haxe.watch` watchers for **both** server (Haxe→Elixir) and client (Haxe→JS) code.
- If you see `Haxe server port 6116 is in use; relocating ...` and builds feel slow, clean up stale servers:
  - `../../scripts/haxe-server-cleanup.sh`
- Inspect status:
  - `mix haxe.status`

### Optional: GitHub OAuth (Login)

Set these env vars (and restart the server) to enable “Continue with GitHub” on `/login`:
```bash
export GITHUB_CLIENT_ID="..."
export GITHUB_CLIENT_SECRET="..."
# Optional (recommended if not on :4000)
export GITHUB_REDIRECT_URI="http://localhost:4000/auth/github/callback"
```

## Where to Look (Code Tour)

- LiveView: `examples/todo-app/src_haxe/server/live/TodoLive.hx`
- Typed assigns/types: `examples/todo-app/src_haxe/server/live/TodoLiveTypes.hx`
- Router/session bridge: `examples/todo-app/src_haxe/TodoAppRouter.hx` + `examples/todo-app/src_haxe/server/infrastructure/TodoAppWeb.hx`
- Ecto schema: `examples/todo-app/src_haxe/server/schemas/Todo.hx`
- Client hooks: `examples/todo-app/src_haxe/client/hooks/`
- Playwright specs: `examples/todo-app/e2e/*.spec.ts`

## Testing Runbook

Full testing policy and test inventory live in:
- `examples/todo-app/AGENTS.md` (`Testing Guide (Canonical)`)

Use this section for quick commands.

### QA Sentinel (non-blocking)

Compile + boot + readiness smoke:
```bash
scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --async --deadline 600 --verbose
```

Smoke browser suite (CI-aligned):
```bash
scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4001 --playwright --e2e-spec "e2e/smoke/*.spec.ts" --async --deadline 900 --verbose
```

Full browser suite:
```bash
scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4001 --playwright --e2e-spec "e2e/*.spec.ts" --async --deadline 900 --verbose
```

One-shot app-local smoke helper (`:4000`):
```bash
scripts/qa-sentinel-local.sh
```

### ExUnit (Haxe-authored tests)

Compile Haxe tests to `test/generated`:
```bash
scripts/with-timeout.sh --secs 180 --cwd examples/todo-app -- haxe build-tests.hxml
```

Run ExUnit:
```bash
scripts/with-timeout.sh --secs 420 --cwd examples/todo-app -- mix test
```

### Visual Regression (targeted)

Run visual spec only:
```bash
scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4001 --playwright --e2e-spec e2e/ui_visual.spec.ts --async --deadline 600 --verbose
```

Update visual baselines intentionally:
```bash
scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4001 --keep-alive --async --deadline 600 --verbose
scripts/with-timeout.sh --secs 240 --cwd examples/todo-app -- env BASE_URL=http://localhost:4001 npx playwright test e2e/ui_visual.spec.ts --update-snapshots
```

## 🏗️ Architecture

### Project Structure
```
todo-app/
├── src_haxe/              # Haxe source code
│   ├── schemas/           # Ecto schemas (Todo, User)
│   ├── live/              # LiveView components
│   ├── templates/         # HEEx templates (.hxx)
│   ├── contexts/          # Business logic
│   ├── services/          # Background services
│   └── client/            # Client-side JavaScript
├── lib/                   # Generated Elixir code
├── priv/static/assets/    # Bundled JS/CSS (esbuild output)
├── build-server.hxml      # Canonical server (Haxe→Elixir) build
├── build.hxml             # Thin alias to build-server.hxml (compat)
└── build-client.hxml      # Client (Haxe→JS) build (used by assets alias)
```

Build note:
- Server source of truth is `build-server.hxml`; `build.hxml` is a thin compatibility alias (`--next build-server.hxml`).
- The other canonical entrypoints are `build-client.hxml` (client) and `build-tests.hxml` (tests).
- Legacy multi-pass/prewarm build experiments are kept in git history and are not required for normal development.

### Is the todo-app “100% Haxe”?

The todo-app is designed to demonstrate **end-to-end Haxe→Elixir** for application code, while still being a *normal* Phoenix project.

**Generated from Haxe**
- Server app code: `examples/todo-app/src_haxe/server/**` → `examples/todo-app/lib/todo_app/**` and `examples/todo-app/lib/todo_app_web/**`
- Shared/domain types: `examples/todo-app/src_haxe/shared/**` → `examples/todo-app/lib/shared/**`
- Client hooks: `examples/todo-app/src_haxe/client/**` → bundled JS under `priv/static/assets/` via `build-client.hxml`

Shared code note:
- `src_haxe/shared/` is the place to put typed client/server boundary contracts (payload typedefs, event names,
  and channel protocols). See `examples/todo-app/src_haxe/shared/README.md`.

**Hand-written (Elixir/Phoenix conventions)**
- Phoenix project scaffolding and configuration: `mix.exs`, `config/*.exs`
  - Why: Phoenix expects these files and patterns; keeping them idiomatic makes gradual adoption easy.
- Ecto seeds: `priv/repo/seeds.exs`
  - Why: Ecto executes seeds as Elixir scripts; keeping them Elixir-first is fine for an example app.
- Phoenix JS bootstrap: `assets/js/phoenix_app.js`
  - Why: this mirrors Phoenix’s canonical LiveView bootstrap and stays stable across Phoenix upgrades.
  - Default in this repo: the Haxe client also bootstraps LiveSocket (typed Genes) so more of the client boot is type-checked; the JS file keeps a guard to avoid double connections.

**Haxe-authored migrations (compiled to `.exs`)**
- Haxe sources: `examples/todo-app/src_haxe/server/migrations/*.hx`
- Runtime artifacts: `examples/todo-app/priv/repo/migrations/*.exs` (generated via `build-migrations.hxml` / `mix haxe.compile.migrations`)
- Why: Ecto requires `.exs` files under `priv/repo/migrations/`, but the migration logic can still be authored in Haxe.

**Intentional small Elixir helper**
- `examples/todo-app/lib/todo_app/flash.ex`
  - Why: it’s a tiny, stable helper module and also demonstrates that you can mix Haxe-generated modules with hand-written Elixir where it makes sense.
  - If you want a “pure Haxe” demo, this module can be moved into `src_haxe/` later (without changing the overall architecture).

### Compilation Flow

```mermaid
graph LR
    A[Haxe Source] --> B[Reflaxe.Elixir]
    A --> C[Genes JS Generator]
    B --> D[Elixir/Phoenix Backend]
    C --> E[JavaScript Frontend]
    D --> F[LiveView + Ecto]
    E --> G[Enhanced UX]
    F <--> G
```

## 💻 Development Workflow

### Phoenix JS Bootstrap (phoenix_app.js)
- Entry point: `assets/js/phoenix_app.js` (hand‑written JS, bundled by esbuild).
- Responsibilities:
  - Import `phoenix_html`, `phoenix`, and `phoenix_live_view`.
  - Read CSRF meta from the HTML `<meta name="csrf-token" ...>`.
  - Pick up LiveView Hooks from `window.Hooks` (populated by the Haxe bundle).
  - Create and connect `LiveSocket` (unless already bootstrapped by Haxe), and expose `window.liveSocket`.
- Haxe integration:
  - The Haxe client compiles via Genes to `assets/js/_hx_app_tmp.js` (intermediate entry) plus supporting modules under `assets/js/client/**` and `assets/js/genes/**` (`build-client.hxml`).
  - In dev, the Haxe watcher promotes `assets/js/_hx_app_tmp.js` to the stable `assets/js/hx_app.js` path atomically (see `config/dev.exs`) so esbuild `--watch` never sees an imported module disappear. `assets/js/app.js` imports `./hx_app.js`, and `phoenix_app.js` imports `./app.js`, so Hooks exported by Haxe are available to LiveView.
- Why JS here and not Haxe?
  - This file mirrors Phoenix’s canonical bootstrap and stays stable across Phoenix upgrades.
  - All meaningful client behavior (Hooks, utils, shared types) remains in Haxe for type safety.
  - Default in this repo: the client build enables `-D todoapp_hx_live_socket_bootstrap`, so the Haxe bundle can connect LiveSocket and `phoenix_app.js` will detect `window.liveSocket` and skip.

### Watch Mode
```bash
# Recommended: single terminal with Phoenix watchers (server+client)
mix dev

# Optional (manual split):
# Terminal 1 (Phoenix with assets watchers)
mix phx.server
# Terminal 2 (manual client build)
npm --prefix assets run watch:haxe
```

Note
- In this app, both `mix dev` and `mix phx.server` run Endpoint watchers from `config/dev.exs`
  (esbuild, tailwind, Haxe server watcher, Haxe client watcher).
- The Haxe client watcher is launched via npm (`npm --prefix assets run watch:haxe`).
- If npm is not available on PATH, Phoenix starts without the Haxe watcher; you can still build once with `mix assets.build`.

### CSRF meta tag
- The layout emits a standard Phoenix CSRF meta tag using Plug:
  - `examples/todo-app/lib/todo_app_web/layouts.ex` includes
    `<meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()}/>`
- LiveSocket reads this token in `client.Boot` (default) or `phoenix_app.js` (fallback) and passes it as `_csrf_token`.
```

### Testing
```bash
# Run all tests
mix test

# Test Haxe compilation
haxe test.hxml

# Test JavaScript output
npm test
```

## 🎯 Key Code Examples

### Ecto Schema with Validation (Haxe)
```haxe
import ecto.Changeset;
import elixir.DateTime.NaiveDateTime;
import elixir.types.Term;

typedef TodoChangesetParams = {
    ?title: String,
    ?completed: Bool,
    ?priority: String,
    ?dueDate: Null<NaiveDateTime>,
    // polymorphic: can be a list or a comma-separated string from forms
    ?tags: Term
}

@:native("TodoApp.Todo")
@:schema("todos")
@:timestamps
@:changeset(["title", "completed", "priority", "dueDate", "tags"], ["title"])
class Todo {
    @:field @:primary_key public var id: Int;
    @:field public var title: String;
    @:field public var completed: Bool = false;
    @:field public var priority: String = "medium";
    @:field public var dueDate: Null<NaiveDateTime>;
    @:field public var tags: Null<Array<String>>;
}
```

`@:schema` auto-injects a typed `changeset<Params>(schema, params)` declaration, so no manual
`extern` method is required.

Generated Elixir shape:

```elixir
defmodule TodoApp.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todos" do
    field :title, :string
    field :completed, :boolean, default: false
    field :priority, :string, default: "medium"
    field :due_date, :naive_datetime
    field :tags, {:array, :string}
    timestamps()
  end

  def changeset(todo, params) do
    todo
    |> cast(params, [:title, :completed, :priority, :due_date, :tags])
    |> validate_required([:title])
  end
end
```

### LiveView Component (Haxe)
```haxe
@:liveview
class TodoLive {
    // Full implementation: examples/todo-app/src_haxe/server/live/TodoLive.hx
    // Demonstrates typed assigns, typed event params, PubSub broadcasts, and handle_info updates.

    public static function render(assigns: TodoAssigns): String {
        return <section>
            <h1>${assigns.page_title}</h1>
            <span data-testid="online-count">${assigns.online_user_count}</span>
        </section>;
    }
}
```

Generated Elixir shape:

```elixir
def render(assigns) do
  ~H"""
  <section>
    <h1><%= @page_title %></h1>
    <span data-testid="online-count"><%= @online_user_count %></span>
  </section>
  """
end
```

### Client-Side Enhancement (Haxe → JavaScript)
```haxe
class TodoApp {
    static function setupKeyboardShortcuts() {
        Browser.document.addEventListener("keydown", function(e) {
            if ((e.ctrlKey || e.metaKey) && e.key == "n") {
                e.preventDefault();
                pushEvent("toggle_form", {});
            }
        });
    }
}
```

## 🔥 LiveView Real-Time Features

### Multi-User Sync
All users see updates in real-time:
- ✅ Todo creation/updates/deletion
- ✅ Status changes (complete/incomplete)
- ✅ Priority updates
- ✅ Bulk operations

### PubSub Events
```elixir
# Broadcast from any user
Phoenix.PubSub.broadcast("todo:updates", %{
  type: "todo_created",
  todo: new_todo
})

# All connected users receive update
def handle_info(%{type: "todo_created", todo: todo}, socket) do
  {:noreply, add_todo_to_list(todo, socket)}
end
```

## 🎨 UI Features

### Keyboard Shortcuts
- `Cmd/Ctrl + N` - New todo
- `Cmd/Ctrl + F` - Focus search
- `Alt + 1/2/3` - Filter (All/Active/Completed)
- `Escape` - Close forms/cancel edit
- `Cmd/Ctrl + Enter` - Quick add todo

### Drag & Drop
- Reorder todos by dragging
- Drop text files to import todos
- Drop images to attach to todos

### Offline Support
- Caches todos in localStorage
- Queues actions when offline
- Syncs automatically when reconnected
- Shows offline indicator

## 📊 Performance

### Compilation Times
- Haxe → Elixir: ~200ms
- Haxe → JavaScript: ~150ms
- Total build: <400ms

### Runtime Performance
- LiveView updates: <50ms
- PubSub broadcast: <10ms
- Offline sync: <100ms
- Drag & drop: 60fps

## 🧪 Testing Strategy

### Backend Tests (Elixir)
```elixir
test "toggles todo completion status" do
  todo = insert(:todo, completed: false)
  
  {:ok, updated} = Todos.toggle_completed(todo)
  
  assert updated.completed == true
end
```

### Frontend Tests (JavaScript)
```javascript
describe("TodoApp", () => {
  it("handles keyboard shortcuts", () => {
    const event = new KeyboardEvent("keydown", {
      key: "n",
      ctrlKey: true
    });
    
    document.dispatchEvent(event);
    
    expect(formVisible()).toBe(true);
  });
});
```

## 🚢 Deployment

### Production Build
```bash
# Compile server and bundle client assets
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix compile

# Build release
MIX_ENV=prod mix release

# Deploy
_build/prod/rel/todo_app/bin/todo_app start
```

### Docker
```dockerfile
FROM elixir:1.14-alpine
WORKDIR /app
COPY . .
RUN mix deps.get && \
    MIX_ENV=prod mix assets.deploy && \
    MIX_ENV=prod mix compile && \
    MIX_ENV=prod mix release
CMD ["_build/prod/rel/todo_app/bin/todo_app", "start"]
```

## 📚 Learning Resources

### Reflaxe.Elixir Documentation
- [Quickstart](../../docs/06-guides/QUICKSTART.md)
- [LiveView Guide](../../docs/02-user-guide/PHOENIX_LIVEVIEW_ARCHITECTURE.md)
- [Ecto Integration](../../docs/07-patterns/ECTO_INTEGRATION_PATTERNS.md)

### Key Concepts Demonstrated
1. **Dual Compilation**: Same language (Haxe) for both backend and frontend
2. **Type Safety**: Compile-time validation across the full stack
3. **Real-Time**: LiveView + PubSub for instant updates
4. **Progressive Enhancement**: Works without JS, enhanced with it
5. **Offline First**: Local storage and sync capabilities

## 🤝 Contributing

This example is part of Reflaxe.Elixir v1.1.x. Contributions welcome!

1. Fork the repository
2. Create your feature branch
3. Add tests for new functionality
4. Submit a pull request

## 📝 License

GPL-3.0 - See LICENSE file in project root

---

**Built with Reflaxe.Elixir v1.1.x** - Write once in Haxe, run everywhere! 🚀

## Template Mode

- Server HXX uses strict TSX inline markup by compiler default.
- Server templates in `src_haxe/server/` use inline markup authoring (no legacy `hxx('...')` wrappers).
