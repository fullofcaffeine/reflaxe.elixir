package phoenix;

/**
 * Phoenix.Endpoint extern definitions for application endpoints
 * 
 * Endpoints provide the boundary where your application receives HTTP requests
 * and handles PubSub operations. They contain URL generation helpers and
 * broadcast functionality.
 * 
 * @see https://hexdocs.pm/phoenix/Phoenix.Endpoint.html
 */

/**
 * Topic for PubSub operations
 */
typedef Topic = String;

/**
 * Event name for broadcasts
 */
typedef Event = String;

/**
 * Message payload for broadcasts
 */
typedef Message = Dynamic;

/**
 * Subscription options
 */
typedef SubscribeOptions = {
    /**
     * Metadata to associate with subscription
     */
    var ?metadata: Dynamic;
    
    /**
     * Link subscription to calling process
     */
    var ?link: Bool;
};

/**
 * Phoenix.Endpoint functions for HTTP and PubSub operations
 */
@:native("Phoenix.Endpoint")
extern class Endpoint {
    /**
     * Broadcast a message to all nodes in the cluster
     * Returns :ok or {:error, reason}
     * 
     * @param topic PubSub topic to broadcast to
     * @param event Event name for the message
     * @param message Message payload
     */
    @:native("Phoenix.Endpoint.broadcast")
    public static function broadcast(topic: Topic, event: Event, message: Message): Dynamic;
    
    /**
     * Broadcast a message to all nodes, raising on failure
     * Same as broadcast/3 but raises on error
     * 
     * @param topic PubSub topic to broadcast to
     * @param event Event name for the message
     * @param message Message payload
     */
    @:native("Phoenix.Endpoint.broadcast!")
    public static function broadcastUnsafe(topic: Topic, event: Event, message: Message): Dynamic;
    
    /**
     * Broadcast a message only within the current node
     * Returns :ok or {:error, reason}
     * 
     * @param topic PubSub topic to broadcast to
     * @param event Event name for the message
     * @param message Message payload
     */
    @:native("Phoenix.Endpoint.local_broadcast")
    public static function localBroadcast(topic: Topic, event: Event, message: Message): Dynamic;
    
    /**
     * Subscribe the calling process to a PubSub topic
     * Returns :ok or {:error, reason}
     * 
     * @param topic Topic to subscribe to
     * @param opts Subscription options
     */
    @:native("Phoenix.Endpoint.subscribe")
    public static function subscribe(topic: Topic, ?opts: SubscribeOptions): Dynamic;
    
    /**
     * Unsubscribe the calling process from a PubSub topic
     * Returns :ok
     * 
     * @param topic Topic to unsubscribe from
     */
    @:native("Phoenix.Endpoint.unsubscribe")
    public static function unsubscribe(topic: Topic): Dynamic;
    
    /**
     * Generate the endpoint base URL without any path information
     * Returns the base URL as a string
     */
    @:native("Phoenix.Endpoint.url")
    public static function url(): String;
    
    /**
     * Generate path information when routing to this endpoint
     * Returns the path as a string
     * 
     * @param path Path to append to the base path
     */
    @:native("Phoenix.Endpoint.path")
    public static function path(path: String): String;
    
    /**
     * Generate the static URL without any path information
     * Returns the static base URL as a string
     */
    @:native("Phoenix.Endpoint.static_url")
    public static function staticUrl(): String;
    
    /**
     * Generate a route to a static file in priv/static
     * Returns the full static path as a string
     * 
     * @param path Path to the static file
     */
    @:native("Phoenix.Endpoint.static_path")
    public static function staticPath(path: String): String;
}

/**
 * Endpoint configuration helpers
 */
@:native("Phoenix.Endpoint")
extern class EndpointConfig {
    /**
     * Get configuration value for the endpoint
     * 
     * @param key Configuration key to retrieve
     */
    @:native("Phoenix.Endpoint.config")
    public static function config(key: String): Dynamic;
    
    /**
     * Get configuration value with default
     * 
     * @param key Configuration key to retrieve
     * @param defaultValue Default value if key not found
     */
    @:native("Phoenix.Endpoint.config")
    public static function configWithDefault(key: String, defaultValue: Dynamic): Dynamic;
    
    /**
     * Check if endpoint is running in development mode
     */
    public static function isDevelopment(): Bool;
    
    /**
     * Check if endpoint is running in production mode
     */
    public static function isProduction(): Bool;
}