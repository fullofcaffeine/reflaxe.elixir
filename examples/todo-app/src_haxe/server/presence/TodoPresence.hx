package server.presence;

import phoenix.Phoenix.Socket;
import phoenix.Presence;
import phoenix.PresenceBehavior;
import phoenix.LiveSocket;
import server.types.Types.User;
import server.types.Types.PresenceTopic;
import server.types.Types.PresenceTopics;

/**
 * Unified presence metadata following idiomatic Phoenix patterns
 * 
 * In Phoenix apps, each user has a single presence entry with all their state.
 * This avoids complex nested structures and multiple presence topics.
 */
typedef PresenceMeta = {
    var onlineAt: Float;
    var userName: String;
    var userEmail: String;
    var avatar: Null<String>;
    // Editing state is part of the same presence entry (Phoenix pattern)
    var editingTodoId: Null<Int>;  // null = not editing, Int = editing todo ID
    var editingStartedAt: Null<Float>;  // When they started editing
}

// PresenceEntry is defined in phoenix.Presence module as a generic typedef
// This provides type-safe presence metadata across all Phoenix applications

/**
 * Idiomatic Phoenix Presence implementation with type-safe Haxe augmentation
 * 
 * This module follows standard Phoenix Presence patterns:
 * - Single presence entry per user (not multiple topics)
 * - All user state in one metadata structure
 * - Updates via Presence.update() rather than track/untrack
 * 
 * The generated Elixir code is indistinguishable from hand-written Phoenix,
 * but with compile-time type safety that Phoenix developers wish they had.
 * 
 * TYPE SAFETY PATTERNS:
 * 
 * Option 1: Use string constant (simple but less type-safe)
 * @:presenceTopic("users")
 * 
 * Option 2: Use static constant (better for shared topics)
 * static inline final TOPIC = "users";
 * @:presenceTopic(TOPIC)  // Note: This requires macro enhancement
 * 
 * Option 3: Use enum + helper (most type-safe, compile-time validation)
 * // Define topic in Types.hx enum, use string in annotation
 * @:presenceTopic("users")  // Must match PresenceTopic.Users mapping
 * 
 * The enum approach provides compile-time validation through the
 * PresenceTopics.toString() helper, ensuring consistency across the app.
 */
@:native("TodoAppWeb.Presence")
@:presence
@:presenceTopic("users")  // Must match PresenceTopics.toString(Users)
class TodoPresence implements PresenceBehavior {
    /**
     * Type-safe topic reference for compile-time validation
     * Use this to ensure consistency with the @:presenceTopic annotation
     */
    public static inline final TOPIC_ENUM = PresenceTopic.Users;
    public static inline final TOPIC = "users"; // Must match PresenceTopics.toString(TOPIC_ENUM)
    /**
     * Track a user's presence in the todo app (idiomatic Phoenix pattern)
     * 
     * Uses the new simplified API with class-level topic configuration.
     * 
     * @param socket The LiveView socket
     * @param user The user to track
     */
    public static function trackUser<T>(socket: Socket<T>, user: User): Socket<T> {
        var meta: PresenceMeta = {
            onlineAt: Date.now().getTime(),
            userName: user.name,
            userEmail: user.email,
            avatar: null,
            editingTodoId: null,  // Not editing initially
            editingStartedAt: null
        };
        // Use the simplified API - no need to pass topic!
        trackSimple(Std.string(user.id), meta);
        return socket;
    }
    
    /**
     * Update user's editing state (idiomatic Phoenix pattern)
     * 
     * Instead of track/untrack on different topics, we update the metadata
     * on the single user presence entry - this is the Phoenix way.
     * 
     * @param socket The LiveView socket
     * @param user The user whose state to update
     * @param todoId The todo being edited (null to stop editing)
     */
    public static function updateUserEditing<T>(socket: Socket<T>, user: User, todoId: Null<Int>): Socket<T> {
        // Update the metadata with new editing state (assume track happened elsewhere)
        var updatedMeta: PresenceMeta = {
            onlineAt: Date.now().getTime(),
            userName: user.name,
            userEmail: user.email,
            avatar: null,
            editingTodoId: todoId,
            editingStartedAt: todoId != null ? Date.now().getTime() : null
        };
        // Use the simplified API - topic is configured at class level
        updateSimple(Std.string(user.id), updatedMeta);
        return socket;
    }
    
    // Removed getUserPresence helper to avoid unused function warning in generated code when
    // presence update is simplified by transforms.
    
    /**
     * Get list of users currently online
     */
    public static function listOnlineUsers<T>(socket: Socket<T>): haxe.DynamicAccess<phoenix.Presence.PresenceEntry<PresenceMeta>> {
        // Use the generated listSimple() method
        return listSimple();
    }
    
    /**
     * Get users currently editing a specific todo (idiomatic Phoenix pattern)
     * 
     * Filters the single presence list by editing state rather than
     * querying separate topics - more maintainable and Phoenix-like.
     */
    public static function getUsersEditingTodo<T>(socket: Socket<T>, todoId: Int): Array<PresenceMeta> {
        // Get all users through the generated listSimple() method
        var allUsers = listSimple();
        var metas:Array<PresenceMeta> = [];
        for (userId in Reflect.fields(allUsers)) {
            var entry: phoenix.Presence.PresenceEntry<PresenceMeta> = Reflect.field(allUsers, userId);
            if (entry.metas.length > 0) {
                var meta = entry.metas[0];
                if (meta.editingTodoId == todoId) metas.push(meta);
            }
        }
        return metas;
    }
}
