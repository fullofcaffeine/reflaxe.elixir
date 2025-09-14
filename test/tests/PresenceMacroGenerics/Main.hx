package;

import phoenix.PresenceBehavior;

/**
 * Test for PresenceMacro with generic type parameters
 * 
 * Validates that the macro generates methods with proper generic types <T, M>
 * instead of using Dynamic, providing complete type safety for both:
 * - Socket types (any type - phoenix.Socket, LiveSocket<T>, or custom)
 * - Metadata types (user-defined typedefs or anonymous structures)
 */

// Test LiveView socket type (generic)
typedef LiveSocket<T> = {
    assigns: T,
    endpoint: String,
    ?id: String
}

// Test metadata type
typedef UserPresenceMeta = {
    onlineAt: Float,
    userName: String,
    ?status: String,
    ?editingDocId: Null<Int>
}

// Test custom socket type for demonstration
typedef CustomSocket = {
    assigns: Dynamic,
    endpoint: String,
    ?id: String
}

@:native("TestApp.Presence")
@:presence
class TestPresence implements PresenceBehavior {
    // Test that the generated methods work with various socket types
    
    // Test with LiveView Socket<T>
    public static function trackUserLiveView<T>(socket: LiveSocket<T>, userId: String, userName: String): LiveSocket<T> {
        var meta: UserPresenceMeta = {
            onlineAt: Date.now().getTime(),
            userName: userName,
            status: "active"
        };
        
        // This should use the generic version with type safety
        return trackInternal(socket, userId, meta);
    }
    
    // Test with custom socket type
    public static function trackUserCustom(socket: CustomSocket, userId: String, userName: String): CustomSocket {
        var meta: UserPresenceMeta = {
            onlineAt: Date.now().getTime(),
            userName: userName
        };
        
        // Generic type parameter T accepts any type
        return trackInternal(socket, userId, meta);
    }
    
    // Test with anonymous structure metadata
    public static function trackWithAnonymous<T>(socket: T, key: String): T {
        var meta = {
            timestamp: Date.now().getTime(),
            source: "test"
        };
        
        // Both socket and metadata use generic types
        return trackInternal(socket, key, meta);
    }
    
    // Test update method with generics
    public static function updateUserStatus<T>(socket: T, userId: String, newStatus: String): T {
        var meta: UserPresenceMeta = {
            onlineAt: Date.now().getTime(),
            userName: "test",
            status: newStatus
        };
        
        return updateInternal(socket, userId, meta);
    }
    
    // Test untrack with generic socket
    public static function removeUser<T>(socket: T, userId: String): T {
        return untrackInternal(socket, userId);
    }
    
    // Test list method with generics
    public static function getAllUsers<T>(socket: T): Dynamic {
        return list(socket);
    }
    
    // Test getByKey with generics  
    public static function findUser<T>(socket: T, userId: String): Dynamic {
        return getByKey(socket, userId);
    }
}

// Test usage from outside (LiveView context)
class ExternalUsage {
    public static function testExternalMethods() {
        // Mock socket for testing
        var socket: LiveSocket<Dynamic> = cast {};
        
        // External methods should also use generics
        var tracked = TestPresence.track(socket, "user123", {
            onlineAt: Date.now().getTime(),
            userName: "John"
        });
        
        var updated = TestPresence.update(tracked, "user123", {
            onlineAt: Date.now().getTime(),
            userName: "John",
            status: "away"
        });
        
        var untracked = TestPresence.untrack(updated, "user123");
        
        // All return the same socket type, preserving type safety
        var _: LiveSocket<Dynamic> = untracked;
    }
}

class Main {
    static function main() {
        // This file tests compilation of the macro-generated methods
        // The actual runtime behavior is tested in Elixir
        trace("PresenceMacro generic types test compiled successfully");
    }
}