package elixir.types;

/**
 * Type-safe options for GenServer.start and GenServer.start_link
 * 
 * Provides compile-time validation of GenServer startup options,
 * ensuring only valid configurations are passed.
 * 
 * ## Usage Example
 * 
 * ```haxe
 * var options: GenServerOptions = {
 *     name: "my_server",
 *     timeout: 5000,
 *     debug: [:trace, :statistics]
 * };
 * 
 * var result = GenServer.startLink(MyServer, args, options);
 * ```
 */
typedef GenServerOptions = {
    /**
     * Register the server with a name
     * Can be a string (converted to atom) or a via tuple
     */
    ?name: Dynamic,
    
    /**
     * Timeout in milliseconds for the init callback
     * Default is 5000ms, use `:infinity` for no timeout
     */
    ?timeout: Dynamic,
    
    /**
     * Debug options for sys module
     * Common values: [:trace, :log, :statistics]
     */
    ?debug: Array<Dynamic>,
    
    /**
     * Options passed to the underlying spawn function
     * Example: [:link, :monitor, {:priority, :high}]
     */
    ?spawn_opt: Array<Dynamic>,
    
    /**
     * Time in milliseconds after which the server will hibernate
     * Helps reduce memory consumption for idle servers
     */
    ?hibernate_after: Int
}

/**
 * Helper class for building GenServer options
 */
class GenServerOptionBuilder {
    /**
     * Create options with a registered name
     */
    public static inline function withName(name: String, ?options: GenServerOptions): GenServerOptions {
        if (options == null) options = {};
        options.name = untyped __elixir__('String.to_atom($name)');
        return options;
    }
    
    /**
     * Create options with a via tuple for custom registry
     */
    public static inline function withVia(module: Dynamic, name: Dynamic, ?options: GenServerOptions): GenServerOptions {
        if (options == null) options = {};
        options.name = untyped __elixir__('{:via, $module, $name}');
        return options;
    }
    
    /**
     * Create options with a global name
     */
    public static inline function withGlobalName(name: String, ?options: GenServerOptions): GenServerOptions {
        if (options == null) options = {};
        options.name = untyped __elixir__('{:global, String.to_atom($name)}');
        return options;
    }
    
    /**
     * Set infinite timeout for init callback
     */
    public static inline function withInfiniteTimeout(?options: GenServerOptions): GenServerOptions {
        if (options == null) options = {};
        options.timeout = untyped __elixir__(':infinity');
        return options;
    }
    
    /**
     * Enable tracing debug mode
     */
    public static inline function withTrace(?options: GenServerOptions): GenServerOptions {
        if (options == null) options = {};
        if (options.debug == null) options.debug = [];
        options.debug.push(untyped __elixir__(':trace'));
        return options;
    }
    
    /**
     * Enable logging debug mode
     */
    public static inline function withLog(?options: GenServerOptions): GenServerOptions {
        if (options == null) options = {};
        if (options.debug == null) options.debug = [];
        options.debug.push(untyped __elixir__(':log'));
        return options;
    }
    
    /**
     * Enable statistics debug mode
     */
    public static inline function withStatistics(?options: GenServerOptions): GenServerOptions {
        if (options == null) options = {};
        if (options.debug == null) options.debug = [];
        options.debug.push(untyped __elixir__(':statistics'));
        return options;
    }
}