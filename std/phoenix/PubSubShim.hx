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
 *
 * - LiveView processes commonly both (1) update local assigns and (2) broadcast the
 *   authoritative result to other subscribers. Using `broadcast_from/4` avoids the
 *   sender receiving its own message and double-applying updates.
 */
@:native("Phoenix.PubSubShim")
class PubSubShim {
    public static inline function subscribe(pubsub: Dynamic, topic: String): Dynamic {
        return untyped __elixir__('Phoenix.PubSub.subscribe({0}, {1})', pubsub, topic);
    }

    public static inline function broadcast(pubsub: Dynamic, topic: String, message: Dynamic): Dynamic {
        return untyped __elixir__('Phoenix.PubSub.broadcast_from({0}, self(), {1}, {2})', pubsub, topic, message);
    }
}

#end
