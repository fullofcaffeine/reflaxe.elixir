package phoenix;

import elixir.types.Term;

/**
 * Phoenix.Presence extern definitions for low-level real-time presence tracking
 * 
 * ## Overview
 * 
 * Phoenix.Presence provides a distributed, real-time presence tracking system that works
 * across multiple nodes in your Phoenix application. It's built on top of Phoenix PubSub
 * and uses a CRDT (Conflict-free Replicated Data Type) for eventual consistency.
 * 
 * ## How Phoenix.Presence Works
 * 
 * Phoenix.Presence uses a special behavior that injects functions into your app's
 * Presence module when you call `use Phoenix.Presence`. In Haxe apps, prefer defining
 * a `@:presence` module that implements `PresenceBehavior` and calling that generated
 * module's helpers from LiveViews:
 *
 * ```haxe
 * var topic = PresenceTopic.of("room:" + roomId);
 * var key = PresenceKey.of(currentUserId);
 * live = ChatPresence.trackWithSocket(live, topic, key, meta);
 * var onlineUsers = ChatPresence.list(topic);
 * var currentUser = ChatPresence.getByKey(topic, key);
 * ```
 *
 * Use this raw `phoenix.Presence` extern when you intentionally need direct interop
 * with Phoenix.Presence itself. Most app code should go through the generated module
 * (`ChatPresence`, `TodoPresence`, etc.) so calls preserve the app module name and
 * use the correct process/topic/key shape.
 * 
 * ### Inside a Presence Module (with `use Phoenix.Presence`)
 * 
 * When you define a module with `use Phoenix.Presence`, Phoenix injects functions
 * used by the generated Haxe helpers:
 * 
 * ```elixir
 * defmodule MyAppWeb.Presence do
 *   use Phoenix.Presence, otp_app: :my_app
 *   
 *   def track_user(topic, user_id, meta) do
 *     # Track the current LiveView/process in an explicit topic.
 *     track(self(), topic, user_id, meta)
 *   end
 * end
 * ```
 * 
 * ### Outside a Presence Module
 * 
 * When calling from outside (e.g. from a LiveView), use the generated app Presence
 * module helpers, not `Phoenix.Presence` directly:
 * 
 * ```elixir
 * defmodule MyAppWeb.UserLive do
 *   alias MyAppWeb.Presence
 *   
 *   def mount(_params, _session, socket) do
 *     Presence.track(self(), "users", user_id, %{online_at: now()})
 *     online = Presence.list("users")
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
 * In Haxe, when you create a Presence module with `@:presence` and `PresenceBehavior`:
 * 
 * ```haxe
 * @:presence
 * class TodoPresence implements PresenceBehavior {}
 *
 * // From a LiveView:
 * var topic = PresenceTopic.of("users");
 * var key = PresenceKey.of(Std.string(user.id));
 * live = TodoPresence.trackWithSocket(live, topic, key, meta);
 * var users = TodoPresence.list(topic);
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
typedef PresenceMeta = Term;

/**
 * Backward-compatible topic alias for low-level extern signatures.
 *
 * New code should import `phoenix.PresenceTopic` and `phoenix.PresenceKey`
 * directly. Haxe cannot safely re-export those exact names from this module
 * because same-name module aliases become recursive typedefs.
 */
typedef Topic = phoenix.PresenceTopic;

/**
 * Presence entry containing accumulated metadata for a key
 * 
 * ## What is TMeta?
 * 
 * TMeta is a generic type parameter that represents the type of metadata attached to each presence.
 * It allows you to use type-safe custom metadata structures instead of raw terms.
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
 * // Use it with the generated app Presence module.
 * var userPresence: Null<PresenceEntry<UserMeta>> =
 *     ChatPresence.getByKey(PresenceTopic.of("users"), PresenceKey.of("user_123"));
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
 * 3. **Using raw terms**: When you don't need type safety
 *    ```haxe
 *    var presence: Null<PresenceEntry<Term>> = ChatPresence.getByKey("users", key);
 *    ```
 * 
 * @param TMeta The type of metadata attached to each presence. Can be any type including
 *              raw terms for untyped metadata, or a custom typedef/class for type-safe access.
 */
typedef PresenceEntry<TMeta> = {
	var metas:Array<TMeta>;
};

/**
 * Presence list containing all presences for a topic.
 *
 * Phoenix returns `%{presence_key => %{metas: [...]}}`. The Haxe surface keeps
 * the same runtime shape while allowing app code to supply the metadata type.
 * Use `PresenceList<Term>` at direct interop boundaries where the metadata shape
 * is intentionally not modeled.
 */
