package;

import phoenix.Presence;

/**
 * Edge case tests for Phoenix.Presence integration
 * 
 * Tests complex scenarios that might break the self() injection:
 * 1. Presence calls within conditional expressions  
 * 2. Presence calls within switch cases
 * 3. Presence calls with complex parameter expressions
 * 4. Presence calls from LiveView/Channel context
 */

// Test: Presence calls within conditional logic
@:presence
@:native("MyAppWeb.ConditionalPresence")
class ConditionalPresence {
    public static function trackConditionally(socket: Dynamic, userId: String, isAdmin: Bool, meta: Dynamic): Dynamic {
        // Should inject self() even in conditional
        if (isAdmin) {
            return Presence.track(socket, userId, {role: "admin", meta: meta});
        } else {
            return Presence.track(socket, userId, {role: "user", meta: meta});
        }
    }
    
    public static function trackInSwitch(socket: Dynamic, userId: String, userType: String, meta: Dynamic): Dynamic {
        // Should inject self() in switch cases
        return switch(userType) {
            case "admin":
                Presence.track(socket, userId, {role: "admin", permissions: "all"});
            case "moderator":
                Presence.track(socket, userId, {role: "mod", permissions: "some"});
            default:
                Presence.track(socket, userId, {role: "user", permissions: "basic"});
        }
    }
}

// Test: Complex parameter expressions
@:presence
@:native("MyAppWeb.ComplexPresence")
class ComplexPresence {
    public static function trackWithComputation(socket: Dynamic, user: Dynamic): Dynamic {
        // Complex parameter expressions should still work with self() injection
        return Presence.track(
            socket,
            user.id + "_" + Date.now().getTime(),
            {
                name: user.firstName + " " + user.lastName,
                timestamp: Math.floor(Date.now().getTime() / 1000),
                computed: user.score > 100 ? "expert" : "novice"
            }
        );
    }
    
    public static function trackNested(socket: Dynamic, users: Array<Dynamic>): Array<Dynamic> {
        // Nested Presence calls in array operations
        return users.map(user -> Presence.track(socket, user.id, {status: "online"}));
    }
}

// Test: LiveView context (simulating a LiveView module)
@:presence
@:native("MyAppWeb.PresenceLive")
class PresenceLive {
    public static function mount(params: Dynamic, session: Dynamic, socket: Dynamic): Dynamic {
        // LiveView mount should inject self() for Presence calls
        var userId = session.userId;
        socket = Presence.track(socket, userId, {joined_at: Date.now().getTime()});
        return {ok: socket};
    }
    
    public static function handleEvent(event: String, params: Dynamic, socket: Dynamic): Dynamic {
        return switch(event) {
            case "user_typing":
                // Event handlers should inject self()
                {noreply: Presence.update(socket, params.userId, {typing: true})};
            case "user_stopped_typing":
                {noreply: Presence.update(socket, params.userId, {typing: false})};
            default:
                {noreply: socket};
        }
    }
}

// Test: Incorrect usage that should NOT inject self()
@:native("MyAppWeb.IncorrectUsage")
class IncorrectUsage {
    // NO @:presence annotation - should generate Phoenix.Presence remote calls
    public static function tryToTrack(socket: Dynamic, userId: String): Dynamic {
        // This should fail at runtime or generate Phoenix.Presence.track
        return Presence.track(socket, userId, {status: "attempting"});
    }
}

// Test: Mixed local and remote calls
@:presence
@:native("MyAppWeb.MixedUsage")
class MixedUsage {
    public static function localAndRemote(socket: Dynamic, userId: String): Dynamic {
        // Local call (has @:presence)
        var result = Presence.track(socket, userId, {local: true});
        
        // Calling another module's Presence (should be remote)
        // This would need to be tested with actual cross-module calls
        
        return result;
    }
}

// Main test entry point
class Main {
    static function main() {
        trace("Phoenix.Presence edge case tests compiled successfully");
    }
}