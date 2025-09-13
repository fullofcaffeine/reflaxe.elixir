/**
 * Additional edge case tests for @:native Presence classes
 * 
 * Tests:
 * - Classes with @:native that match external module names
 * - Multiple methods with different argument counts
 * - Methods that don't need self() injection (list, get_by_key)
 * - Interaction between @:presence and @:native metadata
 */

import phoenix.Presence;

// Test 1: Class with @:native matching external module (edge case)
@:native("Phoenix.Presence")
@:presence
class PhoenixPresenceWrapper {
    // Should inject self() for track
    public static function trackSession(socket: Dynamic, sessionId: String, data: Dynamic): Dynamic {
        return Presence.track(socket, sessionId, data);
    }
    
    // Should inject self() for update
    public static function updateSession(socket: Dynamic, sessionId: String, data: Dynamic): Dynamic {
        return Presence.update(socket, sessionId, data);
    }
    
    // Should NOT inject self() for list
    public static function listSessions(topic: String): Dynamic {
        return Presence.list(topic);
    }
    
    // Should NOT inject self() for get_by_key  
    public static function getSession(topic: String, key: String): Dynamic {
        return Presence.getByKey(topic, key);
    }
}

// Test 2: Class with different @:native name
@:native("MyApp.CustomPresence")
@:presence
class CustomPresence {
    // All track/update/untrack variations
    public static function track3Args(socket: Dynamic, key: String, meta: Dynamic): Dynamic {
        return Presence.track(socket, key, meta);
    }
    
    public static function updateKey(socket: Dynamic, key: String, meta: Dynamic): Dynamic {
        return Presence.update(socket, key, meta);
    }
    
    public static function untrackKey(socket: Dynamic, key: String): Dynamic {
        return Presence.untrack(socket, key);
    }
}

// Test 3: Regular class WITHOUT @:native but WITH @:presence
@:presence
class StandardPresence {
    public static function trackItem(socket: Dynamic, itemId: String, metadata: Dynamic): Dynamic {
        return Presence.track(socket, itemId, metadata);
    }
}

// Test 4: Class calling its OWN static methods (not Presence methods)
@:native("MyAppWeb.Presence")
@:presence
class SelfCallingPresence {
    public static function internalHelper(): String {
        return "helper";
    }
    
    public static function publicMethod(): String {
        // This should NOT get self() injection - it's calling own method
        return internalHelper();
    }
    
    public static function trackWithHelper(socket: Dynamic, key: String, meta: Dynamic): Dynamic {
        // This SHOULD get self() injection for Presence.track
        var result = Presence.track(socket, key, meta);
        // But NOT for own method
        var helper = internalHelper();
        return result;
    }
}

class TestMoreEdgeCases {
    public static function main() {
        // Just compile, don't run - we're testing code generation
        trace("Edge case tests compiled successfully");
    }
}