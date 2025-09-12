package;

import phoenix.Presence;

/**
 * Comprehensive test for Phoenix.Presence integration
 * 
 * Tests all scenarios for Phoenix.Presence method calls:
 * 1. Inside @:presence modules (should generate local calls with self())
 * 2. Outside @:presence modules (should generate remote Phoenix.Presence calls)
 * 3. Different argument overloads for track/update/untrack
 * 4. @:native classes should not interfere with @:presence detection
 * 
 * This test ensures that Phoenix.Presence behavior injection works correctly
 * and that self() is added when needed for distributed CRDT synchronization.
 */

// Test 1: Module WITH @:presence annotation - should get local calls with self()
@:presence
@:native("MyAppWeb.ChatPresence")
class ChatPresence {
    // Test track() - the 3-argument channel version
    public static function trackUser(socket: Dynamic, userId: String, meta: Dynamic): Dynamic {
        // Channel variant: track(socket, key, meta)
        // Should generate: track(self(), socket, userId, meta)
        return Presence.track(socket, userId, meta);
    }
    
    // Test update() - the 3-argument channel version
    public static function updateUser(socket: Dynamic, userId: String, meta: Dynamic): Dynamic {
        // Channel variant: update(socket, key, meta)
        // Should generate: update(self(), socket, userId, meta)
        return Presence.update(socket, userId, meta);
    }
    
    // Test untrack() - the 2-argument channel version
    public static function untrackUser(socket: Dynamic, userId: String): Dynamic {
        // Channel variant: untrack(socket, key)
        // Should generate: untrack(self(), socket, userId)
        return Presence.untrack(socket, userId);
    }
    
    // Test trackPid() and untrackPid() - the explicit PID versions
    public static function trackSpecificPid(pid: Dynamic, userId: String, meta: Dynamic): Dynamic {
        // trackPid(pid, topic, key, meta)
        // Should generate: track(self(), pid, "users", userId, meta)
        return Presence.trackPid(pid, "users", userId, meta);
    }
    
    public static function untrackSpecificPid(pid: Dynamic, userId: String): Dynamic {
        // untrackPid(pid, topic, key)
        // Should generate: untrack(self(), pid, "users", userId)
        return Presence.untrackPid(pid, "users", userId);
    }
    
    // Test list() and getByKey() - these DON'T need self()
    public static function listUsers(topic: String): Dynamic {
        // list(topic) - no self() needed
        // Should generate: list(topic)
        return Presence.list(topic);
    }
    
    public static function getUserByKey(topic: String, key: String): Dynamic {
        // getByKey(socketOrTopic, key) - no self() needed
        // Should generate: get_by_key(topic, key)
        return Presence.getByKey(topic, key);
    }
}

// Test 2: Module WITHOUT @:presence annotation - should get remote calls
@:native("MyAppWeb.NormalModule")
class NormalModule {
    public static function trackFromOutside(socket: Dynamic, userId: String, meta: Dynamic): Dynamic {
        // Outside @:presence module - should generate remote call
        // Should generate: Phoenix.Presence.track(socket, userId, meta)
        return Presence.track(socket, userId, meta);
    }
    
    public static function updateFromOutside(socket: Dynamic, userId: String, meta: Dynamic): Dynamic {
        // Outside @:presence module - should generate remote call
        // Should generate: Phoenix.Presence.update(socket, userId, meta)
        return Presence.update(socket, userId, meta);
    }
    
    public static function listFromOutside(topic: String): Dynamic {
        // Outside @:presence module - should generate remote call
        // Should generate: Phoenix.Presence.list(topic)
        return Presence.list(topic);
    }
}

// Test 3: Other @:native class to ensure no interference
@:native("String")
class StringExtern {
    public static function length(s: String): Int {
        // This should still generate String.length(s)
        // Not affected by Phoenix.Presence handling
        return 0; // Dummy implementation
    }
}

// Test 4: Module with both @:native and @:presence
@:presence
@:native("MyAppWeb.SpecialPresence")
class SpecialPresence {
    public static function trackSpecial(socket: Dynamic, key: String, meta: Dynamic): Dynamic {
        // Should handle @:presence even with @:native present
        // Should generate: track(self(), socket, key, meta)
        return Presence.track(socket, key, meta);
    }
    
    // Test interaction with other @:native classes
    public static function trackWithStringOp(socket: Dynamic, userId: String, meta: Dynamic): Dynamic {
        var userKey = StringExtern.length(userId) > 0 ? userId : "anonymous";
        // Should generate: track(self(), socket, userKey, meta)
        return Presence.track(socket, userKey, meta);
    }
}

// Test 5: Ensure Reflect methods still work
class ReflectTest {
    public static function testReflectHasField(obj: Dynamic, field: String): Bool {
        // Should generate: Map.has_key?(obj, String.to_atom(field))
        return Reflect.hasField(obj, field);
    }
    
    public static function testReflectField(obj: Dynamic, field: String): Dynamic {
        // Should generate: Map.get(obj, String.to_atom(field))
        return Reflect.field(obj, field);
    }
}

// Main test entry point
class Main {
    static function main() {
        trace("Phoenix.Presence test scenarios compiled successfully");
        
        // These would be actual test calls in a real scenario
        // For now, we're just testing that the code compiles correctly
        // and generates the expected Elixir code
    }
}