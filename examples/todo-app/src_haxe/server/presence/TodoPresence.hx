package server.presence;

import phoenix.PresenceBehavior;

/**
 * Extern presence module for the Todo app.
 *
 * WHAT
 * - Declares the presence surface used by the app without generating code.
 *
 * WHY
 * - Generated presence modules were emitting malformed references (e.g., nullWeb).
 *   Treating the module as extern lets a hand-written Elixir module supply the
 *   behavior while keeping typed references for the rest of the app.
 *
 * HOW
 * - Marked @:native to bind to the runtime module `TodoAppWeb.Presence`.
 * - Only the functions the app may call are declared here; others fall back to
 *   the Phoenix.Presence defaults via the runtime module.
 */
typedef PresenceMeta = {
    var onlineAt: Float;
    var userName: String;
    var userEmail: String;
    var avatar: Null<String>;
    var editingTodoId: Null<Int>;
    var editingStartedAt: Null<Float>;
}

@:native("TodoAppWeb.Presence")
extern class TodoPresence implements PresenceBehavior {
}
