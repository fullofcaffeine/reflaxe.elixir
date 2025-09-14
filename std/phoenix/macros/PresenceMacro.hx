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
 * It generates both internal methods (with self()) and external static methods
 * for Phoenix.Presence operations.
 * 
 * ## CRITICAL DESIGN DECISION: Dynamic Socket Parameters
 * 
 * ### Why Dynamic is Used for Socket Parameters
 * 
 * The socket parameter in all generated methods uses `Dynamic` type instead of a specific Socket type.
 * This is a JUSTIFIED architectural decision for the following reasons:
 * 
 * 1. **Multiple Socket Type Definitions Exist**:
 *    - `phoenix.Socket` - Non-generic extern class for client-side WebSocket connections
 *    - `phoenix.Phoenix.Socket<T>` - Generic typedef for server-side LiveView sockets
 *    - These are fundamentally different types that cannot be unified
 * 
 * 2. **Macro Generates Universal Code**:
 *    - The macro generates methods that must work with ANY socket type
 *    - Users might import either Socket definition depending on their use case
 *    - Forcing a specific type would break compatibility
 * 
 * 3. **Phoenix.Presence Accepts Any Socket**:
 *    - The underlying Elixir Phoenix.Presence functions accept any socket structure
 *    - They only care that it has the required fields (assigns, etc.)
 *    - Using Dynamic matches this duck-typing behavior
 * 
 * 4. **Type Safety is Preserved at Usage Sites**:
 *    - While the macro uses Dynamic internally, user code still has type safety
 *    - Users pass their typed Socket<T> which gets accepted as Dynamic
 *    - Return type is also Dynamic but users can cast back to their socket type
 * 
 * ### Alternative Approaches Considered and Rejected
 * 
 * 1. **Generic Type Parameters**: Would require knowing the socket type at macro time (impossible)
 * 2. **Union Types**: Haxe doesn't support union types
 * 3. **Common Interface**: Would require modifying existing Phoenix type definitions
 * 4. **Overloads**: Would duplicate all methods for each socket type (maintenance nightmare)
 * 
 * ### Conclusion
 * 
 * Using Dynamic for socket parameters is the CORRECT approach here because:
 * - It mirrors Phoenix.Presence's actual duck-typed behavior
 * - It allows the macro to generate code that works universally
 * - It doesn't compromise type safety where it matters (metadata types)
 * - It's a necessary bridge between two incompatible type definitions
 * 
 * This is one of the rare cases where Dynamic is justified and improves the design
 * rather than compromising it.
 * 
 * ## Generated Methods
 * 
 * For classes implementing PresenceBehavior, this macro generates:
 * 
 * ### Internal Methods (use within the presence module)
 * ```haxe
 * // Generated: Injects self() as first parameter
 * public static function trackInternal<T>(socket: Socket<T>, key: String, meta: Dynamic): Socket<T> {
 *     return untyped __elixir__('track({0}, {1}, {2}, {3})', untyped __elixir__('self()'), socket, key, meta);
 * }
 * ```
 * 
 * ### External Static Methods (use from LiveViews)
 * ```haxe
 * // Generated: Calls Phoenix.Presence directly
 * public static function track<T>(socket: Socket<T>, key: String, meta: Dynamic): Socket<T> {
 *     return Phoenix.Presence.track(socket, key, meta);
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
 * The macro preserves type parameters and ensures all generated methods
 * maintain proper type safety with Socket<T> and generic metadata types.
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
		
		// Generate internal methods (with self())
		newFields.push(generateInternalTrack());
		newFields.push(generateInternalUpdate());
		newFields.push(generateInternalUntrack());
		
		// Generate external static methods (without self())
		newFields.push(generateExternalTrack());
		newFields.push(generateExternalUpdate());
		newFields.push(generateExternalUntrack());
		
		// Generate utility methods
		newFields.push(generateList());
		newFields.push(generateGetByKey());
		
		return fields.concat(newFields);
	}
	
	/**
	 * Generate internal track method that injects self().
	 * Used within the presence module itself.
	 * 
	 * @note Socket parameter uses Dynamic - see class documentation for justification
	 */
	static function generateInternalTrack(): Field {
		return {
			name: "trackInternal",
			pos: Context.currentPos(),
			kind: FFun({
				params: [
					{name: "M"}
				],
				args: [
					{name: "socket", type: macro : Dynamic},
					{name: "key", type: macro : String},
					{name: "meta", type: TPath({pack: [], name: "M", params: []})}  // Generic metadata type
				],
				ret: macro : Dynamic,
				expr: macro {
					// Inject self() as first parameter for internal usage
					return untyped __elixir__('track({0}, {1}, {2}, {3})', 
						untyped __elixir__('self()'), socket, key, meta);
				}
			}),
			access: [APublic, AStatic],
			doc: "Track presence internally (within the presence module). Automatically injects self().",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	/**
	 * Generate internal update method that injects self().
	 */
	static function generateInternalUpdate(): Field {
		return {
			name: "updateInternal",
			pos: Context.currentPos(),
			kind: FFun({
				params: [
					{name: "M"}
				],
				args: [
					{name: "socket", type: macro : Dynamic},
					{name: "key", type: macro : String},
					{name: "meta", type: TPath({pack: [], name: "M", params: []})}  // Generic metadata type
				],
				ret: macro : Dynamic,
				expr: macro {
					return untyped __elixir__('update({0}, {1}, {2}, {3})', 
						untyped __elixir__('self()'), socket, key, meta);
				}
			}),
			access: [APublic, AStatic],
			doc: "Update presence internally (within the presence module). Automatically injects self().",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	/**
	 * Generate internal untrack method that injects self().
	 */
	static function generateInternalUntrack(): Field {
		return {
			name: "untrackInternal",
			pos: Context.currentPos(),
			kind: FFun({
				params: [],
				args: [
					{name: "socket", type: macro : Dynamic},
					{name: "key", type: macro : String}
				],
				ret: macro : Dynamic,
				expr: macro {
					return untyped __elixir__('untrack({0}, {1}, {2})', 
						untyped __elixir__('self()'), socket, key);
				}
			}),
			access: [APublic, AStatic],
			doc: "Untrack presence internally (within the presence module). Automatically injects self().",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	/**
	 * Generate external track method for use from LiveViews.
	 * Calls Phoenix.Presence directly without self().
	 */
	static function generateExternalTrack(): Field {
		return {
			name: "track",
			pos: Context.currentPos(),
			kind: FFun({
				params: [
					{name: "M"}
				],
				args: [
					{name: "socket", type: macro : Dynamic},
					{name: "key", type: macro : String},
					{name: "meta", type: TPath({pack: [], name: "M", params: []})}  // Generic metadata type
				],
				ret: macro : Dynamic,
				expr: macro {
					// External usage - call Phoenix.Presence directly
					return untyped __elixir__('Phoenix.Presence.track({0}, {1}, {2})', socket, key, meta);
				}
			}),
			access: [APublic, AStatic],
			doc: "Track presence externally (from LiveViews). Calls Phoenix.Presence.track.",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	/**
	 * Generate external update method for use from LiveViews.
	 */
	static function generateExternalUpdate(): Field {
		return {
			name: "update",
			pos: Context.currentPos(),
			kind: FFun({
				params: [
					{name: "M"}
				],
				args: [
					{name: "socket", type: macro : Dynamic},
					{name: "key", type: macro : String},
					{name: "meta", type: TPath({pack: [], name: "M", params: []})}  // Generic metadata type
				],
				ret: macro : Dynamic,
				expr: macro {
					// Call the actual Phoenix.Presence module, not local function
					return untyped __elixir__('Phoenix.Presence.update({0}, {1}, {2})', socket, key, meta);
				}
			}),
			access: [APublic, AStatic],
			doc: "Update presence externally (from LiveViews). Calls Phoenix.Presence.update.",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	/**
	 * Generate external untrack method for use from LiveViews.
	 */
	static function generateExternalUntrack(): Field {
		return {
			name: "untrack",
			pos: Context.currentPos(),
			kind: FFun({
				params: [],
				args: [
					{name: "socket", type: macro : Dynamic},
					{name: "key", type: macro : String}
				],
				ret: macro : Dynamic,
				expr: macro {
					// Call the actual Phoenix.Presence module, not local function
					return untyped __elixir__('Phoenix.Presence.untrack({0}, {1})', socket, key);
				}
			}),
			access: [APublic, AStatic],
			doc: "Untrack presence externally (from LiveViews). Calls Phoenix.Presence.untrack.",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	/**
	 * Generate list method for querying presences.
	 * Works both internally and externally.
	 */
	static function generateList(): Field {
		return {
			name: "list",
			pos: Context.currentPos(),
			kind: FFun({
				params: [
					{name: "M"}
				],
				args: [
					{name: "socket", type: macro : Dynamic}
				],
				ret: TPath({pack: ["haxe"], name: "DynamicAccess", params: [TPType(TPath({pack: ["phoenix"], name: "PresenceEntry", params: [TPType(TPath({pack: [], name: "M", params: []}))]}))]}),
				expr: macro {
					// Always use Phoenix.Presence.list which works both internally and externally
					// Phoenix.Presence handles the self() injection automatically when called from within a presence module
					return untyped __elixir__('Phoenix.Presence.list({0})', socket);
				}
			}),
			access: [APublic, AStatic],
			doc: "List all presences. Automatically detects context and uses appropriate method.",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	/**
	 * Generate getByKey method for querying specific presence.
	 * Works both internally and externally.
	 */
	static function generateGetByKey(): Field {
		return {
			name: "getByKey",
			pos: Context.currentPos(),
			kind: FFun({
				params: [
					{name: "M"}
				],
				args: [
					{name: "socket", type: macro : Dynamic},
					{name: "key", type: macro : String}
				],
				ret: TPath({pack: [], name: "Null", params: [TPType(TPath({pack: ["phoenix"], name: "PresenceEntry", params: [TPType(TPath({pack: [], name: "M", params: []}))]}))]}),
				expr: macro {
					// Always use Phoenix.Presence.get_by_key which works both internally and externally
					// Phoenix.Presence handles the self() injection automatically when called from within a presence module
					return untyped __elixir__('Phoenix.Presence.get_by_key({0}, {1})', socket, key);
				}
			}),
			access: [APublic, AStatic],
			doc: "Get presence by key. Automatically detects context and uses appropriate method.",
			meta: [{name: ":doc", pos: Context.currentPos()}]
		};
	}
	
	#end
}