package phoenix;

/**
 * Phoenix.Presence extern definitions for real-time presence tracking
 * 
 * Presence provides a distributed way to track which users are currently 
 * online in your Phoenix application across multiple servers.
 * 
 * @see https://hexdocs.pm/phoenix/Phoenix.Presence.html
 */

/**
 * Presence metadata - can contain any data about the tracked entity
 */
typedef PresenceMeta = Dynamic;

/**
 * Presence key - typically user ID or other unique identifier
 */
typedef PresenceKey = String;

/**
 * Topic identifier for presence tracking
 */
typedef Topic = String;

/**
 * Presence entry containing accumulated metadata for a key
 */
typedef PresenceEntry = {
    var metas: Array<PresenceMeta>;
};

/**
 * Presence list containing all presences for a topic
 * Map of PresenceKey -> PresenceEntry
 */
typedef PresenceList = Dynamic;

/**
 * Phoenix.Presence functions for tracking user presence
 */
@:native("Phoenix.Presence")
extern class Presence {
    /**
     * Track a channel's process with metadata
     * Returns {:ok, ref} or {:error, reason}
     * 
     * @param socket Channel socket
     * @param key Unique identifier for the presence (e.g., user ID)
     * @param meta Metadata to associate with the presence
     */
    @:native("Phoenix.Presence.track")
    public static function track(socket: Dynamic, key: PresenceKey, meta: PresenceMeta): Dynamic;
    
    /**
     * Track an arbitrary process with metadata
     * Returns {:ok, ref} or {:error, reason}
     * 
     * @param pid Process to track
     * @param topic Topic to track in
     * @param key Unique identifier for the presence
     * @param meta Metadata to associate with the presence
     */
    @:native("Phoenix.Presence.track")
    public static function trackPid(pid: Dynamic, topic: Topic, key: PresenceKey, meta: PresenceMeta): Dynamic;
    
    /**
     * Stop tracking a channel's process
     * Returns :ok
     * 
     * @param socket Channel socket
     * @param key Presence key to untrack
     */
    @:native("Phoenix.Presence.untrack")
    public static function untrack(socket: Dynamic, key: PresenceKey): Dynamic;
    
    /**
     * Stop tracking an arbitrary process
     * Returns :ok
     * 
     * @param pid Process to untrack
     * @param topic Topic to untrack from
     * @param key Presence key to untrack
     */
    @:native("Phoenix.Presence.untrack")
    public static function untrackPid(pid: Dynamic, topic: Topic, key: PresenceKey): Dynamic;
    
    /**
     * Get all presences for a socket or topic
     * Returns a map of presence_key => %{metas: [meta, ...]}
     * 
     * @param socketOrTopic Channel socket or topic string
     */
    @:native("Phoenix.Presence.list")
    public static function list(socketOrTopic: Dynamic): PresenceList;
    
    /**
     * Update presence metadata for a channel's process
     * Returns {:ok, ref} or {:error, reason}
     * 
     * @param socket Channel socket
     * @param key Presence key to update
     * @param meta New metadata (can be a map or update function)
     */
    @:native("Phoenix.Presence.update")
    public static function update(socket: Dynamic, key: PresenceKey, meta: PresenceMeta): Dynamic;
    
    /**
     * Update presence metadata for an arbitrary process
     * Returns {:ok, ref} or {:error, reason}
     * 
     * @param pid Process to update
     * @param topic Topic to update in
     * @param key Presence key to update
     * @param meta New metadata (can be a map or update function)
     */
    @:native("Phoenix.Presence.update")
    public static function updatePid(pid: Dynamic, topic: Topic, key: PresenceKey, meta: PresenceMeta): Dynamic;
    
    /**
     * Get presence entries for a specific key
     * Returns list of presence entries for the key
     * 
     * @param socketOrTopic Channel socket or topic string
     * @param key Presence key to get
     */
    @:native("Phoenix.Presence.get_by_key")
    public static function getByKey(socketOrTopic: Dynamic, key: PresenceKey): Array<PresenceEntry>;
}

/**
 * Helper functions for working with presence data
 * Note: These are utility functions you can implement in your application
 */
class PresenceHelpers {
    /**
     * Simple list all unique presence keys for a topic
     * Utility function to get just the keys without metadata
     */
    public static function simpleList(presences: PresenceList): Array<PresenceKey> {
        var keys = [];
        // Implementation: extract keys from presence map
        // for (key in Reflect.fields(presences)) keys.push(key);
        return keys;
    }
    
    /**
     * Check if a key is present in the presence list
     */
    public static function isPresent(presences: PresenceList, key: PresenceKey): Bool {
        // Implementation: check if key exists in presences
        // return Reflect.hasField(presences, key);
        return false;
    }
    
    /**
     * Count total number of presences
     */
    public static function count(presences: PresenceList): Int {
        // Implementation: count keys in presence map
        // return Reflect.fields(presences).length;
        return 0;
    }
}