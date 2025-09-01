package elixir.types;

import elixir.types.Pid;

/**
 * Type-safe reference to an Agent process.
 * 
 * An AgentRef can be either a process ID (Pid) or a registered atom name.
 * This abstraction provides type safety when working with Agent references.
 * 
 * ## Usage Example
 * ```haxe
 * // Start an agent and get its reference
 * var result = Agent.start(() -> 0);
 * switch(result) {
 *     case Ok(agent):
 *         Agent.update(agent, x -> x + 1);
 *         var value = Agent.get(agent, x -> x);
 *     case Error(reason):
 *         trace("Failed to start agent: " + reason);
 * }
 * 
 * // Use a named agent
 * var namedAgent = AgentRef.named("my_agent");
 * Agent.get(namedAgent, x -> x);
 * ```
 * 
 * @see Agent for agent operations
 * @see Pid for process identifiers
 */
abstract AgentRef(Dynamic) from Dynamic to Dynamic {
    
    /**
     * Create an AgentRef from a process ID.
     * @param pid The process ID of the agent
     * @return An AgentRef wrapping the pid
     */
    @:from
    public static inline function fromPid(pid: Pid): AgentRef {
        return new AgentRef(pid);
    }
    
    /**
     * Create an AgentRef from a registered atom name.
     * @param name The registered name of the agent
     * @return An AgentRef for the named agent
     */
    public static inline function named(name: String): AgentRef {
        return new AgentRef(untyped __elixir__(':$name'));
    }
    
    /**
     * Convert to Pid if this is a pid-based reference.
     * @return The underlying Pid, or null if this is a named reference
     */
    @:to
    public inline function toPid(): Null<Pid> {
        // In Elixir, we'd check if it's a pid
        return this;
    }
    
    /**
     * Check if this agent is alive.
     * @return True if the agent process is running
     */
    public inline function isAlive(): Bool {
        return untyped __elixir__('Process.alive?($this)');
    }
    
    /**
     * Get the underlying value (pid or atom).
     * @return The raw agent reference
     */
    public inline function toValue(): Dynamic {
        return this;
    }
    
    @:from
    private static inline function fromDynamic(d: Dynamic): AgentRef {
        return new AgentRef(d);
    }
    
    @:to
    private inline function toDynamic(): Dynamic {
        return this;
    }
    
    private inline function new(ref: Dynamic) {
        this = ref;
    }
}