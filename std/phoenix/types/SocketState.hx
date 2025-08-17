package phoenix.types;

import phoenix.types.Assigns;

/**
 * Type-safe wrapper for Phoenix LiveView socket state
 * 
 * Provides compile-time type checking for socket operations while maintaining
 * runtime compatibility with Phoenix LiveView's socket structure.
 * 
 * Usage:
 * ```haxe
 * typedef MyLiveViewState = {
 *     todos: Array<Todo>,
 *     filter: TodoFilter,
 *     loading: Bool
 * }
 * 
 * function handle_event(event: String, params: Dynamic, socket: LiveViewSocket<MyLiveViewState>): LiveViewSocket<MyLiveViewState> {
 *     return switch (event) {
 *         case "add_todo":
 *             var newTodos = socket.assigns.todos.concat([new Todo(params.title)]);
 *             socket.assign("todos", newTodos);
 *         case _: socket;
 *     };
 * }
 * ```
 * 
 * @see documentation/guides/TYPE_SAFE_LIVEVIEW.md - Complete usage guide
 */
abstract LiveViewSocket<T>(Dynamic) from Dynamic to Dynamic {
    
    /**
     * Create typed socket from a Dynamic value
     * Used when receiving socket from Phoenix
     * 
     * @param value Raw socket from Phoenix
     * @return LiveViewSocket<T> Type-safe wrapper
     */
    public static function fromDynamic<T>(value: Dynamic): LiveViewSocket<T> {
        return cast value;
    }
    
    /**
     * Get the underlying Dynamic value
     * Use when passing to Phoenix functions that expect Dynamic
     * 
     * @return Dynamic Raw socket for Phoenix compatibility
     */
    public function toDynamic(): Dynamic {
        return this;
    }
    
    /**
     * Get typed assigns from socket
     * Provides type-safe access to socket assigns
     * 
     * @return Assigns<T> Type-safe assigns wrapper
     */
    public function getAssigns(): Assigns<T> {
        return Assigns.fromDynamic(Reflect.field(this, "assigns"));
    }
    
    /**
     * Type-safe assign operation
     * Assigns a single value to the socket with compile-time type checking
     * 
     * @param key Field name in assigns structure
     * @param value Value to assign (type checked against T)
     * @return LiveViewSocket<T> Updated socket
     */
    public function assign<K, V>(key: String, value: V): LiveViewSocket<T> {
        // In Elixir, this compiles to: Phoenix.LiveView.assign(socket, key, value)
        return cast untyped __elixir__("Phoenix.LiveView.assign(~w{socket}, ~w{key}, ~w{value})", this, key, value);
    }
    
    /**
     * Bulk assign operation
     * Assigns multiple values at once
     * 
     * @param assigns Map of key-value pairs to assign
     * @return LiveViewSocket<T> Updated socket
     */
    public function assignMultiple(assigns: Dynamic): LiveViewSocket<T> {
        // In Elixir, this compiles to: Phoenix.LiveView.assign(socket, assigns)
        return cast untyped __elixir__("Phoenix.LiveView.assign(~w{socket}, ~w{assigns})", this, assigns);
    }
    
    /**
     * Update an assign value with a function
     * Type-safe way to modify existing assigns
     * 
     * @param key Field name to update
     * @param updater Function that transforms the current value
     * @return LiveViewSocket<T> Updated socket
     */
    public function update<K, V>(key: String, updater: V -> V): LiveViewSocket<T> {
        // In Elixir, this compiles to: Phoenix.LiveView.update(socket, key, updater)
        return cast untyped __elixir__("Phoenix.LiveView.update(~w{socket}, ~w{key}, ~w{updater})", this, key, updater);
    }
    
    /**
     * Socket navigation operations
     */
    
    /**
     * Push a LiveView patch (client-side navigation)
     * Updates URL without full page reload
     * 
     * @param to Path to navigate to
     * @return LiveViewSocket<T> Updated socket
     */
    public function pushPatch(to: String): LiveViewSocket<T> {
        return cast untyped __elixir__("Phoenix.LiveView.push_patch(~w{socket}, to: ~w{to})", this, to);
    }
    
    /**
     * Push a LiveView redirect (server-side redirect)
     * Performs full page navigation
     * 
     * @param to Path to redirect to
     * @return LiveViewSocket<T> Updated socket
     */
    public function pushRedirect(to: String): LiveViewSocket<T> {
        return cast untyped __elixir__("Phoenix.LiveView.push_redirect(~w{socket}, to: ~w{to})", this, to);
    }
    
    /**
     * Flash message operations
     */
    
    /**
     * Put a flash message
     * Shows temporary messages to users
     * 
     * @param type Flash message type (info, error, success, warning)
     * @param message Message content
     * @return LiveViewSocket<T> Updated socket
     */
    public function putFlash(type: String, message: String): LiveViewSocket<T> {
        return cast untyped __elixir__("Phoenix.LiveView.put_flash(~w{socket}, ~w{type}, ~w{message})", this, type, message);
    }
    
    /**
     * Clear flash messages
     * Removes flash messages from socket
     * 
     * @param type Optional specific type to clear, or all if null
     * @return LiveViewSocket<T> Updated socket
     */
    public function clearFlash(?type: String): LiveViewSocket<T> {
        if (type != null) {
            return cast untyped __elixir__("Phoenix.LiveView.clear_flash(~w{socket}, ~w{type})", this, type);
        } else {
            return cast untyped __elixir__("Phoenix.LiveView.clear_flash(~w{socket})", this);
        }
    }
    
    /**
     * Socket state inspection
     */
    
    /**
     * Check if socket is connected
     * True for live connections, false for static renders
     * 
     * @return Bool Connection status
     */
    public function isConnected(): Bool {
        return Reflect.field(this, "connected");
    }
    
    /**
     * Get socket ID
     * Unique identifier for this socket session
     * 
     * @return String Socket ID
     */
    public function getId(): String {
        return Reflect.field(this, "id");
    }
    
    /**
     * Get transport PID
     * Process ID for the socket transport
     * 
     * @return Dynamic Transport PID
     */
    public function getTransportPid(): Dynamic {
        return Reflect.field(this, "transport_pid");
    }
    
    /**
     * Get endpoint module
     * The Phoenix endpoint handling this socket
     * 
     * @return Dynamic Endpoint module
     */
    public function getEndpoint(): Dynamic {
        return Reflect.field(this, "endpoint");
    }
    
    /**
     * Get view module
     * The LiveView module for this socket
     * 
     * @return Dynamic View module
     */
    public function getView(): Dynamic {
        return Reflect.field(this, "view");
    }
    
    /**
     * Advanced socket operations
     */
    
    /**
     * Subscribe to PubSub topic
     * Listen for real-time updates
     * 
     * @param topic PubSub topic to subscribe to
     * @return LiveViewSocket<T> Socket (subscription is side effect)
     */
    public function subscribe(topic: String): LiveViewSocket<T> {
        untyped __elixir__("Phoenix.PubSub.subscribe(:todo_app_pubsub, ~w{topic})", topic);
        return cast this;
    }
    
    /**
     * Unsubscribe from PubSub topic
     * Stop listening for updates
     * 
     * @param topic PubSub topic to unsubscribe from
     * @return LiveViewSocket<T> Socket (unsubscription is side effect)
     */
    public function unsubscribe(topic: String): LiveViewSocket<T> {
        untyped __elixir__("Phoenix.PubSub.unsubscribe(:todo_app_pubsub, ~w{topic})", topic);
        return cast this;
    }
    
    /**
     * Broadcast to PubSub topic
     * Send messages to other subscribers
     * 
     * @param topic PubSub topic to broadcast to
     * @param message Message to broadcast
     * @return LiveViewSocket<T> Socket (broadcast is side effect)
     */
    public function broadcast(topic: String, message: Dynamic): LiveViewSocket<T> {
        untyped __elixir__("Phoenix.PubSub.broadcast(:todo_app_pubsub, ~w{topic}, ~w{message})", topic, message);
        return cast this;
    }
}

/**
 * Common socket state types for typical Phoenix LiveView applications
 */

/**
 * Basic LiveView state
 * Minimal state for simple LiveViews
 */
typedef BasicLiveViewState = {
    ?loading: Bool,
    ?error: String
}

/**
 * User-aware LiveView state
 * For LiveViews that need current user context
 */
typedef UserAwareLiveViewState = {
    current_user: Dynamic,  // TODO: Replace with typed User
    ?loading: Bool,
    ?error: String
}

/**
 * Form-based LiveView state
 * For LiveViews with form handling
 */
typedef FormLiveViewState = {
    changeset: Dynamic,  // TODO: Replace with typed Changeset<T>
    ?loading: Bool,
    ?error: String,
    ?success: String
}