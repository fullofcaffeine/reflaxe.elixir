package elixir.types;

/**
 * Type-safe representation of Elixir process flags.
 * 
 * Process flags control various behaviors of a process such as
 * trapping exits, setting priority, or enabling error logging.
 * 
 * ## Usage Example
 * ```haxe
 * // Set process to trap exits
 * var oldValue = Process.flag(ProcessFlag.trapExit(), true);
 * 
 * // Set process priority
 * Process.flag(ProcessFlag.priority(), Priority.high());
 * ```
 * 
 * ## Available Flags
 * - `trap_exit`: When true, exit signals become messages
 * - `priority`: Process scheduling priority (low, normal, high, max)
 * - `error_handler`: Module handling undefined function calls
 * - `min_heap_size`: Minimum heap size in words
 * - `min_bin_vheap_size`: Minimum binary virtual heap size
 * - `max_heap_size`: Maximum heap size configuration
 * - `message_queue_data`: Message queue data storage location
 * - `save_calls`: Number of recent calls to save for debugging
 * - `sensitive`: Mark process as containing sensitive data
 * 
 * @see Process for flag usage
 * @see Priority for priority values
 */
abstract ProcessFlag(String) from String to String {
    
    /**
     * When set to true, exit signals arriving to this process
     * are converted to messages {'EXIT', FromPid, Reason}.
     */
    public static inline function trapExit(): ProcessFlag {
        return new ProcessFlag("trap_exit");
    }
    
    /**
     * Sets the process priority level which affects scheduling.
     * Value should be a Priority abstract.
     */
    public static inline function priority(): ProcessFlag {
        return new ProcessFlag("priority");
    }
    
    /**
     * Module used for handling undefined function calls.
     * Value should be an atom (module name).
     */
    public static inline function errorHandler(): ProcessFlag {
        return new ProcessFlag("error_handler");
    }
    
    /**
     * Minimum heap size in words for this process.
     * Value should be a positive integer.
     */
    public static inline function minHeapSize(): ProcessFlag {
        return new ProcessFlag("min_heap_size");
    }
    
    /**
     * Minimum binary virtual heap size in words.
     * Value should be a positive integer.
     */
    public static inline function minBinVHeapSize(): ProcessFlag {
        return new ProcessFlag("min_bin_vheap_size");
    }
    
    /**
     * Maximum heap size configuration.
     * Value can be an integer or a map with size, kill, and error_logger keys.
     */
    public static inline function maxHeapSize(): ProcessFlag {
        return new ProcessFlag("max_heap_size");
    }
    
    /**
     * Controls where message queue data is stored.
     * Value should be "on_heap" or "off_heap".
     */
    public static inline function messageQueueData(): ProcessFlag {
        return new ProcessFlag("message_queue_data");
    }
    
    /**
     * Number of recent function calls to save for debugging.
     * Value should be a non-negative integer.
     */
    public static inline function saveCalls(): ProcessFlag {
        return new ProcessFlag("save_calls");
    }
    
    /**
     * Marks process as containing sensitive data that shouldn't
     * be logged or included in crash dumps.
     * Value should be a boolean.
     */
    public static inline function sensitive(): ProcessFlag {
        return new ProcessFlag("sensitive");
    }
    
    @:from
    private static inline function fromString(s: String): ProcessFlag {
        return new ProcessFlag(s);
    }
    
    @:to
    private inline function toString(): String {
        return this;
    }
    
    private inline function new(flag: String) {
        this = flag;
    }
}