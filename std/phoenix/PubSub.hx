package phoenix;

#if (elixir || reflaxe_runtime)
import elixir.types.Term;

/**
 * API-faithful externs for Phoenix.PubSub.
 *
 * WHAT
 * - Maps directly to Phoenix.PubSub's public functions:
 *   subscribe/2, subscribe/3, broadcast/3, broadcast_from/4, and unsubscribe/2.
 *
 * WHY
 * - App code should call Phoenix.PubSub through typed Haxe externs instead of
 *   raw `__elixir__()` snippets or compatibility shims.
 *
 * HOW
 * - `@:native("Phoenix.PubSub")` pins the Elixir module.
 * - Haxe camelCase helper names use method-level `@:native` only where Elixir
 *   uses snake_case.
 */
@:native("Phoenix.PubSub")
extern class PubSub {
	public static function subscribe(pubsub:PubSubServer, topic:String):Term;

	@:native("subscribe")
	public static function subscribeWithOptions(pubsub:PubSubServer, topic:String, options:PubSubOptions):Term;

	public static function broadcast<TMessage>(pubsub:PubSubServer, topic:String, message:TMessage):Term;

	@:native("broadcast_from")
	public static function broadcastFrom<TMessage>(pubsub:PubSubServer, from:Term, topic:String, message:TMessage):Term;

	public static function unsubscribe(pubsub:PubSubServer, topic:String):Term;
}

/**
 * Phoenix accepts the PubSub server name as a module atom or compatible term.
 */
typedef PubSubServer = Term;

/**
 * Phoenix.PubSub.subscribe/3 expects a keyword list. Until this stdlib grows a
 * first-class Keyword type, keep the boundary precise as an Elixir term instead
 * of pretending an object map is a keyword list.
 */
typedef PubSubOptions = Term;
#end
