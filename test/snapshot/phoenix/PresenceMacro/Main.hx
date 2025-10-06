package;

import phoenix.PresenceBehavior;
import phoenix.Socket;
import phoenix.Presence.PresenceEntry;

/**
 * Test for PresenceMacro - validates that the macro generates both internal
 * and external presence methods correctly with proper type safety.
 * 
 * The macro should generate:
 * - Internal methods (trackInternal, updateInternal, untrackInternal) with self()
 * - External methods (track, update, untrack) calling Phoenix.Presence
 * - Utility methods (list, getByKey)
 * 
 * All methods should be properly typed with generic parameters T and M.
 */

// Test metadata type
typedef TestMeta = {
	onlineAt: Float,
	userName: String,
	status: String
}

// Test presence module implementing PresenceBehavior
@:native("TestApp.Presence")
@:presence
class TestPresence implements PresenceBehavior {
	// Topic constant for Presence operations
	static inline var TOPIC = "presence:test";

	// Custom method that uses the generated internal methods
	public static function trackTestUser(socket: Socket, userId: String, name: String): Socket {
		var meta: TestMeta = {
			onlineAt: Date.now().getTime(),
			userName: name,
			status: "active"
		};

		// This should use the macro-generated trackInternal method
		trackInternal(TOPIC, userId, meta);
		return socket;
	}

	// Custom method that uses the generated update method
	public static function updateStatus(socket: Socket, userId: String, newStatus: String): Socket {
		// Get current metadata using generated list method
		var presences = list(TOPIC);

		if (Reflect.hasField(presences, userId)) {
			var entry: PresenceEntry<TestMeta> = Reflect.field(presences, userId);
			if (entry.metas.length > 0) {
				var currentMeta = entry.metas[0];
				var updatedMeta: TestMeta = {
					onlineAt: currentMeta.onlineAt,
					userName: currentMeta.userName,
					status: newStatus
				};

				// This should use the macro-generated updateInternal method
				updateInternal(TOPIC, userId, updatedMeta);
			}
		}

		return socket;
	}

	// Custom method that uses the generated untrack method
	public static function removeUser(socket: Socket, userId: String): Socket {
		// This should use the macro-generated untrackInternal method
		untrackInternal(TOPIC, userId);
		return socket;
	}
}

// Test that external methods can be called from outside
class ExternalCaller {
	static inline var TOPIC = "presence:test";

	public static function callFromOutside(socket: Socket): Void {
		// These should use the macro-generated external methods that call Phoenix.Presence
		var meta: TestMeta = {
			onlineAt: Date.now().getTime(),
			userName: "External User",
			status: "online"
		};

		// External track (should call Phoenix.Presence.track)
		TestPresence.track(TOPIC, "external_user", meta);

		// External update (should call Phoenix.Presence.update)
		TestPresence.update(TOPIC, "external_user", meta);

		// External untrack (should call Phoenix.Presence.untrack)
		TestPresence.untrack(TOPIC, "external_user");

		// List and getByKey should work externally too
		var allPresences = TestPresence.list(TOPIC);
		var userPresence = TestPresence.getByKey(TOPIC, "external_user");

		// Type safety check - should be able to access typed metadata
		if (userPresence != null && userPresence.metas.length > 0) {
			var typedMeta: TestMeta = userPresence.metas[0];
			trace("User status: " + typedMeta.status);
			trace("User name: " + typedMeta.userName);
		}
	}
}

class Main {
	static function main() {
		// Create a mock socket for testing
		var socket: Socket = untyped {};
		
		// Test internal methods via custom functions
		TestPresence.trackTestUser(socket, "user_1", "Alice");
		TestPresence.updateStatus(socket, "user_1", "busy");
		TestPresence.removeUser(socket, "user_1");
		
		// Test external methods
		ExternalCaller.callFromOutside(socket);
		
		trace("PresenceMacro test completed successfully");
	}
}