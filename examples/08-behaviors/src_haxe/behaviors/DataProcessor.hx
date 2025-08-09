package behaviors;

/**
 * Data Processing behavior defining the contract for data transformation modules
 * 
 * This behavior ensures consistent interfaces for data processing operations
 * across different implementation strategies (streaming, batching, real-time)
 */
@:behaviour
class DataProcessor {
    
    /**
     * Initialize the processor with configuration
     */
    @:callback
    public function init(config: Dynamic): {ok: Dynamic, error: String} {
        throw "Callback must be implemented by behavior user";
    }
    
    /**
     * Process a single data item
     */
    @:callback
    public function process_item(item: Dynamic, state: Dynamic): {result: Dynamic, newState: Dynamic} {
        throw "Callback must be implemented by behavior user";
    }
    
    /**
     * Process a batch of items
     */
    @:callback
    public function process_batch(items: Array<Dynamic>, state: Dynamic): {results: Array<Dynamic>, newState: Dynamic} {
        throw "Callback must be implemented by behavior user";
    }
    
    /**
     * Validate data format before processing
     */
    @:callback
    public function validate_data(data: Dynamic): Bool {
        throw "Callback must be implemented by behavior user";
    }
    
    /**
     * Handle processing errors
     */
    @:callback
    public function handle_error(error: Dynamic, context: Dynamic): String {
        throw "Callback must be implemented by behavior user";
    }
    
    /**
     * Optional: Get processing statistics
     */
    @:optional_callback
    public function get_stats(): Map<String, Dynamic> {
        throw "Optional callback can be implemented by behavior user";
    }
    
    /**
     * Optional: Cleanup resources
     */
    @:optional_callback
    public function cleanup(state: Dynamic): Void {
        throw "Optional callback can be implemented by behavior user";
    }
}