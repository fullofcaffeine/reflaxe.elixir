package shared.liveview;

/**
 * EventName
 *
 * Single source of truth for Phoenix LiveView `phx-*` event names used by the todo-app.
 *
 * WHY
 * - Keep templates and `handle_event/3` logic in sync.
 * - Make event refactors type-safe (rename once, compiler finds all usages).
 *
 * HOW
 * - Templates: `phx-click=${EventName.ToggleForm}` (compiles to `phx-click="toggle_form"`).
 * - Server: compare `event == EventName.ToggleForm`.
 */
@:phxEventNames
enum abstract EventName(String) from String to String {
    var ToggleForm = "toggle_form";
    var CreateTodo = "create_todo";
}

