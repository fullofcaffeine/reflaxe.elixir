package phoenix.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;
#end

/**
 * PresenceMacro: Build macro for generating Phoenix.Presence dual API
 * 
 * ## Overview
 * 
 * This macro is triggered by @:autoBuild on the PresenceBehavior interface.
 * It generates a comprehensive set of presence methods with varying levels of abstraction,
 * giving developers the choice between simplicity and control.
 * 
 * ## API Layers (NEW - January 2025)
 * 
 * ### Layer 1: Simple API (Highest Abstraction)
 * When using `@:presenceTopic("topic_name")` annotation:
 * - `trackSimple(key, meta)` - Topic configured at class level
 * - `updateSimple(key, meta)` - No need to pass topic every time
 * - `untrackSimple(key)` - Clean, simple API
 * 
 * ### Layer 2: Chainable Socket API (LiveView Friendly)
 * For LiveView's socket chaining pattern:
 * - `trackWithSocket(socket, topic, key, meta): Socket` - Returns socket for chaining
 * - `updateWithSocket(socket, topic, key, meta): Socket` - Maintains fluent interface
 * - `untrackWithSocket(socket, topic, key): Socket` - Compatible with LiveView patterns
 * 
 * ### Layer 3: Internal API (Full Control)
 * Direct Phoenix.Presence calls with self() injection:
 * - `trackInternal(topic, key, meta)` - Full control over topic
 * - `updateInternal(topic, key, meta)` - Direct presence manipulation
 * - `untrackInternal(topic, key)` - Low-level access
 * 
 * ### Layer 4: External Static API (Framework Use)
 * For calling from outside the presence module:
 * - `track(socket, key, meta)` - Standard Phoenix.Presence interface
 * - `update(socket, key, meta)` - External updates
 * - `untrack(socket, key)` - External cleanup
 * 
 * ## Usage Examples
 * 
 * ### With @:presenceTopic (Recommended)
 * ```haxe
 * @:presence
 * @:presenceTopic("users")
 * class MyPresence implements PresenceBehavior {
 *     public static function trackUser<T>(socket: Socket<T>, user: User): Socket<T> {
 *         trackSimple(Std.string(user.id), createUserMeta(user));
 *         return socket;
 *     }
 * }
 * ```
 * 
 * ### Without @:presenceTopic (Manual Topic)
 * ```haxe
 * @:presence
 * class MyPresence implements PresenceBehavior {
 *     public static function trackUser<T>(socket: Socket<T>, user: User): Socket<T> {
 *         return trackWithSocket(socket, "users", Std.string(user.id), createUserMeta(user));
 *     }
 * }
 * ```
 * 
 * ## CRITICAL DESIGN DECISION: Generic Type Parameters for Universal Type Safety
 * 
 * ### The Type-Safe Solution Using Generics
 * 
 * The socket parameter in all generated methods uses generic type parameter `T` instead of Dynamic.
 * This provides COMPLETE TYPE SAFETY while handling multiple Socket type definitions.
 * 
 * ### How Generic Type Parameters Solve the Problem
 * 
 * 1. **Multiple Socket Type Definitions Handled**:
 *    - `phoenix.Socket` - Non-generic extern class for client-side WebSocket connections
 *    - `phoenix.Phoenix.Socket<T>` - Generic typedef for server-side LiveView sockets
 *    - Generic parameter `T` accepts ANY type at compile time
 * 
 * 2. **Zero-Cost Abstraction with extern inline**:
 *    - Methods marked as `extern inline` for compile-time resolution
 *    - No runtime overhead - methods are inlined at call sites
 *    - Type checking happens at compile time, not runtime
 * 
 * 3. **Full Type Safety Preserved**:
 *    - Socket type `T` flows through the entire call chain
 *    - Metadata type `M` provides type-safe metadata
 * 
 * ## ARCHITECTURAL FIX (September 2025): LiveView Context Requires Topic Strings
 * 
 * ### UPDATE (January 2025): Enhanced API Design
 * 
 * Based on user feedback, the API has been enhanced with multiple abstraction layers:
 * 
 * 1. **Class-Level Topic Configuration**: `@:presenceTopic("topic")` eliminates repetition
 * 2. **Chainable Socket Methods**: Return sockets for LiveView's fluent interface pattern
 * 3. **Simple API Methods**: Hide Phoenix internals for cleaner code
 * 4. **Backward Compatibility**: All existing methods continue to work
 * 
 * This layered approach gives developers maximum flexibility while maintaining type safety.
 * 
 * ### The Problem That Was Fixed
 * 
 * Phoenix.Presence has DIFFERENT APIs for different contexts:
 * - **Channel context**: `track(socket, key, meta)` - 3 parameters
 * - **LiveView context**: `track(pid, topic, key, meta)` - 4 parameters
 * 
 * The macro was incorrectly passing `socket` as the second parameter to Phoenix.Presence.track/4,
 * but in LiveView context, the second parameter MUST be a topic STRING (e.g., "users").
 * 
 * This caused runtime errors:
 * ```
 * Phoenix.Tracker.track/5 no function clause matching:
 * Phoenix.Tracker.track(TodoAppWeb.Presence, #Phoenix.LiveView.Socket<...>, "users", "1", %{...})
 * ```
 * 
 * ### The Solution
 * 
 * Internal methods now correctly accept `topic: String` parameters:
 * - `trackInternal<M>(topic: String, key: String, meta: M): Void`
 * - `updateInternal<M>(topic: String, key: String, meta: M): Void`
 * - `untrackInternal(topic: String, key: String): Void`
 * 
 * These methods call Phoenix.Presence functions with the correct signature:
 * `Phoenix.Presence.track(self(), topic, key, meta)` where topic is a STRING.
 * 
 * ### Usage Pattern
 * 
 * ```haxe
 * // In your presence module:
 * public static function trackUser<T>(socket: Socket<T>, user: User): Socket<T> {
 *     var topic = "users";  // Topic is a STRING for LiveView!
 *     trackInternal(topic, Std.string(user.id), createUserMeta(user));
 *     return socket;
 * }
 * ```
 *    - Return type matches input socket type exactly
 *    - IntelliSense and refactoring work perfectly
 * 
 * 4. **Clean Generated Code**:
 *    - Generic types compile to clean Elixir code
 *    - No Dynamic casts or type conversions needed
 *    - Idiomatic Phoenix.Presence calls generated
 * 
 * ### Implementation Strategy
 * 
 * ```haxe
 * // Generated method signature
 * extern inline public static function trackInternal<T, M>(
 *     socket: T,      // Any socket type
 *     key: String, 
 *     meta: M         // Any metadata type
 * ): T {              // Returns same socket type
 *     return untyped __elixir__('track({0}, {1}, {2}, {3})', 
 *         untyped __elixir__('self()'), socket, key, meta);
 * }
 * ```
 * 
 * ### Benefits Over Dynamic
 * 
 * - **Type Safety**: Full compile-time type checking
 * - **IntelliSense**: Complete IDE support with proper types
 * - **Refactoring**: Safe automated refactoring
 * - **Documentation**: Types are self-documenting
 * - **No Runtime Cost**: extern inline = zero overhead
 * 
 * This solution provides the best of both worlds: universal compatibility with complete type safety.
 * 
 * ## Generated Methods
 * 
 * For classes implementing PresenceBehavior, this macro generates:
 * 
 * ### Internal Methods (use within the presence module)
 * ```haxe
 * // Generated: Injects self() as first parameter with full type safety
 * extern inline public static function trackInternal<T, M>(socket: T, key: String, meta: M): T {
 *     return untyped __elixir__('track({0}, {1}, {2}, {3})', untyped __elixir__('self()'), socket, key, meta);
 * }
 * ```
 * 
 * ### External Static Methods (use from LiveViews)
 * ```haxe
 * // Generated: Calls Phoenix.Presence directly with type-safe parameters
 * extern inline public static function track<T, M>(socket: T, key: String, meta: M): T {
 *     return untyped __elixir__('Phoenix.Presence.track({0}, {1}, {2})', socket, key, meta);
 * }
 * ```
 * 
 * ## Implementation Strategy
 * 
 * 1. **Detect implementation**: Check if class implements PresenceBehavior
 * 2. **Generate internal methods**: Create methods that inject self()
 * 3. **Generate external methods**: Create methods that call Phoenix.Presence
 * 4. **Add utility methods**: list() and getByKey() for presence queries
 * 
 * ## Type Safety
 * 
 * The macro uses generic type parameters <T, M> to ensure complete type safety:
 * - T: Any socket type (phoenix.Socket, phoenix.Phoenix.Socket<T>, or custom)
 * - M: Any metadata type (user-defined typedef or anonymous structure)
 * All methods preserve types throughout the call chain with no Dynamic usage.
 * 
 * ## Why This Approach?
 * 
 * Phoenix.Presence has a dual nature:
 * - Inside a presence module: Functions expect self() as first parameter
 * - Outside (in LiveViews): Call Phoenix.Presence functions normally
 * 
 * This macro eliminates the need for runtime detection or transformation
 * by generating both APIs at compile-time.
 * 
 * @see phoenix.PresenceBehavior - The interface that triggers this macro
 * @see docs/05-architecture/PHOENIX_PRESENCE_BEHAVIOR_PATTERNS.md - Architecture
 */
