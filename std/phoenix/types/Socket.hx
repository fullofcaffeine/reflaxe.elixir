package phoenix.types;

import elixir.types.Term;
import phoenix.types.Assigns;

/**
 * Type-safe wrapper for Phoenix LiveView Socket
 * 
 * Provides compile-time type checking for LiveView socket operations
 * while maintaining runtime compatibility with Phoenix's socket behavior.
 * 
 * Usage:
 * ```haxe
 * typedef TodoAssigns = {
 *     todos: Array<Todo>,
 *     current_user: User,
 *     filter: String
 * }
 * 
 * function mount(params: Term, session: Term, socket: Socket<TodoAssigns>): Socket<TodoAssigns> {
 *     return socket.assign({
 *         todos: [],
 *         current_user: getCurrentUser(session),
 *         filter: "all"
 *     });
 * }
 * ```
 */

/**
 * LiveView socket transport types
 */
enum SocketTransport {
    WebSocket;
    LongPoll;
}

/**
 * Type-safe LiveView socket wrapper
 */
abstract Socket<TAssigns>(Term) from Term to Term {
    
    /**
     * Create typed socket from an arbitrary term
     */
    public static function fromDynamic<TAssigns>(socket: Term): Socket<TAssigns> {
        return cast socket;
    }
    
    /**
     * Get the underlying term socket
     */
    public function toDynamic(): Term {
        return this;
    }
    
    /**
     * Get socket assigns with type safety
     */
    public function getAssigns(): Assigns<TAssigns> {
        return Assigns.fromDynamic(Reflect.field(this, "assigns"));
    }
    
    /**
     * Get specific assign value
     */
    public function getAssign(key: String): Term {
        var assigns = Reflect.field(this, "assigns");
        return Reflect.field(assigns, key);
    }
    
    /**
     * Check if socket is connected
     */
    public function isConnected(): Bool {
        return Reflect.field(this, "transport_pid") != null;
    }
    
    /**
     * Get socket ID
     */
    public function getId(): String {
        return Reflect.field(this, "id");
    }
    
    /**
     * Get transport type
     */
    public function getTransport(): SocketTransport {
        var transport: Term = Reflect.field(this, "transport");
        // This is a simplified detection - actual implementation would inspect transport details
        return WebSocket;
    }
    
    /**
     * Get endpoint module
     */
    public function getEndpoint(): Term {
        return Reflect.field(this, "endpoint");
    }
    
    /**
     * Get router module
     */
    public function getRouter(): Term {
        return Reflect.field(this, "router");
    }
    
    /**
     * Get view module
     */
    public function getView(): Term {
        return Reflect.field(this, "view");
    }
    
    /**
     * Get changed assigns
     */
    public function getChanged(): Term {
        return Reflect.field(this, "changed");
    }
    
    /**
     * Check if specific assign has changed
     */
    public function hasChanged(key: String): Bool {
        var changed: Term = getChanged();
        return Reflect.hasField(changed, key);
    }
    
    /**
     * Get parent process ID
     */
    public function getParentPid(): Term {
        return Reflect.field(this, "parent_pid");
    }
    
    /**
     * Get root process ID
     */
    public function getRootPid(): Term {
        return Reflect.field(this, "root_pid");
    }
    
    /**
     * Get transport process ID
     */
    public function getTransportPid(): Term {
        return Reflect.field(this, "transport_pid");
    }
}

/**
 * Socket utility functions
 */
class SocketTools {
    /**
     * Check if socket has specific assign
     */
    public static function hasAssign<T>(socket: Socket<T>, key: String): Bool {
        var assigns = socket.getAssigns().toDynamic();
        return Reflect.hasField(assigns, key);
    }
    
    /**
     * Get assign with default value
     */
    public static function getAssignOr<T>(socket: Socket<T>, key: String, defaultValue: Term): Term {
        var assigns = socket.getAssigns().toDynamic();
        return Reflect.hasField(assigns, key) ? Reflect.field(assigns, key) : defaultValue;
    }
    
    /**
     * Check if socket is in a specific state
     */
    public static function isInState<T>(socket: Socket<T>, stateName: String, stateValue: Term): Bool {
        return socket.getAssign(stateName) == stateValue;
    }
    
    /**
     * Extract user from socket assigns (common pattern)
     */
    public static function getCurrentUser<T>(socket: Socket<T>): Term {
        return socket.getAssign("current_user");
    }
    
    /**
     * Extract flash messages from socket assigns
     */
    public static function getFlash<T>(socket: Socket<T>): Term {
        return socket.getAssign("flash");
    }
    
    /**
     * Check if socket has flash messages
     */
    public static function hasFlash<T>(socket: Socket<T>): Bool {
        var flash = getFlash(socket);
        return flash != null && Reflect.fields(flash).length > 0;
    }
}
