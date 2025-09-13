package;

import phoenix.Presence;

/**
 * Test that Phoenix.Presence behavior transformations work correctly.
 * 
 * When using Phoenix.Presence behavior, methods like track(), update(), and untrack()
 * need self() injected as the first argument.
 */
@:presence
@:native("TestPresence")
class TestPresence {
    
    // Test basic track method - should inject self()
    public static function trackUser(socket: Dynamic, userId: String, meta: Dynamic): Dynamic {
        // This should become: track(self(), socket, "users", user_id, meta)
        return Presence.track(socket, userId, meta);
    }
    
    // Test update method - should inject self()
    public static function updateUser(socket: Dynamic, userId: String, meta: Dynamic): Dynamic {
        // This should become: update(self(), socket, "users", user_id, meta)
        return Presence.update(socket, userId, meta);
    }
    
    // Test untrack method - should inject self()
    public static function untrackUser(socket: Dynamic, userId: String): Dynamic {
        // This should become: untrack(self(), socket, "users", user_id)
        return Presence.untrack(socket, userId);
    }
    
    // Test list method - should NOT inject self()
    public static function listUsers(socket: Dynamic): Dynamic {
        // This should become: list(socket) - no self() needed
        return Presence.list(socket);
    }
    
    // Test getByKey method - should NOT inject self()
    public static function getUser(socket: Dynamic, userId: String): Dynamic {
        // This should become: get_by_key(socket, user_id) - no self() needed
        return Presence.getByKey(socket, userId);
    }
}

// Also test that regular classes don't get transformation
class RegularClass {
    public static function testMethod(): Void {
        // If Presence methods were called here, they should NOT get self() injection
        // because this class doesn't have @:presence metadata
    }
}