# Optimistic Updates in LiveView (Haxe → Elixir)

This pattern shows how to implement fast, user‑friendly “optimistic UI” updates in Phoenix LiveView using Haxe, while keeping code idiomatic and server‑driven.

Goals
- Immediate feedback for checkbox‑style toggles (single‑field, idempotent).
- Server remains the source of truth; PubSub reconciles state.
- No client‑side hacks or JS hooks required.
- App‑agnostic and shape‑based (works for any LiveView using the pattern).

When to use optimistic vs. server‑first
- Optimistic (recommended): single‑field, idempotent changes like a todo “completed” checkbox.
- Server‑first (recommended): create/edit/delete and multi‑field updates — do the write, then update assigns, and broadcast for peers.

Pattern overview
1) Track a small optimistic state in assigns, e.g. `optimistic_toggle_ids: Array<Int>`.
2) On toggle, push the id into the list, recompute view rows so it flips immediately, then persist in the database and broadcast.
3) On PubSub messages (`TodoUpdated`, `TodoDeleted`), update the list with the authoritative record and recompute again (reconciliation).

Haxe (server/live/TodoLive.hx)
```haxe
// Assigns includes a tiny optimistic state
typedef TodoLiveAssigns = {
  var optimistic_toggle_ids: Array<Int>;
  var visible_todos: Array<TodoView>;
  // … other fields …
}

// Immediate UI flip
static function toggleTodoStatus(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
  var s: LiveSocket<TodoLiveAssigns> = socket;
  var ids = s.assigns.optimistic_toggle_ids;
  var contains = ids.indexOf(id) != -1;
  var computed = contains ? ids.filter(x -> x != id) : [id].concat(ids);
  var sOptimistic = s.assign(_.optimistic_toggle_ids, computed);

  // Locally flip the row for instant feedback
  var local = findTodo(id, s.assigns.todos);
  if (local != null) {
    var toggled = local; toggled.completed = !local.completed;
    sOptimistic = updateTodoInList(toggled, sOptimistic);
  }

  // Persist; PubSub broadcast will reconcile authoritative state
  var db = Repo.get(server.schemas.Todo, id);
  if (db != null) switch (Repo.update(server.schemas.Todo.toggleCompleted(db))) {
    case Ok(value): TodoPubSub.broadcast(TodoUpdates, TodoUpdated(value));
    case Error(_):  TodoPubSub.broadcast(TodoUpdates, TodoUpdated(db)); // revert best‑effort
  }
  return recomputeVisible(sOptimistic);
}

// Recompute rows: derive completed_for_view from optimistic ids
static function buildVisibleTodos(a: TodoLiveAssigns): Array<TodoView> {
  var base = filterAndSortTodos(…);
  var optimistic = a.optimistic_toggle_ids != null ? a.optimistic_toggle_ids : [];
  return base.map(todo -> makeViewRow(a, optimistic, todo));
}
```

Generated Elixir (shape)
```elixir
def handle_event("toggle_todo", params, socket) do
  id = … # extracted safely, string→int when needed
  {:noreply, toggle_todo_status(id, socket)}
end

# In toggle_todo_status/2
s_optimistic = Phoenix.Component.assign(socket, :optimistic_toggle_ids, computed_ids)
# flip local row
# persist Repo.update/1, broadcast TodoUpdated, reevaluate via recompute_visible/1
```

Create/edit/delete (server‑first)
- Insert/update/delete with Repo, update assigns, then broadcast (`TodoCreated`, `TodoUpdated`, `TodoDeleted`).
- Peers reconcile via PubSub. This keeps code simple and matches typical LiveView guidance for multi‑field or list‑membership changes.

Why this follows Phoenix best practices
- LiveView is still server‑driven — “optimistic” is only a temporary server‑side assigns tweak.
- Reconciliation happens through PubSub messages; idempotent and deterministic.
- No coupling to app‑specific names; uses shapes (id, value maps) and standard Repo/Assign/PubSub flows.

Testing
- ExUnit (Haxe): LiveViewTest can assert that `data-completed` flips immediately and reconciles after a simulated delay.
- Playwright: Assert the ✓ appears quickly and the card `data-completed` attribute updates.
```
BASE_URL=http://localhost:4001 npx -C examples/todo-app playwright test e2e/smoke/optimistic-toggle.spec.ts
```

Notes
- Keep the optimistic surface minimal (ids only). Avoid storing whole rows as “optimistic” copies.
- Always broadcast after persistence; handle errors by broadcasting the authoritative record to revert.
- For other CRUD, prefer server‑first; add optimistic only when user experience gains outweigh complexity.

