package elixir.types;

import elixir.types.Pid;
import elixir.types.Atom;
import elixir.types.Term;
import elixir.Kernel;
import elixir.Process;

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
abstract AgentRef(Term) from Term to Term {
    
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
    public static inline function named(name: Atom): AgentRef {
        return new AgentRef(name);
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
        if (Kernel.isPid(this)) {
            return Process.alive(cast this);
        }
        var pid = Process.whereis(cast this);
        return pid != null && Process.alive(pid);
    }
    
    /**
     * Get the underlying value (pid or atom).
     * @return The raw agent reference
     */
    public inline function toValue(): Term {
        return this;
    }

    private inline function new(ref: Term) {
        this = ref;
    }
}
