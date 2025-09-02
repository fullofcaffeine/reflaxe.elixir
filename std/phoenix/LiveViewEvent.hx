package phoenix;

/**
 * Type-safe Phoenix LiveView event system.
 * 
 * This module provides a foundation for compile-time validated events in Phoenix LiveView,
 * eliminating string-based event names and dynamic parameters.
 * 
 * ## Problem Being Solved
 * 
 * Standard Phoenix LiveView uses string event names and dynamic params:
 * - No compile-time validation of event names
 * - No type safety for event parameters
 * - Manual conversion between different param types
 * - Runtime errors from typos or wrong parameters
 * 
 * ## Solution: Algebraic Data Types for Events
 * 
 * By using Haxe enums (ADTs), we get:
 * - Compile-time validation of all events
 * - Type-safe parameters for each event
 * - Exhaustiveness checking (compiler ensures all events are handled)
 * - IntelliSense/autocomplete support
 * - Zero Dynamic types
 * 
 * ## Usage Pattern
 * 
 * ```haxe
 * // Define your app's events
 * enum MyAppEvent {
 *     CreateItem(params: ItemParams);
 *     DeleteItem(id: Int);
 *     UpdateItem(id: Int, changes: ItemParams);
 * }
 * 
 * // Handle events with pattern matching
 * public static function handle_event(event: MyAppEvent, socket: Socket<MyAssigns>) {
 *     return switch(event) {
 *         case CreateItem(params):
 *             // params is fully typed as ItemParams
 *             var changeset = Item.changeset(new Item(), params);
 *             // ...
 *         case DeleteItem(id):
 *             // id is typed as Int
 *             Repo.delete(Repo.get(Item, id));
 *             // ...
 *         case UpdateItem(id, changes):
 *             // Both id and changes are typed
 *             var item = Repo.get(Item, id);
 *             var changeset = Item.changeset(item, changes);
 *             // ...
 *     }
 * }
 * ```
 * 
 * ## Compiler Integration
 * 
 * The @:liveview macro will generate the necessary Elixir pattern matching:
 * 
 * ```elixir
 * def handle_event("create_item", params, socket) do
 *   # Generated code to call the typed handler
 * end
 * 
 * def handle_event("delete_item", %{"id" => id}, socket) do
 *   # Generated code with proper param extraction
 * end
 * ```
 */

/**
 * Base interface for LiveView event enums.
 * 
 * This is a marker interface that allows the compiler to recognize
 * which enums represent LiveView events and generate appropriate code.
 */
interface ILiveViewEvent {
    // Marker interface - no methods required
}

/**
 * Result type for event handlers.
 * 
 * Phoenix LiveView expects specific return values from handle_event.
 */
enum LiveViewEventResult<TAssigns> {
    /** Continue without reply */
    NoReply(socket: Socket<TAssigns>);
    
    /** Reply with data */
    Reply(data: Dynamic, socket: Socket<TAssigns>);
}

/**
 * Generic Socket type with typed assigns.
 * 
 * @param TAssigns The type of the assigns structure for this LiveView
 */
abstract Socket<TAssigns>(Dynamic) {
    /** The typed assigns for this socket */
    public var assigns(get, never): TAssigns;
    
    inline function get_assigns(): TAssigns {
        return untyped this.assigns;
    }
    
    /**
     * Assign values to the socket.
     * Returns a new socket with updated assigns.
     */
    public function assign(values: Partial<TAssigns>): Socket<TAssigns> {
        return untyped this.assign(values);
    }
    
    /**
     * Put a flash message.
     */
    public function putFlash(kind: String, message: String): Socket<TAssigns> {
        return untyped this.put_flash(kind, message);
    }
    
    /**
     * Push an event to the client.
     */
    public function pushEvent(event: String, payload: Dynamic): Socket<TAssigns> {
        return untyped this.push_event(event, payload);
    }
}

/**
 * Partial type helper for assign operations.
 * 
 * Allows passing only some fields of TAssigns when updating.
 */
typedef Partial<T> = Dynamic; // Will be replaced with proper implementation

/**
 * Compiler helper to generate event name from enum constructor.
 * 
 * Transforms: CreateTodo -> "create_todo"
 * This will be used by the compiler to generate Elixir pattern matching.
 */
class LiveViewEventCompiler {
    /**
     * Convert enum constructor name to Phoenix event name.
     * 
     * @param constructorName The Haxe enum constructor name (e.g., "CreateTodo")
     * @return The Phoenix event name (e.g., "create_todo")
     */
    public static function toEventName(constructorName: String): String {
        // Convert CamelCase to snake_case
        var result = "";
        for (i in 0...constructorName.length) {
            var char = constructorName.charAt(i);
            if (i > 0 && char == char.toUpperCase() && char != char.toLowerCase()) {
                result += "_";
            }
            result += char.toLowerCase();
        }
        return result;
    }
    
    /**
     * Generate Elixir handle_event clause for an event constructor.
     * 
     * This is used by the compiler to generate the pattern matching.
     */
    public static function generateHandleEventClause(
        constructorName: String,
        paramNames: Array<String>,
        paramTypes: Array<String>
    ): String {
        var eventName = toEventName(constructorName);
        
        if (paramNames.length == 0) {
            return 'def handle_event("$eventName", _params, socket)';
        } else if (paramNames.length == 1) {
            return 'def handle_event("$eventName", params, socket)';
        } else {
            var destructuring = paramNames.map(name -> '"$name" => $name').join(", ");
            return 'def handle_event("$eventName", %{$destructuring}, socket)';
        }
    }
}