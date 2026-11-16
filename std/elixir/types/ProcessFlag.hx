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
 *
 * The value is an atom on the BEAM: `Process.flag/2` rejects strings.
 * `extern` keeps the abstract from emitting a runtime `_Impl_` module.
 */
extern abstract ProcessFlag(Atom) to Atom {
	/**
	 * When set to true, exit signals arriving to this process
	 * are converted to messages {'EXIT', FromPid, Reason}.
	 */
	public static inline function trapExit():ProcessFlag {
		return cast("trap_exit" : Atom);
	}

	/**
	 * Sets the process priority level which affects scheduling.
	 * Value should be a Priority abstract.
	 */
	public static inline function priority():ProcessFlag {
		return cast("priority" : Atom);
	}

	/**
	 * Module used for handling undefined function calls.
	 * Value should be an atom (module name).
	 */
	public static inline function errorHandler():ProcessFlag {
		return cast("error_handler" : Atom);
	}

	/**
	 * Minimum heap size in words for this process.
	 * Value should be a positive integer.
	 */
	public static inline function minHeapSize():ProcessFlag {
		return cast("min_heap_size" : Atom);
	}

	/**
	 * Minimum binary virtual heap size in words.
	 * Value should be a positive integer.
	 */
	public static inline function minBinVHeapSize():ProcessFlag {
		return cast("min_bin_vheap_size" : Atom);
	}

	/**
	 * Maximum heap size configuration.
	 * Value can be an integer or a map with size, kill, and error_logger keys.
	 */
	public static inline function maxHeapSize():ProcessFlag {
		return cast("max_heap_size" : Atom);
	}

	/**
	 * Controls where message queue data is stored.
	 * Value should be "on_heap" or "off_heap".
	 */
	public static inline function messageQueueData():ProcessFlag {
		return cast("message_queue_data" : Atom);
	}

	/**
	 * Number of recent function calls to save for debugging.
	 * Value should be a non-negative integer.
	 */
	public static inline function saveCalls():ProcessFlag {
		return cast("save_calls" : Atom);
	}

	/**
	 * Marks process as containing sensitive data that shouldn't
	 * be logged or included in crash dumps.
	 * Value should be a boolean.
	 */
	public static inline function sensitive():ProcessFlag {
		return cast("sensitive" : Atom);
	}
}
