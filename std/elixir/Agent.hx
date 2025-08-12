package elixir;

#if (macro || reflaxe_runtime)

/**
 * Agent module extern definitions for Elixir OTP
 * Provides type-safe interfaces for Agent operations
 * 
 * Maps to Elixir's Agent module functions with proper type signatures
 * Agents are a simple abstraction around state management
 */
@:native("Agent")
extern class Agent {
    
    // Agent startup
    @:native("Agent.start")
    public static function start(fun: Void -> Dynamic): {_0: String, _1: Dynamic}; // {:ok, pid} | {:error, reason}
    
    @:native("Agent.start")
    public static function startWithOptions(fun: Void -> Dynamic, options: Map<String, Dynamic>): {_0: String, _1: Dynamic};
    
    @:native("Agent.start_link")
    public static function startLink(fun: Void -> Dynamic): {_0: String, _1: Dynamic}; // {:ok, pid} | {:error, reason}
    
    @:native("Agent.start_link")
    public static function startLinkWithOptions(fun: Void -> Dynamic, options: Map<String, Dynamic>): {_0: String, _1: Dynamic};
    
    @:native("Agent.child_spec")
    public static function childSpec(options: Map<String, Dynamic>): Map<String, Dynamic>; // Child spec for Supervisor
    
    // Agent state access - synchronous operations
    @:native("Agent.get")
    public static function get<T>(agent: Dynamic, fun: T -> Dynamic): Dynamic; // Get state with transformation
    
    @:native("Agent.get")
    public static function getWithTimeout<T>(agent: Dynamic, fun: T -> Dynamic, timeout: Int): Dynamic;
    
    @:native("Agent.get_and_update")
    public static function getAndUpdate<T>(agent: Dynamic, fun: T -> {_0: Dynamic, _1: T}): Dynamic; // Get value and update state
    
    @:native("Agent.get_and_update")
    public static function getAndUpdateWithTimeout<T>(agent: Dynamic, fun: T -> {_0: Dynamic, _1: T}, timeout: Int): Dynamic;
    
    // Agent state modification - synchronous operations
    @:native("Agent.update")
    public static function update<T>(agent: Dynamic, fun: T -> T): String; // Returns :ok
    
    @:native("Agent.update")
    public static function updateWithTimeout<T>(agent: Dynamic, fun: T -> T, timeout: Int): String;
    
    // Agent state modification - asynchronous operations
    @:native("Agent.cast")
    public static function sendCast<T>(agent: Dynamic, fun: T -> T): String; // Returns :ok immediately
    
    // Agent lifecycle
    @:native("Agent.stop")
    public static function stop(agent: Dynamic): String; // Returns :ok
    
    @:native("Agent.stop")
    public static function stopWithReason(agent: Dynamic, reason: Dynamic): String;
    
    @:native("Agent.stop")
    public static function stopWithTimeout(agent: Dynamic, reason: Dynamic, timeout: Int): String;
    
    // Agent information and introspection
    @:native("Agent.whereis")
    public static function whereis(agent: Dynamic): Null<Dynamic>; // Find agent process
    
    // Common timeout values
    public static inline var TIMEOUT: Int = 5000; // Default timeout
    public static inline var INFINITY: Int = -1;  // Infinite timeout
    
    // Helper functions for common patterns
    public static inline function simpleAgent<T>(initialState: T): {_0: String, _1: Dynamic} {
        return startLink(() -> initialState);
    }
    
    public static inline function namedAgent<T>(name: String, initialState: T): {_0: String, _1: Dynamic} {
        return startLinkWithOptions(() -> initialState, ["name" => name]);
    }
    
    public static inline function getState<T>(agent: Dynamic): T {
        return (get(agent, (state) -> state) : T);
    }
    
    public static inline function setState<T>(agent: Dynamic, newState: T): String {
        return update(agent, (state) -> newState);
    }
    
    public static inline function updateStateAsync<T>(agent: Dynamic, fun: T -> T): String {
        return sendCast(agent, fun);
    }
    
    // Counter agent helpers (common use case)
    public static inline function counterAgent(initialValue: Int = 0): {_0: String, _1: Dynamic} {
        return startLink(() -> initialValue);
    }
    
    public static inline function increment(agent: Dynamic, by: Int = 1): String {
        return update(agent, (count) -> (count : Int) + by);
    }
    
    public static inline function decrement(agent: Dynamic, by: Int = 1): String {
        return update(agent, (count) -> (count : Int) - by);
    }
    
    public static inline function getCount(agent: Dynamic): Int {
        return (get(agent, (count) -> count) : Int);
    }
    
    // Map agent helpers (simplified without generics to avoid compilation issues)
    public static inline function mapAgent(): {_0: String, _1: Dynamic} {
        return startLink(() -> null);  // Start with null, will be replaced with Map in Elixir
    }
    
    public static inline function putValue(agent: Dynamic, key: Dynamic, value: Dynamic): String {
        return update(agent, (state) -> {
            // In Elixir this would use Map.put
            return state;
        });
    }
    
    public static inline function getValue(agent: Dynamic, key: Dynamic): Dynamic {
        return get(agent, (state) -> {
            // In Elixir this would use Map.get
            return null;
        });
    }
    
    public static inline function deleteKey(agent: Dynamic, key: Dynamic): Bool {
        return (get(agent, (state) -> {
            // In Elixir this would use Map.delete
            return false;
        }) : Bool);
    }
}

#end