package elixir;

#if (macro || reflaxe_runtime)

/**
 * Elixir atom-like constants for GenServer return tuples
 */
enum ElixirAtom {
    OK;
    STOP;
    REPLY;
    NOREPLY;
    CONTINUE;
    HIBERNATE;
}

/**
 * GenServer extern definitions for Elixir OTP
 * Provides type-safe interfaces for GenServer operations
 * 
 * Maps to Elixir's GenServer module functions with proper type signatures
 */
@:native("GenServer")
extern class GenServer {
    
    // GenServer startup
    @:native("GenServer.start")
    public static function start(module: String, initArg: Dynamic): {_0: String, _1: Dynamic}; // {:ok, pid} | {:error, reason}
    
    @:native("GenServer.start")
    public static function startWithOptions(module: String, initArg: Dynamic, options: Array<Dynamic>): {_0: String, _1: Dynamic};
    
    @:native("GenServer.start_link")
    public static function startLink(module: String, initArg: Dynamic): {_0: String, _1: Dynamic}; // {:ok, pid} | {:error, reason}
    
    @:native("GenServer.start_link")
    public static function startLinkWithOptions(module: String, initArg: Dynamic, options: Array<Dynamic>): {_0: String, _1: Dynamic};
    
    @:native("GenServer.child_spec")
    public static function childSpec(options: Map<String, Dynamic>): Map<String, Dynamic>; // Child spec map
    
    // GenServer communication - synchronous calls
    @:native("GenServer.call")
    public static function call(serverRef: Dynamic, request: Dynamic): Dynamic; // Synchronous call
    
    @:native("GenServer.call")
    public static function callWithTimeout(serverRef: Dynamic, request: Dynamic, timeout: Int): Dynamic;
    
    @:native("GenServer.multi_call")
    public static function multiCall(nodes: Array<String>, name: String, request: Dynamic): {_0: Array<{_0: String, _1: Dynamic}>, _1: Array<String>}; // {replies, bad_nodes}
    
    @:native("GenServer.multi_call")
    public static function multiCallWithTimeout(nodes: Array<String>, name: String, request: Dynamic, timeout: Int): {_0: Array<{_0: String, _1: Dynamic}>, _1: Array<String>};
    
    // GenServer communication - asynchronous casts
    @:native("GenServer.cast")
    public static function sendCast(serverRef: Dynamic, request: Dynamic): String; // Returns :ok
    
    @:native("GenServer.abcast")
    public static function abcast(nodes: Array<String>, name: String, request: Dynamic): String; // Broadcast cast
    
    @:native("GenServer.abcast")
    public static function abcastAll(name: String, request: Dynamic): String; // Broadcast to all nodes
    
    // GenServer information and introspection
    @:native("GenServer.whereis")
    public static function whereis(serverRef: Dynamic): Null<Dynamic>; // Find pid by name
    
    // GenServer lifecycle management
    @:native("GenServer.stop")
    public static function stop(serverRef: Dynamic): String; // Returns :ok
    
    @:native("GenServer.stop")
    public static function stopWithReason(serverRef: Dynamic, reason: Dynamic): String;
    
    @:native("GenServer.stop")
    public static function stopWithTimeout(serverRef: Dynamic, reason: Dynamic, timeout: Int): String;
    
    // GenServer reply operations (for use in handle_call)
    @:native("GenServer.reply")
    public static function reply(client: Dynamic, reply: Dynamic): String; // Returns :ok
    
    // GenServer behavior callbacks - these would be implemented by user code
    // but we define them here for reference and type safety
    
    /**
     * Callback signatures for GenServer behavior implementation
     * These are not @:native as they are implemented by the user
     */
    
    // init callback - called when GenServer starts
    public static function init(args: Dynamic): {_0: String, _1: Dynamic}; // {:ok, state} | {:stop, reason}
    
    // handle_call callback - handles synchronous requests
    public static function handleCall(request: Dynamic, from: Dynamic, state: Dynamic): {_0: String, _1: Dynamic, _2: Dynamic}; // {:reply, reply, new_state}
    
    // handle_cast callback - handles asynchronous requests  
    public static function handleCast(request: Dynamic, state: Dynamic): {_0: String, _1: Dynamic}; // {:noreply, new_state}
    
    // handle_info callback - handles other messages
    public static function handleInfo(info: Dynamic, state: Dynamic): {_0: String, _1: Dynamic}; // {:noreply, new_state}
    
    // handle_continue callback - handles continue instructions
    public static function handleContinue(continueData: Dynamic, state: Dynamic): {_0: String, _1: Dynamic}; // {:noreply, new_state}
    
    // terminate callback - cleanup before stopping
    public static function terminate(reason: Dynamic, state: Dynamic): String; // Returns :ok
    
    // code_change callback - handle hot code upgrades
    public static function codeChange(oldVsn: Dynamic, state: Dynamic, extra: Dynamic): {_0: String, _1: Dynamic}; // {:ok, new_state}
    
    // format_status callback - custom status formatting
    public static function formatStatus(opt: Dynamic, statusData: Array<Dynamic>): Dynamic;
    
    // GenServer timeout and hibernation helpers
    @:native("GenServer.timeout") 
    public static var TIMEOUT: Int; // Default timeout constant
    
    // Common return tuple constructors for callbacks - using ElixirAtom enum for type safety
    public static inline var OK: ElixirAtom = ElixirAtom.OK;
    public static inline var STOP: ElixirAtom = ElixirAtom.STOP;  
    public static inline var REPLY: ElixirAtom = ElixirAtom.REPLY;
    public static inline var NOREPLY: ElixirAtom = ElixirAtom.NOREPLY;
    public static inline var CONTINUE: ElixirAtom = ElixirAtom.CONTINUE;
    public static inline var HIBERNATE: ElixirAtom = ElixirAtom.HIBERNATE;
    
    // Helper functions for building return tuples
    public static inline function replyTuple<T, S>(reply: T, state: S): {_0: ElixirAtom, _1: T, _2: S} {
        return {_0: REPLY, _1: reply, _2: state};
    }
    
    public static inline function noreplyTuple<S>(state: S): {_0: ElixirAtom, _1: S} {
        return {_0: NOREPLY, _1: state};
    }
    
    public static inline function stopTuple<R, S>(reason: R, state: S): {_0: ElixirAtom, _1: R, _2: S} {
        return {_0: STOP, _1: reason, _2: state};
    }
    
    public static inline function continueTuple<S, C>(state: S, continue_: C): {_0: ElixirAtom, _1: S, _2: C} {
        return {_0: CONTINUE, _1: state, _2: continue_};
    }
    
    public static inline function hibernateTuple<S>(state: S): {_0: ElixirAtom, _1: S, _2: ElixirAtom} {
        return {_0: NOREPLY, _1: state, _2: HIBERNATE};
    }
}

#end