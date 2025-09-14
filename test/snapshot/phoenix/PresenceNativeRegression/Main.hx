/**
 * Regression test for @:native Presence classes not receiving BehaviorTransformer
 * 
 * Issue: When a Presence class uses @:native annotation, it compiles as an extern
 * class which bypasses the normal compilation path where BehaviorTransformer is active.
 * This causes Phoenix.Presence method calls to miss the required self() injection.
 * 
 * Expected: Classes with both @:native and @:presence should still get transformations
 * Actual (before fix): @:native classes bypass BehaviorTransformer entirely
 */

import phoenix.Presence;

/**
 * This mimics the TodoPresence class which uses @:native("TodoAppWeb.Presence")
 * and should still receive BehaviorTransformer treatment for self() injection
 */
@:native("MyAppWeb.Presence")
@:presence
class NativePresence {
    public static function trackUser(socket: Dynamic, userId: String, meta: Dynamic): Dynamic {
        // This should be transformed to: track(self(), socket, userId, meta)
        return Presence.track(socket, userId, meta);
    }
    
    public static function updateUser(socket: Dynamic, userId: String, meta: Dynamic): Dynamic {
        // This should be transformed to: update(self(), socket, userId, meta)
        return Presence.update(socket, userId, meta);
    }
    
    public static function untrackUser(socket: Dynamic, userId: String): Dynamic {
        // This should be transformed to: untrack(self(), socket, userId)
        return Presence.untrack(socket, userId);
    }
}

/**
 * Control test - regular @:presence without @:native should also work
 */
@:presence
class RegularPresence {
    public static function trackUser(socket: Dynamic, userId: String, meta: Dynamic): Dynamic {
        return Presence.track(socket, userId, meta);
    }
}

class Main {
    static function main() {
        // Force compilation by using the classes
        var socket = {};
        NativePresence.trackUser(socket, "user1", {});
        RegularPresence.trackUser(socket, "user2", {});
    }
}