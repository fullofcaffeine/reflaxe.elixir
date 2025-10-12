package phoenix;

/**
 * Phoenix.Presence extern definitions for real-time presence tracking
 * 
 * ## Overview
 * 
 * Phoenix.Presence provides a distributed, real-time presence tracking system that works
 * across multiple nodes in your Phoenix application. It's built on top of Phoenix PubSub
 * and uses a CRDT (Conflict-free Replicated Data Type) for eventual consistency.
 * 
 * ## How Phoenix.Presence Works
 * 
 * Phoenix.Presence uses a special behavior that injects functions into your module when
 * you call `use Phoenix.Presence`. This is why the function signatures differ depending
 * on whether you're calling from inside or outside a Presence module.
 * 
 * ### Inside a Presence Module (with `use Phoenix.Presence`)
 * 
 * When you define a module with `use Phoenix.Presence`, Phoenix injects local functions
 * that require `self()` as the first argument:
 * 
 * ```elixir
 * defmodule MyAppWeb.Presence do
 *   use Phoenix.Presence, otp_app: :my_app
 *   
 *   def track_user(socket, user_id, meta) do
 *     # Inside the module, track() is a local injected function
 *     # It needs self() as first argument to identify the tracker process
 *     track(self(), socket, "users", user_id, meta)
 *   end
 * end
 * ```
 * 
 * ### Outside a Presence Module
 * 
 * When calling from outside (e.g., from a LiveView or Channel), you use the module name:
 * 
 * ```elixir
 * defmodule MyAppWeb.UserLive do
 *   alias MyAppWeb.Presence
 *   
 *   def mount(_params, _session, socket) do
 *     # From outside, we call through the module
 *     # The module name replaces self()
 *     Presence.track(socket, "users", user_id, %{online_at: now()})
 *   end
 * end
 * ```
 * 
 * ## The self() Function
 * 
 * `self()` is an Erlang/Elixir built-in function that returns the PID (Process ID) of
 * the current process. In Phoenix.Presence:
 * 
 * - It identifies which tracker process is handling the presence
 * - It's required for the internal CRDT synchronization
 * - It ensures presence updates are properly distributed
 * 
 * ## Using from Haxe
 * 
 * In Haxe, when you create a Presence module with `@:presence` annotation:
 * 
 * ```haxe
 * @:presence
 * class TodoPresence {
 *     // The compiler should generate local function calls with self()
 *     public static function trackUser(socket: Socket, user: User) {
 *         // This should compile to: track(self(), socket, "users", ...)
 *         // NOT: Phoenix.Presence.track(socket, "users", ...)
 *         return Presence.track(socket, "users", user.id, meta);
 *     }
 * }
 * ```
 * 
 * ## Common Patterns
 * 
 * 1. **Single Presence per User**: Track each user once with updateable metadata
 * 2. **Topic Organization**: Use consistent topics like "users", "rooms:123"
 * 3. **Metadata Updates**: Use update() to change metadata without track/untrack
 * 4. **Graceful Cleanup**: Presence automatically cleans up when processes die
 * 
 * @see https://hexdocs.pm/phoenix/Phoenix.Presence.html
 * @see https://hexdocs.pm/phoenix/presence.html#the-presence-generator
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
 * 
 * ## What is TMeta?
 * 
 * TMeta is a generic type parameter that represents the type of metadata attached to each presence.
 * It allows you to use type-safe custom metadata structures instead of Dynamic.
 * 
 * ## Why Generic?
 * 
 * Phoenix.Presence can track any kind of metadata about presences. By making PresenceEntry
 * generic with TMeta, we enable compile-time type safety for your application's specific
 * metadata structure.
 * 
 * ## Examples
 * 
 * ```haxe
 * // Define your custom metadata type
 * typedef UserMeta = {
 *     var onlineAt: Float;
 *     var userName: String;
 *     var status: String;
 * }
 * 
 * // Use it with PresenceEntry
 * var userPresence: PresenceEntry<UserMeta> = Presence.getByKey(socket, "user_123");
 * 
 * // Access metadata with full type safety
 * for (meta in userPresence.metas) {
 *     trace(meta.userName);  // Type-safe access to userName
 *     trace(meta.status);    // Type-safe access to status
 * }
 * ```
 * 
 * ## Common Patterns
 * 
 * 1. **Simple metadata**: Just tracking when user came online
 *    ```haxe
 *    typedef SimpleMeta = { onlineAt: Float }
 *    ```
 * 
 * 2. **Rich metadata**: Tracking user state and activity
 *    ```haxe
 *    typedef RichMeta = {
 *        onlineAt: Float,
 *        userName: String,
 *        avatar: String,
 *        currentPage: String,
 *        editingItemId: Null<Int>
 *    }
 *    ```
 * 
 * 3. **Using Dynamic**: When you don't need type safety
 *    ```haxe
 *    var presence: PresenceEntry<Dynamic> = Presence.getByKey(socket, key);
 *    ```
 * 
 * @param TMeta The type of metadata attached to each presence. Can be any type including
 *              Dynamic for untyped metadata, or a custom typedef/class for type-safe access.
 */
