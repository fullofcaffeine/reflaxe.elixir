package elixir;

import elixir.types.AgentRef;
import elixir.types.Result;
import elixir.types.Pid;

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
    
    // Agent startup with type-safe results
    @:native("Agent.start")
    public static function start<T>(fun: Void -> T): Result<AgentRef, String>;
    
    @:native("Agent.start")
    public static function startWithOptions<T>(fun: Void -> T, options: Map<String, Dynamic>): Result<AgentRef, String>;
    
    @:native("Agent.start_link")
    public static function startLink<T>(fun: Void -> T): Result<AgentRef, String>;
    
    @:native("Agent.start_link")
    public static function startLinkWithOptions<T>(fun: Void -> T, options: Map<String, Dynamic>): Result<AgentRef, String>;
    
    @:native("Agent.child_spec")
    public static function childSpec(options: Map<String, Dynamic>): Map<String, Dynamic>;
    
    // Agent state access - synchronous operations with generics
    @:native("Agent.get")
    public static function get<T, R>(agent: AgentRef, fun: T -> R): R;
    
    @:native("Agent.get")
    public static function getWithTimeout<T, R>(agent: AgentRef, fun: T -> R, timeout: Int): R;
    
    @:native("Agent.get_and_update")
    public static function getAndUpdate<T, R>(agent: AgentRef, fun: T -> {_0: R, _1: T}): R;
    
    @:native("Agent.get_and_update")
    public static function getAndUpdateWithTimeout<T, R>(agent: AgentRef, fun: T -> {_0: R, _1: T}, timeout: Int): R;
    
    // Agent state modification - synchronous operations
    @:native("Agent.update")
    public static function update<T>(agent: AgentRef, fun: T -> T): String;
    
    @:native("Agent.update")
    public static function updateWithTimeout<T>(agent: AgentRef, fun: T -> T, timeout: Int): String;
    
    // Agent state modification - asynchronous operations
    @:native("Agent.cast")
    public static function sendCast<T>(agent: AgentRef, fun: T -> T): String;
    
    // Agent lifecycle
    @:native("Agent.stop")
    public static function stop(agent: AgentRef): String;
    
    @:native("Agent.stop")
    public static function stopWithReason<E>(agent: AgentRef, reason: E): String;
    
    @:native("Agent.stop")
    public static function stopWithTimeout<E>(agent: AgentRef, reason: E, timeout: Int): String;
    
    // Agent information and introspection
    @:native("Agent.whereis")
    public static function whereis(name: String): Null<Pid>;
    
    // Common timeout values
    public static inline var TIMEOUT: Int = 5000; // Default timeout
    public static inline var INFINITY: Int = -1;  // Infinite timeout
    
    // Helper functions for common patterns
    public static inline function simpleAgent<T>(initialState: T): Result<AgentRef, String> {
        return startLink(() -> initialState);
    }
    
    public static inline function namedAgent<T>(name: String, initialState: T): Result<AgentRef, String> {
        return startLinkWithOptions(() -> initialState, ["name" => name]);
    }
    
    public static inline function getState<T>(agent: AgentRef): T {
        return get(agent, (state: T) -> state);
    }
    
    public static inline function setState<T>(agent: AgentRef, newState: T): String {
        return update(agent, (_: T) -> newState);
    }
    
    public static inline function updateStateAsync<T>(agent: AgentRef, fun: T -> T): String {
        return sendCast(agent, fun);
    }
    
    // Counter agent helpers (common use case)
    public static inline function counterAgent(initialValue: Int = 0): Result<AgentRef, String> {
        return startLink(() -> initialValue);
    }
    
    public static inline function increment(agent: AgentRef, by: Int = 1): String {
        return update(agent, (count: Int) -> count + by);
    }
    
    public static inline function decrement(agent: AgentRef, by: Int = 1): String {
        return update(agent, (count: Int) -> count - by);
    }
    
    public static inline function getCount(agent: AgentRef): Int {
        return get(agent, (count: Int) -> count);
    }
    
    // Note: Map-based Agent helpers removed due to Haxe Map type limitations in lambdas
    // Users should use the basic Agent.get/update/getAndUpdate functions directly
    // with their own map handling logic
}

#end