package elixir;

import elixir.types.Result;
import elixir.types.GenServerRef;
import elixir.types.GenServerOption;
import elixir.types.GenServerCallbackResults;
import elixir.types.Pid;

#if (macro || reflaxe_runtime)

/**
 * GenServer extern definitions for Elixir OTP
 * Provides type-safe interfaces for GenServer operations with full generic support
 * 
 * GenServer is a generic server process that maintains state and handles
 * synchronous (call) and asynchronous (cast) requests.
 * 
 * ## Type Parameters
 * - `S`: State type maintained by the GenServer
 * - `Req`: Request type for calls/casts
 * - `Res`: Response type for calls
 * 
 * ## Usage Example
 * ```haxe
 * // Define your state type
 * typedef CounterState = { count: Int }
 * 
 * // Start a GenServer
 * var result = GenServer.start(CounterModule, {count: 0});
 * switch(result) {
 *     case Ok(server):
 *         // Make a synchronous call
 *         var count = GenServer.call(server, "get_count");
 *         // Send an asynchronous cast
 *         GenServer.cast(server, "increment");
 *     case Error(reason):
 *         trace("Failed to start: " + reason);
 * }
 * ```
 * 
 * Maps to Elixir's GenServer module functions with proper type signatures
 */
@:native("GenServer")
extern class GenServer {
    
    // GenServer startup with type-safe results
    @:native("GenServer.start")
    public static function start<S>(module: Dynamic, initArg: S): Result<GenServerRef, String>;
    
    @:native("GenServer.start")
    public static function startWithOptions<S>(module: Dynamic, initArg: S, options: GenServerOptions): Result<GenServerRef, String>;
    
    @:native("GenServer.start_link")
    public static function startLink<S>(module: Dynamic, initArg: S): Result<GenServerRef, String>;
    
    @:native("GenServer.start_link")
    public static function startLinkWithOptions<S>(module: Dynamic, initArg: S, options: GenServerOptions): Result<GenServerRef, String>;
    
    @:native("GenServer.child_spec")
    public static function childSpec(options: Map<String, Dynamic>): Map<String, Dynamic>;
    
    // GenServer communication - synchronous calls with generics
    @:native("GenServer.call")
    public static function call<Req, Res>(serverRef: GenServerRef, request: Req): Res;
    
    @:native("GenServer.call")
    public static function callWithTimeout<Req, Res>(serverRef: GenServerRef, request: Req, timeout: Int): Res;
    
    @:native("GenServer.multi_call")
    public static function multiCall<Req, Res>(nodes: Array<String>, name: String, request: Req): {replies: Array<{node: String, reply: Res}>, badNodes: Array<String>};
    
    @:native("GenServer.multi_call")
    public static function multiCallWithTimeout<Req, Res>(nodes: Array<String>, name: String, request: Req, timeout: Int): {replies: Array<{node: String, reply: Res}>, badNodes: Array<String>};
    
    // GenServer communication - asynchronous casts with generics
    @:native("GenServer.cast")
    public static function cast<Req>(serverRef: GenServerRef, request: Req): Void;
    
    @:native("GenServer.abcast")
    public static function abcast<Req>(nodes: Array<String>, name: String, request: Req): Void;
    
    @:native("GenServer.abcast")
    public static function abcastAll<Req>(name: String, request: Req): Void;
    
    // GenServer information and introspection
    @:native("GenServer.whereis")
    public static function whereis(serverRef: GenServerRef): Null<Pid>;
    
    // GenServer lifecycle management with type-safe reasons
    @:native("GenServer.stop")
    public static function stop(serverRef: GenServerRef): Void;
    
    @:native("GenServer.stop")
    public static function stopWithReason<R>(serverRef: GenServerRef, reason: R): Void;
    
    @:native("GenServer.stop")
    public static function stopWithTimeout<R>(serverRef: GenServerRef, reason: R, timeout: Int): Void;
    
    // GenServer reply operations with generics
    @:native("GenServer.reply")
    public static function reply<R>(from: Dynamic, reply: R): Void;
    
    /**
     * GenServer behavior callbacks - these would be implemented by user code
     * but we define their signatures here for reference and type safety
     * 
     * User implementations should return the appropriate callback result types
     * from GenServerCallbackResults for full type safety.
     */
    
    /**
     * Initialize the GenServer state
     * @param args Initial arguments passed to start/start_link
     * @return InitResult with the initial state or stop reason
     */
    public static function init<S>(args: Dynamic): InitResult<S>;
    
    /**
     * Handle synchronous requests
     * @param request The request from the caller
     * @param from The caller's reference (for delayed replies)
     * @param state Current GenServer state
     * @return HandleCallResult with reply and new state
     */
    public static function handleCall<Req, Res, S>(request: Req, from: Dynamic, state: S): HandleCallResult<Res, S>;
    
    /**
     * Handle asynchronous messages
     * @param request The cast message
     * @param state Current GenServer state
     * @return HandleCastResult with new state
     */
    public static function handleCast<Req, S>(request: Req, state: S): HandleCastResult<S>;
    
    /**
     * Handle other messages (not calls or casts)
     * @param info The message received
     * @param state Current GenServer state
     * @return HandleInfoResult with new state
     */
    public static function handleInfo<S>(info: Dynamic, state: S): HandleInfoResult<S>;
    
    /**
     * Handle continue instructions from previous callbacks
     * @param continueArg The continue argument
     * @param state Current GenServer state
     * @return HandleContinueResult with new state
     */
    public static function handleContinue<S>(continueArg: Dynamic, state: S): HandleContinueResult<S>;
    
    /**
     * Clean up before stopping
     * @param reason The stop reason
     * @param state Final GenServer state
     */
    public static function terminate<S>(reason: Dynamic, state: S): Void;
    
    /**
     * Handle hot code upgrades
     * @param oldVsn Previous version
     * @param state Current state
     * @param extra Extra upgrade data
     * @return Result with new state or error
     */
    public static function codeChange<S>(oldVsn: Dynamic, state: S, extra: Dynamic): Result<S, String>;
    
    /**
     * Format status for debugging
     * @param opt Format option (:normal or :terminate)
     * @param statusData Current status data
     * @return Formatted status
     */
    public static function formatStatus(opt: Dynamic, statusData: Array<Dynamic>): Dynamic;
    
    // Helper constants for common atoms
    @:native("GenServer.timeout")
    public static var TIMEOUT(default, never): Int;
    
    /**
     * Helper function to create an infinite timeout
     * @return The :infinity atom for no timeout
     */
    public static inline function infinity(): Dynamic {
        return untyped __elixir__(':infinity');
    }
    
    /**
     * Helper function to create a normal stop reason
     * @return The :normal atom
     */
    public static inline function normal(): Dynamic {
        return untyped __elixir__(':normal');
    }
    
    /**
     * Helper function to create a shutdown stop reason
     * @return The :shutdown atom
     */
    public static inline function shutdown(): Dynamic {
        return untyped __elixir__(':shutdown');
    }
}

#end