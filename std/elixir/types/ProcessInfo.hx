package elixir.types;

import elixir.types.Pid;
import elixir.types.ProcessDictionary;
import elixir.types.MonitorInfo;

/**
 * Type-safe representation of process information
 * 
 * This typedef represents the information returned by Process.info()
 * with properly typed fields for common process attributes.
 * 
 * The generic parameter T allows you to specify the message type if known,
 * otherwise defaults to Dynamic for flexibility.
 * 
 * Usage:
 * ```haxe
 * var info: ProcessInfo<MyMessageType> = Process.info(pid);
 * trace('Memory usage: ${info.memory}');
 * trace('Message queue: ${info.message_queue_len}');
 * 
 * // Or use with Dynamic for unknown message types:
 * var info: ProcessInfo<Dynamic> = Process.info(pid);
 * ```
 */
typedef ProcessInfo<T = Dynamic> = {
    /**
     * Current function being executed
     */
    ?current_function: {module: String, func: String, arity: Int},
    
    /**
     * Dictionary/process dictionary
     */
    ?dictionary: ProcessDictionary,
    
    /**
     * Error handler module
     */
    ?error_handler: String,
    
    /**
     * Process group leader
     */
    ?group_leader: Pid,
    
    /**
     * Heap size in words
     */
    ?heap_size: Int,
    
    /**
     * Initial function that started the process
     */
    ?initial_call: {module: String, func: String, arity: Int},
    
    /**
     * Links to other processes
     */
    ?links: Array<Pid>,
    
    /**
     * Memory usage in bytes
     */
    ?memory: Int,
    
    /**
     * Number of messages in mailbox
     */
    ?message_queue_len: Int,
    
    /**
     * Messages in the mailbox
     */
    ?messages: Array<T>,
    
    /**
     * Minimum heap size
     */
    ?min_heap_size: Int,
    
    /**
     * Minimum binary virtual heap size
     */
    ?min_bin_vheap_size: Int,
    
    /**
     * Monitored by (processes monitoring this one)
     */
    ?monitored_by: Array<Pid>,
    
    /**
     * Monitors (processes this one is monitoring)
     */
    ?monitors: Array<MonitorInfo>,
    
    /**
     * Priority level (low, normal, high, max)
     */
    ?priority: String,
    
    /**
     * Number of reductions executed
     */
    ?reductions: Int,
    
    /**
     * Registered name (if any)
     */
    ?registered_name: String,
    
    /**
     * Stack size in words
     */
    ?stack_size: Int,
    
    /**
     * Process status (running, runnable, waiting, suspended, etc.)
     */
    ?status: String,
    
    /**
     * Suspend count
     */
    ?suspending: Array<{suspender: Pid, count: Int}>,
    
    /**
     * Total heap size in words
     */
    ?total_heap_size: Int,
    
    /**
     * Trap exit flag
     */
    ?trap_exit: Bool
}