package phoenix;

#if (elixir || reflaxe_runtime)

/**
 * PubSubShim
 *
 * WHAT
 * - Lightweight helper to call Phoenix.PubSub without leaking __elixir__ into app code.
 *
 * WHY
 * - Some app modules need direct PubSub calls; printer currently shortens module
 *   names, producing bare `PubSub.broadcast/3` warnings. Inline shim guarantees
 *   fully qualified Phoenix.PubSub calls while keeping app code clean.
 */
@:native("TodoApp.PubSubShim")
class PubSubShim {
    public static inline function subscribe(pubsub: Dynamic, topic: String): Dynamic {
        return untyped __elixir__('Phoenix.PubSub.subscribe({0}, {1})', pubsub, topic);
    }

    public static inline function broadcast(pubsub: Dynamic, topic: String, message: Dynamic): Dynamic {
        return untyped __elixir__('Phoenix.PubSub.broadcast({0}, {1}, {2})', pubsub, topic, message);
    }
}

#end
