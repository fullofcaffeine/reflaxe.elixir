package server.presence;

import phoenix.PresenceBehavior;

/**
 * Presence module for the Todo app.
 *
 * WHAT
 * - Declares the Presence module used by the app and generates a valid Phoenix.Presence
 *   module via the @:presence transform.
 *
 * WHY
 * - The app expects a concrete `TodoAppWeb.Presence` module in the supervision tree.
 *   Keeping this in Haxe ensures the example app is self-contained and the compiler
 *   output remains the single source of truth.
 *
 * HOW
 * - Marked @:native to generate the runtime module `TodoAppWeb.Presence`.
 * - Marked @:presence so the compiler injects `use Phoenix.Presence, ...`.
 */
typedef PresenceMeta = {
	var onlineAt:Float;
	var userName:String;
	var userEmail:String;
	var avatar:Null<String>;
	var editingTodoId:Null<Int>;
	var editingStartedAt:Null<Float>;
}

// @:presence: emits a Phoenix.Presence module for realtime presence tracking.
// Exact interop escape hatch: PresenceBehavior still needs this app web module
// target until its macro emitter is fully target-name-first.

@:native("TodoAppWeb.Presence")
@:presence
class TodoPresence implements PresenceBehavior {}