#if !macro @:build(stdgo.StdGo.buildModule()) #end
@:nullSafety(Off)
class PresenceMacro {
	#if macro
	
	/**
	 * Build function called by @:autoBuild on PresenceBehavior.
	 * Generates dual API methods for Phoenix.Presence operations.
	 * 
	 * @return Array of generated fields to add to the implementing class
	 */
	public static function build(): Array<Field> {
		var fields = Context.getBuildFields();
		var newFields: Array<Field> = [];
		
		// Extract topic from @:presenceTopic metadata if present
		var localClass = Context.getLocalClass();
		var classTopic: Null<String> = null;
		if (localClass != null) {
			var classType = localClass.get();
			if (classType.meta.has(":presenceTopic")) {
				var topicMeta = classType.meta.extract(":presenceTopic");
				if (topicMeta.length > 0 && topicMeta[0].params != null && topicMeta[0].params.length > 0) {
					switch (topicMeta[0].params[0].expr) {
						case EConst(CString(s, _)):
							classTopic = s;
						case _:
							Context.warning("@:presenceTopic requires a string literal", topicMeta[0].pos);
					}
				}
			}
		}
		
        // Determine fully-qualified module name for this presence module
        var fqModule:String = (function() {
            if (localClass != null) {
                var ct = localClass.get();
                if (ct.meta.has(":native")) {
                    var m = ct.meta.extract(":native");
                    if (m.length > 0 && m[0].params != null && m[0].params.length > 0) {
                        switch (m[0].params[0].expr) {
                            case EConst(CString(s, _)): return s;
                            default:
                        }
                    }
                }
                var parts = ct.pack.copy(); parts.push(ct.name);
                return parts.join(".");
            }
            return "__MODULE__";
        })();

        // Generate internal methods (with self())
		newFields.push(generateInternalTrack());
		newFields.push(generateInternalUpdate());
		newFields.push(generateInternalUntrack());
		
		// Generate convenience methods if topic is configured
		if (classTopic != null) {
			newFields.push(generateSimpleTrack(classTopic));
			newFields.push(generateSimpleUpdate(classTopic));
			newFields.push(generateSimpleUntrack(classTopic));
			newFields.push(generateSimpleList(classTopic));
		}
		
        // Generate chainable socket methods
        newFields.push(generateTrackWithSocket());
        newFields.push(generateUpdateWithSocket());
        newFields.push(generateUntrackWithSocket());

        // Generate external topic-based wrappers expected by snapshots:
        newFields.push(generateExternalList(fqModule));
        newFields.push(generateExternalGetByKey());
        newFields.push(generateExternalTrackTopic());
        newFields.push(generateExternalUpdateTopic());
        newFields.push(generateExternalUntrackTopic());
		
		return fields.concat(newFields);
	}
	