typedef PresenceList<TMeta> = Map<String, PresenceEntry<TMeta>>;

/**
 * Low-level Phoenix.Presence functions for tracking user presence.
 *
 * Prefer generated `PresenceBehavior` helpers from application code. They emit
 * `<AppWeb>.Presence.track(self(), topic, key, meta)`, `<AppWeb>.Presence.list(topic)`,
 * and related app-module calls. This extern remains for direct Phoenix interop.
 */
@:native("Phoenix.Presence")
extern class Presence {
	/**
	 * Track a channel socket with metadata (3-argument channel shape)
	 * 
	 * **Lower-level API**: App LiveViews should usually call a generated presence
	 * module helper such as `ChatPresence.trackWithSocket(socket, topic, key, meta)`.
	 * This raw extern maps to Phoenix.Presence's channel/socket-oriented `track/3`
	 * shape and does not choose your app Presence module for you.
	 * 
	 * ## Usage from Outside (LiveView/Channel)
	 * ```haxe
	 * // Preferred LiveView pattern:
	 * live = MyPresence.trackWithSocket(live, "users", user_id, meta);
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
	 * @return Term Either {:ok, ref} or {:error, reason}
	 */
	@:native("track")
	public static function track(socket:Term, key:PresenceKey, meta:PresenceMeta):Term;

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
	 * @return Term Either {:ok, ref} or {:error, reason}
	 */
	@:native("track")
	public static function trackPid(pid:Term, topic:Topic, key:PresenceKey, meta:PresenceMeta):Term;

	/**
	 * Stop tracking a channel's process
	 * Returns :ok
	 * 
	 * @param socket Channel socket
	 * @param key Presence key to untrack
	 */
	@:native("untrack")
	public static function untrack(socket:Term, key:PresenceKey):Term;

	/**
	 * Stop tracking an arbitrary process
	 * Returns :ok
	 * 
	 * @param pid Process to untrack
	 * @param topic Topic to untrack from
	 * @param key Presence key to untrack
	 */
	@:native("untrack")
	public static function untrackPid(pid:Term, topic:Topic, key:PresenceKey):Term;

	/**
	 * Get all presences for a topic or channel socket
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
	 * // Preferred app-module usage.
	 * var presences = ChatPresence.list("users");
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
	 * @param socketOrTopic Either a topic string or a channel socket
	 * @return PresenceList Map of presence_key to typed metadata entries
	 */
	@:native("list")
	public static function list<TMeta>(socketOrTopic:Term):PresenceList<TMeta>;

	/**
	 * Update presence metadata for a channel socket
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
	 * // Preferred LiveView pattern.
	 * live = ChatPresence.updateWithSocket(live, "users", user_id, {
	 *     status: "editing",
	 *     editingTodoId: todoId
	 * });
	 * ```
	 * 
	 * ## Metadata Parameter
	 * Can be either:
	 * - A new metadata map (replaces existing)
	 * - An update function: `(old_meta) -> new_meta`
	 * 
	 * ## Self() Requirement
	 * Inside a Presence module: `update(self(), topic, key, meta)`
	 * 
	 * @param socket Channel socket containing the process/topic
	 * @param key Presence key to update (must already be tracked)
	 * @param meta New metadata map or update function
	 * @return Term Either {:ok, ref} or {:error, :not_tracked}
	 */
	@:native("update")
	public static function update(socket:Term, key:PresenceKey, meta:PresenceMeta):Term;

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
	public static function updatePid(pid:Term, topic:Topic, key:PresenceKey, meta:PresenceMeta):Term;

	/**
	 * Get presence entries for a specific key.
	 *
	 * Prefer generated `PresenceBehavior` modules for app code:
	 * `ChatPresence.getByKey(topic, key)` returns `Null<PresenceEntry<TMeta>>`,
	 * matching the `[] -> nil` convenience used by Haxe call sites.
	 * 
	 * @param socketOrTopic Topic string or channel socket
	 * @param key Presence key to get
	 */
	@:native("get_by_key")
	public static function getByKey<TMeta>(socketOrTopic:Term, key:PresenceKey):Array<PresenceEntry<TMeta>>;
}

/**
 * Helper functions for working with presence data
 * Note: These are utility functions you can implement in your application
 */
#if (reflaxe_runtime)
// Runtime helpers moved to std/_std to avoid macro-time __elixir__ references
#end
