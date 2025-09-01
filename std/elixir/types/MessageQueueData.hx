package elixir.types;

/**
 * Type-safe representation of message queue data storage location.
 * 
 * Controls where messages sent to a process are stored in memory.
 * This affects garbage collection behavior and memory usage patterns.
 * 
 * ## Storage Options
 * - `on_heap`: Messages stored directly on process heap (default)
 * - `off_heap`: Messages stored in separate memory area
 * 
 * ## Usage Example
 * ```haxe
 * // Configure process to store messages off heap
 * Process.flag(ProcessFlag.messageQueueData(), MessageQueueData.offHeap());
 * ```
 * 
 * ## Performance Considerations
 * 
 * ### on_heap (default)
 * - Messages are part of process heap
 * - Subject to garbage collection with rest of heap
 * - Better for processes with short-lived messages
 * - Can cause GC pressure with large message queues
 * 
 * ### off_heap
 * - Messages stored separately from process heap
 * - Reduces GC pressure for processes with many messages
 * - Better for processes that accumulate messages
 * - Small overhead for message access
 * 
 * @see Process.flag for setting message queue configuration
 * @see ProcessFlag for other process flags
 */
abstract MessageQueueData(String) from String to String {
    
    /**
     * Store messages on the process heap (default behavior).
     * Messages are garbage collected with the rest of the heap.
     * Best for processes with short-lived or few messages.
     */
    public static inline function onHeap(): MessageQueueData {
        return new MessageQueueData("on_heap");
    }
    
    /**
     * Store messages off the process heap in separate memory.
     * Reduces garbage collection pressure for the process heap.
     * Best for processes that accumulate many messages.
     */
    public static inline function offHeap(): MessageQueueData {
        return new MessageQueueData("off_heap");
    }
    
    @:from
    private static inline function fromString(s: String): MessageQueueData {
        return new MessageQueueData(s);
    }
    
    @:to
    private inline function toString(): String {
        return this;
    }
    
    private inline function new(location: String) {
        this = location;
    }
}