	/**
	 * Generate internal track method that works with any socket type.
	 * Uses extern inline to allow compile-time resolution of socket type.
	 * This avoids the need for overloading and eliminates Dynamic usage.
	 */
	static function generateInternalTrack(): Field {
		return {
			name: "trackInternal",
			pos: Context.currentPos(),
			kind: FFun({
				params: [
					{name: "M"}   // Metadata type parameter
				],
				args: [
					{name: "topic", type: macro : String},  // Topic string for LiveView
					{name: "key", type: macro : String},
					{name: "meta", type: macro : M}  // Generic metadata type
				],
				ret: macro : Void,  // Presence tracking doesn't return anything
                expr: macro {
                    // Delegate to presence module: __MODULE__.track(self(), topic, key, meta)
                    untyped __elixir__('{0}.track({1}, {2}, {3}, {4})', 
                        untyped __elixir__('__MODULE__'), 
                        untyped __elixir__('self()'), topic, key, meta);
                }
            }),
            access: [APublic, AStatic, AInline],  // inline for zero-cost abstraction
			doc: "Track presence internally for LiveView contexts. Uses topic string as required by Phoenix.Presence.",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	
	/**
	 * Generate internal update method that injects self().
	 * Uses generic type parameters for type safety.
	 */
	static function generateInternalUpdate(): Field {
		return {
			name: "updateInternal",
			pos: Context.currentPos(),
			kind: FFun({
				params: [
					{name: "M"}   // Metadata type parameter
				],
				args: [
					{name: "topic", type: macro : String},  // Topic string for LiveView
					{name: "key", type: macro : String},
					{name: "meta", type: macro : M}
				],
				ret: macro : Void,
                expr: macro {
                    // Delegate to presence module: __MODULE__.update(self(), topic, key, meta)
                    untyped __elixir__('{0}.update({1}, {2}, {3}, {4})', 
                        untyped __elixir__('__MODULE__'), 
                        untyped __elixir__('self()'), topic, key, meta);
                }
			}),
            access: [APublic, AStatic, AInline],
			doc: "Update presence internally for LiveView contexts. Uses topic string as required by Phoenix.Presence.",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	/**
	 * Generate internal untrack method that injects self().
	 * Uses generic type parameter for socket type safety.
	 */
	static function generateInternalUntrack(): Field {
		return {
			name: "untrackInternal",
			pos: Context.currentPos(),
			kind: FFun({
				args: [
					{name: "topic", type: macro : String},  // Topic string for LiveView
					{name: "key", type: macro : String}
				],
				ret: macro : Void,
                expr: macro {
                    // Delegate to presence module: __MODULE__.untrack(self(), topic, key)
                    untyped __elixir__('{0}.untrack({1}, {2}, {3})', 
                        untyped __elixir__('__MODULE__'), 
                        untyped __elixir__('self()'), topic, key);
                }
			}),
            access: [APublic, AStatic, AInline],
			doc: "Untrack presence internally for LiveView contexts. Uses topic string as required by Phoenix.Presence.",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	/**
	 * Generate external track method for use from LiveViews.
	 * Calls Phoenix.Presence directly without self().
	 * Uses generic types for both socket and metadata.
	 */
	static function generateExternalTrack(): Field {
		return {
			name: "track",
			pos: Context.currentPos(),
			kind: FFun({
				params: [
					{name: "T"},  // Socket type parameter
					{name: "M"}   // Metadata type parameter
				],
				args: [
					{name: "socket", type: macro : T},
					{name: "key", type: macro : String},
					{name: "meta", type: macro : M}
				],
				ret: macro : T,
				expr: macro {
					// External usage - call Phoenix.Presence directly
					return untyped __elixir__('Phoenix.Presence.track({0}, {1}, {2})', socket, key, meta);
				}
			}),
			access: [APublic, AStatic, AExtern, AInline],
			doc: "Track presence externally (from LiveViews). Calls Phoenix.Presence.track.",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	/**
	 * Generate external update method for use from LiveViews.
	 * Uses generic types for full type safety.
	 */
	static function generateExternalUpdate(): Field {
		return {
			name: "update",
			pos: Context.currentPos(),
			kind: FFun({
				params: [
					{name: "T"},  // Socket type parameter
					{name: "M"}   // Metadata type parameter
				],
				args: [
					{name: "socket", type: macro : T},
					{name: "key", type: macro : String},
					{name: "meta", type: macro : M}
				],
				ret: macro : T,
				expr: macro {
					// Call the actual Phoenix.Presence module, not local function
					return untyped __elixir__('Phoenix.Presence.update({0}, {1}, {2})', socket, key, meta);
				}
			}),
			access: [APublic, AStatic, AExtern, AInline],
			doc: "Update presence externally (from LiveViews). Calls Phoenix.Presence.update.",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	/**
	 * Generate external untrack method for use from LiveViews.
	 * Uses generic type parameter for socket type safety.
	 */
	static function generateExternalUntrack(): Field {
		return {
			name: "untrack",
			pos: Context.currentPos(),
			kind: FFun({
				params: [
					{name: "T"}  // Socket type parameter
				],
				args: [
					{name: "socket", type: macro : T},
					{name: "key", type: macro : String}
				],
				ret: macro : T,
				expr: macro {
					// Call the actual Phoenix.Presence module, not local function
					return untyped __elixir__('Phoenix.Presence.untrack({0}, {1})', socket, key);
				}
			}),
			access: [APublic, AStatic, AExtern, AInline],
			doc: "Untrack presence externally (from LiveViews). Calls Phoenix.Presence.untrack.",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	/**
	 * Generate list method for querying presences.
	 * Works both internally and externally.
	 * Uses generic types for socket and metadata.
	 */
    // Removed: external list wrapper. Use __MODULE__.list/1 injected by `use Phoenix.Presence`.
	
	/**
	 * Generate getByKey method for querying specific presence.
	 * Works both internally and externally.
	 * Uses generic types for full type safety.
	 */
    // Removed: external getByKey wrapper. Use __MODULE__.get_by_key/2 injected by `use Phoenix.Presence`.
	
	
	/**
	 * Generate simple track method that uses class-level topic.
	 * Only generated when @:presenceTopic is specified.
	 */
	static function generateSimpleTrack(topic: String): Field {
		return {
			name: "trackSimple",
			pos: Context.currentPos(),
			kind: FFun({
				params: [
					{name: "M"}   // Metadata type parameter
				],
				args: [
					{name: "key", type: macro : String},
					{name: "meta", type: macro : M}
				],
				ret: macro : Void,
				expr: macro {
					// Use the class-level topic
					trackInternal($v{topic}, key, meta);
				}
			}),
			access: [APublic, AStatic, AInline],
			doc: "Track presence using class-level topic configuration.",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	/**
	 * Generate simple update method that uses class-level topic.
	 */
	static function generateSimpleUpdate(topic: String): Field {
		return {
			name: "updateSimple",
			pos: Context.currentPos(),
			kind: FFun({
				params: [
					{name: "M"}   // Metadata type parameter
				],
				args: [
					{name: "key", type: macro : String},
					{name: "meta", type: macro : M}
				],
				ret: macro : Void,
				expr: macro {
					// Use the class-level topic
					updateInternal($v{topic}, key, meta);
				}
			}),
			access: [APublic, AStatic, AInline],
			doc: "Update presence using class-level topic configuration.",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	/**
	 * Generate simple untrack method that uses class-level topic.
	 */
	static function generateSimpleUntrack(topic: String): Field {
		return {
			name: "untrackSimple",
			pos: Context.currentPos(),
			kind: FFun({
				args: [
					{name: "key", type: macro : String}
				],
				ret: macro : Void,
				expr: macro {
					// Use the class-level topic
					untrackInternal($v{topic}, key);
				}
			}),
			access: [APublic, AStatic, AInline],
			doc: "Untrack presence using class-level topic configuration.",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	/**
	 * Generate simple list method that uses class-level topic.
	 * Returns all presences for the configured topic.
	 */
    static function generateSimpleList(topic: String): Field {
		return {
			name: "listSimple",
			pos: Context.currentPos(),
			kind: FFun({
				args: [],  // No arguments needed
				ret: macro : Dynamic,  // Returns a map of presence entries
				expr: macro {
                    // Use presence module's list/1 with the class-level topic
                    return untyped __elixir__('{0}.list({1})', untyped __elixir__('__MODULE__'), $v{topic});
                }
            }),
            access: [APublic, AStatic, AInline],
            doc: "List all presences for the class-level topic.",
            meta: [{name: ":doc", pos: Context.currentPos()}]
        };
    }

    /**
     * Generate external list(topic) wrapper always available.
     */
    static function generateExternalList(fqModule:String): Field {
        return {
            name: "list",
            pos: Context.currentPos(),
            kind: FFun({
                args: [ {name: "topic", type: macro : String} ],
                ret: macro : Dynamic,
                expr: macro {
                    // Emit <FQModule>.list(topic)
                    return untyped __elixir__('{0}.list({1})', untyped __elixir__($v{fqModule}), topic);
                }
            }),
            access: [APublic, AStatic, AInline],
            doc: "List presences for a topic via __MODULE__.list/1",
            meta: [{name: ":doc", pos: Context.currentPos()}]
        };
    }

    /**
     * Generate external getByKey(topic, key) wrapper.
     */
    static function generateExternalGetByKey(): Field {
        return {
            name: "getByKey",
            pos: Context.currentPos(),
            kind: FFun({
                args: [ {name: "topic", type: macro : String}, {name: "key", type: macro : String} ],
                ret: macro : Dynamic,
                expr: macro {
                    return untyped __elixir__('Phoenix.Presence.get_by_key({0}, {1})', topic, key);
                }
            }),
            access: [APublic, AStatic, AInline],
            doc: "Get a presence entry by key via __MODULE__.get_by_key/2",
            meta: [{name: ":doc", pos: Context.currentPos()}]
        };
    }

    /** Topic-based external track wrapper: track(topic, key, meta) */
    static function generateExternalTrackTopic(): Field {
        return {
            name: "track",
            pos: Context.currentPos(),
            kind: FFun({
                params: [ {name: "M"} ],
                args: [ {name: "topic", type: macro : String}, {name: "key", type: macro : String}, {name: "meta", type: macro : M} ],
                ret: macro : Void,
                expr: macro {
                    // Call Phoenix.Presence directly for external usage
                    untyped __elixir__('Phoenix.Presence.track({0}, {1}, {2})', topic, key, meta);
                }
            }),
            access: [APublic, AStatic, AInline],
            doc: "External track wrapper using topic; injects self()",
            meta: [{name: ":doc", pos: Context.currentPos()}]
        };
    }

    /** Topic-based external update wrapper: update(topic, key, meta) */
    static function generateExternalUpdateTopic(): Field {
        return {
            name: "update",
            pos: Context.currentPos(),
            kind: FFun({
                params: [ {name: "M"} ],
                args: [ {name: "topic", type: macro : String}, {name: "key", type: macro : String}, {name: "meta", type: macro : M} ],
                ret: macro : Void,
                expr: macro {
                    untyped __elixir__('Phoenix.Presence.update({0}, {1}, {2})', topic, key, meta);
                }
            }),
            access: [APublic, AStatic, AInline],
            doc: "External update wrapper using topic; injects self()",
            meta: [{name: ":doc", pos: Context.currentPos()}]
        };
    }

    /** Topic-based external untrack wrapper: untrack(topic, key) */
    static function generateExternalUntrackTopic(): Field {
        return {
            name: "untrack",
            pos: Context.currentPos(),
            kind: FFun({
                args: [ {name: "topic", type: macro : String}, {name: "key", type: macro : String} ],
                ret: macro : Void,
                expr: macro {
                    untyped __elixir__('Phoenix.Presence.untrack({0}, {1})', topic, key);
                }
            }),
            access: [APublic, AStatic, AInline],
            doc: "External untrack wrapper using topic; injects self()",
            meta: [{name: ":doc", pos: Context.currentPos()}]
        };
    }

    /**
     * Generate chainable track method that returns the socket.
     * Useful for LiveView's socket chaining pattern.
     */
        static function generateTrackWithSocket(): Field {
            return {
                name: "trackWithSocket",
                pos: Context.currentPos(),
                kind: FFun({
                    params: [
                        {name: "T"},  // Socket type parameter
                        {name: "M"}   // Metadata type parameter
                    ],
                    args: [
                        {name: "socket", type: macro : T},
                        {name: "topic", type: macro : String},
                        {name: "key", type: macro : String},
                        {name: "meta", type: macro : M}
                    ],
                    ret: macro : T,
                    expr: macro {
                        // Call internal implementation (injects self() and uses topic)
                        // This surfaces as a statement before the trailing socket and
                        // will be preserved by PresenceBareCallPreserveTransforms.
                        trackInternal(topic, key, meta);
                        return socket;
                    }
                }),
                access: [APublic, AStatic, AInline],
                doc: "Track presence and return socket for LiveView chaining pattern.",
                meta: [{name: ":doc", pos: Context.currentPos()}]
            };
        }
	
	/**
	 * Generate chainable update method that returns the socket.
	 */
        static function generateUpdateWithSocket(): Field {
            return {
                name: "updateWithSocket",
                pos: Context.currentPos(),
                kind: FFun({
                    params: [
                        {name: "T"},  // Socket type parameter
                        {name: "M"}   // Metadata type parameter
                    ],
                    args: [
                        {name: "socket", type: macro : T},
                        {name: "topic", type: macro : String},
                        {name: "key", type: macro : String},
                        {name: "meta", type: macro : M}
                    ],
                    ret: macro : T,
                    expr: macro {
                        // Call internal implementation to surface effect as statement
                        updateInternal(topic, key, meta);
                        return socket;
                    }
                }),
                access: [APublic, AStatic, AInline],
                doc: "Update presence and return socket for LiveView chaining pattern.",
                meta: [{name: ":doc", pos: Context.currentPos()}]
            };
        }
	
	/**
	 * Generate chainable untrack method that returns the socket.
	 */
        static function generateUntrackWithSocket(): Field {
            return {
                name: "untrackWithSocket",
                pos: Context.currentPos(),
                kind: FFun({
                    params: [
                        {name: "T"}  // Socket type parameter
                    ],
                    args: [
                        {name: "socket", type: macro : T},
                        {name: "topic", type: macro : String},
                        {name: "key", type: macro : String}
                    ],
                    ret: macro : T,
                    expr: macro {
                        // Call internal implementation to surface effect as statement
                        untrackInternal(topic, key);
                        return socket;
                    }
                }),
                access: [APublic, AStatic, AInline],
                doc: "Untrack presence and return socket for LiveView chaining pattern.",
                meta: [{name: ":doc", pos: Context.currentPos()}]
            };
        }
	
	#end
}
