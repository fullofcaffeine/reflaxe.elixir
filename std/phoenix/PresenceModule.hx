package phoenix;

import phoenix.Phoenix.Socket;

/**
 * Base class for Phoenix Presence modules
 * 
 * WHY: When a module uses Phoenix.Presence, it gets injected functions
 * that have different calling conventions than the static extern functions.
 * Specifically, track/update need self() as the first argument.
 * 
 * WHAT: Provides proper abstractions for Presence modules so users
 * don't need to use __elixir__() escape hatches.
 * 
 * HOW: Uses extern inline functions with __elixir__() to generate
 * the correct calls for modules that use Phoenix.Presence.
 * 
 * Usage:
 * ```haxe
 * @:presence
 * class MyPresence extends PresenceModule {
 *     public static function trackUser(socket, user) {
 *         return trackPresence(socket, "users", user.id, metadata);
 *     }
 * }
 * ```
 */
class PresenceModule {
    /**
     * Track a presence in this module
     * Generates: track(self(), socket, topic, key, meta)
     * 
     * @param socket The LiveView or Channel socket
     * @param topic The presence topic (e.g., "users")
     * @param key The unique key for this presence
     * @param meta The metadata to associate with the presence
     */
    protected static extern inline function trackPresence<T>(socket: Socket<T>, topic: String, key: String, meta: Dynamic): Socket<T> {
        return untyped __elixir__('track(self(), {0}, {1}, {2}, {3})', socket, topic, key, meta);
    }
    
    /**
     * Update a presence in this module
     * Generates: update(self(), socket, topic, key, meta)
     * 
     * @param socket The LiveView or Channel socket
     * @param topic The presence topic
     * @param key The unique key for this presence
     * @param meta The updated metadata
     */
    protected static extern inline function updatePresence<T>(socket: Socket<T>, topic: String, key: String, meta: Dynamic): Socket<T> {
        return untyped __elixir__('update(self(), {0}, {1}, {2}, {3})', socket, topic, key, meta);
    }
    
    /**
     * List presences for a topic in this module
     * Generates: list(topic)
     * 
     * @param topic The presence topic to list
     * @return Map of presence keys to their metadata
     */
    protected static extern inline function listPresences(topic: String): Dynamic {
        return untyped __elixir__('list({0})', topic);
    }
    
    /**
     * Untrack a presence in this module
     * Generates: untrack(self(), socket, topic, key)
     * 
     * @param socket The LiveView or Channel socket
     * @param topic The presence topic
     * @param key The unique key to untrack
     */
    protected static extern inline function untrackPresence<T>(socket: Socket<T>, topic: String, key: String): Socket<T> {
        return untyped __elixir__('untrack(self(), {0}, {1}, {2})', socket, topic, key);
    }
}