typedef PresenceEntry<TMeta> = {
    var metas: Array<TMeta>;
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
     * Track a channel's process with metadata (3-argument version for channels)
     * 
     * **IMPORTANT**: This overload is for calling from OUTSIDE a Presence module.
     * When calling from INSIDE a module with `use Phoenix.Presence`, the injected
     * function requires `self()` as the first argument.
     * 
     * ## Usage from Outside (LiveView/Channel)
     * ```haxe
     * // In a LiveView mount function
     * MyPresence.track(socket, user_id, %{online_at: now()});
     * ```
     * 
     * ## Internal Behavior
     * When you track a presence:
     * 1. The process is monitored for crashes
     * 2. Metadata is stored in the distributed CRDT
     * 3. All subscribers to the topic receive presence_diff events
     * 4. If the process dies, presence is automatically removed
     * 
     * ## Returns
     * - `{:ok, ref}` - Successfully tracked with a unique reference
     * - `{:error, reason}` - Failed to track (e.g., already tracked)
     * 
     * @param socket Channel socket to track (contains the PID and topic)
     * @param key Unique identifier for the presence (e.g., user ID as string)
     * @param meta Metadata map to associate with the presence (e.g., user info)
     * @return Dynamic Either {:ok, ref} or {:error, reason}
     */
    @:native("track")
    public static function track(socket: Dynamic, key: PresenceKey, meta: PresenceMeta): Dynamic;
    
    /**
     * Track an arbitrary process with metadata (4-argument version with explicit topic)
     * 
     * This version allows you to track any process (not just channels) by providing
     * an explicit PID and topic. Useful for tracking background processes, GenServers,
     * or any other Elixir process.
     * 
     * ## Example Use Cases
     * - Track a background job processor
     * - Track a GenServer handling user sessions
     * - Track processes across different topics
     * 
     * ## Usage
     * ```haxe
     * // Track a GenServer process
     * var pid = MyGenServer.whereis("worker_1");
     * Presence.trackPid(pid, "workers", "worker_1", %{started_at: now()});
     * ```
     * 
     * ## Self() Requirement
     * When called from inside a Presence module, this becomes:
     * ```elixir
     * track(self(), pid, topic, key, meta)
     * ```
     * 
     * @param pid Process ID to track (any Elixir process)
     * @param topic Topic string to track in (e.g., "users", "rooms:123")
     * @param key Unique identifier for the presence within the topic
     * @param meta Metadata map to associate with the presence
     * @return Dynamic Either {:ok, ref} or {:error, reason}
     */
    @:native("track")
    public static function trackPid(pid: Dynamic, topic: Topic, key: PresenceKey, meta: PresenceMeta): Dynamic;
    
    /**
     * Stop tracking a channel's process
     * Returns :ok
     * 
     * @param socket Channel socket
     * @param key Presence key to untrack
     */
    @:native("untrack")
    public static function untrack(socket: Dynamic, key: PresenceKey): Dynamic;
    
    /**
     * Stop tracking an arbitrary process
     * Returns :ok
     * 
     * @param pid Process to untrack
     * @param topic Topic to untrack from
     * @param key Presence key to untrack
     */
    @:native("untrack")
    public static function untrackPid(pid: Dynamic, topic: Topic, key: PresenceKey): Dynamic;
    
    /**
     * Get all presences for a socket or topic
     * 
     * Returns all presences for a given topic as a map. Each presence can have
     * multiple metadata entries if tracked from multiple processes.
     * 
     * ## Return Structure
     * ```elixir
     * %{
     *   "user_1" => %{
     *     metas: [
     *       %{online_at: 1234567890, status: "active", phx_ref: "abc123"},
     *       %{online_at: 1234567891, status: "idle", phx_ref: "def456"}
     *     ]
     *   },
     *   "user_2" => %{
     *     metas: [%{online_at: 1234567892, status: "active", phx_ref: "ghi789"}]
     *   }
     * }
     * ```
     * 
     * ## Multiple Metadata Entries
     * A single key can have multiple metadata entries if:
     * - The same user is connected from multiple devices
     * - Multiple processes are tracking the same entity
     * - You're using presence for resource locking (multiple locks)
     * 
     * ## Usage Examples
     * ```haxe
     * // Get all online users
     * var presences = Presence.list(socket);
     * 
     * // Count online users
     * var userCount = Reflect.fields(presences).length;
     * 
     * // Get specific user's metadata
     * if (Reflect.hasField(presences, user_id)) {
     *     var userMetas = Reflect.field(presences, user_id).metas;
     *     // Process all metadata entries for this user
     * }
     * ```
     * 
     * ## Performance Note
     * This returns ALL presences for the topic. For large topics, consider
     * pagination or filtering on the client side.
     * 
     * @param socketOrTopic Either a channel socket or a topic string
     * @return PresenceList Map of presence_key to metadata entries
     */
    @:native("list")
    public static function list(socketOrTopic: Dynamic): PresenceList;
    
    /**
     * Update presence metadata for a channel's process
     * 
     * Updates the metadata for an existing presence without untracking/retracking.
     * This is more efficient than track/untrack cycles and maintains the presence
     * reference.
     * 
     * ## When to Use Update vs Track/Untrack
     * - **Use update()**: When changing user status, activity, or other metadata
     * - **Use track/untrack**: When user actually joins/leaves
     * 
     * ## Example: User Status Updates
     * ```haxe
     * // User starts editing
     * Presence.update(socket, user_id, %{
     *     status: "editing",
     *     editing_todo_id: todo_id,
     *     editing_started_at: now()
     * });
     * 
     * // User goes idle
     * Presence.update(socket, user_id, %{
     *     status: "idle",
     *     idle_since: now()
     * });
     * ```
     * 
     * ## Metadata Parameter
     * Can be either:
     * - A new metadata map (replaces existing)
     * - An update function: `(old_meta) -> new_meta`
     * 
     * ## Self() Requirement
     * Inside a Presence module: `update(self(), socket, topic, key, meta)`
     * 
     * @param socket Channel socket containing the process and topic
     * @param key Presence key to update (must already be tracked)
     * @param meta New metadata map or update function
     * @return Dynamic Either {:ok, ref} or {:error, :not_tracked}
     */
    @:native("update")
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
    @:native("update")
    public static function updatePid(pid: Dynamic, topic: Topic, key: PresenceKey, meta: PresenceMeta): Dynamic;
    
    /**
     * Get presence entries for a specific key
     * Returns list of presence entries for the key
     * 
     * @param socketOrTopic Channel socket or topic string
     * @param key Presence key to get
     */
    @:native("get_by_key")
    public static function getByKey<TMeta>(socketOrTopic: Dynamic, key: PresenceKey): Array<PresenceEntry<TMeta>>;
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
        // Map.keys returns list of binary keys for Presence maps
        return untyped __elixir__('Map.keys({0})', presences);
    }
    
    /**
     * Check if a key is present in the presence list
     */
    public static function isPresent(presences: PresenceList, key: PresenceKey): Bool {
        // Presence keys are strings; Map.has_key? supports binary keys
        return untyped __elixir__('Map.has_key?({0}, {1})', presences, key);
    }
    
    /**
     * Count total number of presences
     */
    public static function count(presences: PresenceList): Int {
        // map_size/1 returns number of entries
        return untyped __elixir__('map_size({0})', presences);
    }
}
