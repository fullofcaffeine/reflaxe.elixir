package;

import phoenix.PresenceBehavior;
import phoenix.Presence;

/**
 * Test Phoenix.Presence behavior implementation with:
 * - Class-level @:presenceTopic annotation
 * - Simple API methods (trackSimple, updateSimple, untrackSimple)
 * - Chainable socket methods
 * - Proper self() injection for Phoenix.Tracker compatibility
 */
@:native("TestApp.Presence")
@:presence
@:presenceTopic("test:presence")
class TestPresence implements PresenceBehavior {
    
    /**
     * Test simple tracking without socket
     * Should generate: Phoenix.Presence.track(self(), "test:presence", key, meta)
     */
    public static function testSimpleTrack(): Void {
        var key = "user:123";
        var meta = {
            onlineAt: Date.now().getTime(),
            status: "active"
        };
        
        // This should compile to Phoenix.Presence.track(self(), "test:presence", key, meta)
        trackSimple(key, meta);
    }
    
    /**
     * Test simple update without socket
     * Should generate: Phoenix.Presence.update(self(), "test:presence", key, meta)
     */
    public static function testSimpleUpdate(): Void {
        var key = "user:123";
        var meta = {
            onlineAt: Date.now().getTime(),
            status: "away"
        };
        
        // This should compile to Phoenix.Presence.update(self(), "test:presence", key, meta)
        updateSimple(key, meta);
    }
    
    /**
     * Test simple untrack without socket
     * Should generate: Phoenix.Presence.untrack(self(), "test:presence", key)
     */
    public static function testSimpleUntrack(): Void {
        var key = "user:123";
        
        // This should compile to Phoenix.Presence.untrack(self(), "test:presence", key)
        untrackSimple(key);
    }
    
    /**
     * Test chainable socket methods
     * Should maintain socket chaining pattern
     */
    public static function testChainableMethods<T>(socket: Dynamic): Dynamic {
        var key = "user:456";
        var meta = {
            onlineAt: Date.now().getTime(),
            device: "mobile"
        };
        
        // Test chainable track
        socket = trackWithSocket(socket, "custom:topic", key, meta);
        
        // Test chainable update
        socket = updateWithSocket(socket, "custom:topic", key, {
            onlineAt: Date.now().getTime(),
            device: "desktop"
        });
        
        // Test chainable untrack
        socket = untrackWithSocket(socket, "custom:topic", key);
        
        return socket;
    }
    
    /**
     * Test that generated methods include self() for Phoenix.Tracker compatibility
     * This is the critical test to prevent regression of the circular bug
     */
    public static function testTrackerCompatibility(): Void {
        // These methods MUST generate with self() as first parameter:
        // Phoenix.Presence.track(self(), topic, key, meta)
        // NOT: Phoenix.Presence.track(topic, key, meta)
        
        trackSimple("critical:test", {test: true});
        updateSimple("critical:test", {test: false});
        untrackSimple("critical:test");
    }
}

/**
 * Test presence without @:presenceTopic annotation
 * Should use traditional trackInternal/updateInternal API
 */
@:native("TestApp.LegacyPresence")
@:presence
class LegacyPresence implements PresenceBehavior {
    
    public static function testLegacyMethods(): Void {
        var topic = "legacy:topic";
        var key = "user:789";
        var meta = {status: "online"};
        
        // Should still work with explicit topic
        untyped __elixir__('Phoenix.Presence.track({0}, {1}, {2}, {3})', 
            untyped __elixir__("self()"), topic, key, meta);
    }
}

class Main {
    static function main() {
        // Test all presence patterns
        TestPresence.testSimpleTrack();
        TestPresence.testSimpleUpdate();
        TestPresence.testSimpleUntrack();
        TestPresence.testTrackerCompatibility();
        
        // Test legacy patterns
        LegacyPresence.testLegacyMethods();
        
        // Test socket chaining
        var socket = {};
        socket = TestPresence.testChainableMethods(socket);
    }
}