package server.presence;

import phoenix.Phoenix.Socket;
import phoenix.Phoenix.Presence;
import phoenix.Phoenix.PresenceEntry;
import phoenix.LiveSocket;
import server.types.Types.User;

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

// PresenceEntry is now imported from the framework layer (phoenix.Phoenix.PresenceEntry)
// This ensures consistency across all Phoenix applications

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
 */
@:native("TodoAppWeb.Presence")
@:presence
class TodoPresence {
    /**
     * Track a user's presence in the todo app (idiomatic Phoenix pattern)
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
        // Single presence entry per user - the Phoenix way
        return Presence.track(socket, "users", Std.string(user.id), meta);
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
        // Get current presence metadata
        var currentMeta = getUserPresence(socket, user.id);
        if (currentMeta == null) {
            // User not tracked yet, track them first
            return trackUser(socket, user);
        }
        
        // Update the metadata with new editing state
        var updatedMeta: PresenceMeta = {
            onlineAt: currentMeta.onlineAt,
            userName: currentMeta.userName,
            userEmail: currentMeta.userEmail,
            avatar: currentMeta.avatar,
            editingTodoId: todoId,
            editingStartedAt: todoId != null ? Date.now().getTime() : null
        };
        
        // Phoenix pattern: update existing presence rather than track/untrack
        return Presence.update(socket, "users", Std.string(user.id), updatedMeta);
    }
    
    /**
     * Helper to get current user presence metadata
     */
    static function getUserPresence<T>(socket: Socket<T>, userId: Int): Null<PresenceMeta> {
        var presences = Presence.listTopic("users");
        var userKey = Std.string(userId);
        if (presences.exists(userKey)) {
            var entry = presences.get(userKey);
            return entry.metas.length > 0 ? entry.metas[0] : null;
        }
        return null;
    }
    
    /**
     * Get list of users currently online
     */
    public static function listOnlineUsers<T>(socket: Socket<T>): Map<String, PresenceEntry<PresenceMeta>> {
        // Use framework-level Presence abstraction instead of __elixir__()
        return Presence.listTopic("users");
    }
    
    /**
     * Get users currently editing a specific todo (idiomatic Phoenix pattern)
     * 
     * Filters the single presence list by editing state rather than
     * querying separate topics - more maintainable and Phoenix-like.
     */
    public static function getUsersEditingTodo<T>(socket: Socket<T>, todoId: Int): Array<PresenceMeta> {
        var allUsers = Presence.listTopic("users");
        var editingUsers = [];
        
        for (userId => entry in allUsers) {
            if (entry.metas.length > 0) {
                var meta = entry.metas[0];
                if (meta.editingTodoId == todoId) {
                    editingUsers.push(meta);
                }
            }
        }
        
        return editingUsers;
    }
}
