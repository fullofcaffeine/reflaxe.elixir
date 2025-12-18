package elixir.types;

import elixir.Kernel;
import elixir.types.Atom;
import elixir.types.Term;

/**
 * Type-safe abstraction for GenServer references
 * 
 * GenServerRef provides a unified way to reference GenServers whether by:
 * - PID (process identifier)
 * - Registered name (atom)
 * - Via tuple for custom registries
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // From a PID
 * var serverRef: GenServerRef = GenServer.start(MyServer, args);
 * 
 * // From a registered name
 * var namedRef: GenServerRef = GenServerRef.fromName("my_server");
 * 
 * // Use with GenServer operations
 * var result = GenServer.call(serverRef, request);
 * GenServer.cast(serverRef, message);
 * ```
 * 
 * ## Implicit Conversions
 * 
 * The @:from metadata enables automatic conversions:
 * ```haxe
 * function doCall(server: GenServerRef, msg: Term): Term {
 *     return GenServer.call(server, msg);
 * }
 * 
 * // All these work automatically:
 * doCall(pid, msg);           // Pid converts to GenServerRef
 * doCall("my_server", msg);   // String converts to GenServerRef
 * doCall(viaRef, msg);        // Via tuple converts to GenServerRef
 * ```
 * 
 * ## Type Safety Benefits
 * 
 * - **Unified API**: Single type for all server reference methods
 * - **Compile-time validation**: Can't pass invalid references
 * - **Zero overhead**: Compiles to native Elixir references
 * - **IntelliSense support**: Full autocomplete for server operations
 */
abstract GenServerRef(Term) from Term to Term {
    /**
     * Create a new GenServerRef from a dynamic value
     * Usually not called directly - use implicit conversions
     */
    public inline function new(ref: Term) {
        this = ref;
    }
    
    /**
     * Convert from a PID to GenServerRef
     * Enables: `var ref: GenServerRef = pid;`
     */
    @:from
    public static inline function fromPid(pid: Pid): GenServerRef {
        return new GenServerRef(pid);
    }
    
    /**
     * Convert from a registered name (atom)
     * Enables: `var ref: GenServerRef = "my_server";` (string literal inferred as Atom)
     */
    @:from
    public static inline function fromName(name: Atom): GenServerRef {
        return new GenServerRef(name);
    }
    
    /**
     * Convert from a via tuple for custom registries
     * Example: `{:via, Registry, {MyRegistry, "key"}}`
     */
    @:from
    public static inline function fromVia(via: {via: String, module: Term, name: Term}): GenServerRef {
        return new GenServerRef(via);
    }
    
    /**
     * Create a global reference for cross-node communication
     * @param name The globally registered name
     */
    public static inline function global(name: Atom): GenServerRef {
        return new GenServerRef(untyped __elixir__('{:global, $name}'));
    }
    
    /**
     * Check if this server is alive
     * Works for both local PIDs and registered names
     */
    public inline function isAlive(): Bool {
        return untyped __elixir__('
            case $this do
                pid when is_pid(pid) -> Process.alive?(pid)
                name when is_atom(name) -> 
                    case Process.whereis(name) do
                        nil -> false
                        pid -> Process.alive?(pid)
                    end
                {:global, name} ->
                    case :global.whereis_name(name) do
                        :undefined -> false
                        pid -> Process.alive?(pid)
                    end
                {:via, module, name} ->
                    case module.whereis_name(name) do
                        :undefined -> false
                        pid -> Process.alive?(pid)
                    end
                _ -> false
            end
        ');
    }
    
    /**
     * Get the PID of this server reference
     * Returns null if the server doesn't exist
     */
    public inline function whereis(): Null<Pid> {
        return untyped __elixir__('
            case $this do
                pid when is_pid(pid) -> pid
                name when is_atom(name) -> Process.whereis(name)
                {:global, name} -> :global.whereis_name(name)
                {:via, module, name} -> module.whereis_name(name)
                _ -> nil
            end
        ');
    }
    
    /**
     * Convert to string representation for debugging
     */
    @:to
    public inline function toString(): String {
        return Kernel.inspect(this);
    }
}
