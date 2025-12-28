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
    public function init(config: ProcessorConfig): InitResponse {
        throw "Callback must be implemented by behavior user";
    }
    
    /**
     * Process a single data item
     */
    @:callback
    public function process_item(item: DataItem, state: ProcessorState): ProcessItemResponse {
        throw "Callback must be implemented by behavior user";
    }
    
    /**
     * Process a batch of items
     */
    @:callback
    public function process_batch(items: Array<DataItem>, state: ProcessorState): ProcessBatchResponse {
        throw "Callback must be implemented by behavior user";
    }
    
    /**
     * Validate data format before processing
     */
    @:callback
    public function validate_data(data: DataItem): Bool {
        throw "Callback must be implemented by behavior user";
    }
    
    /**
     * Handle processing errors
     */
    @:callback
    public function handle_error(error: String, context: String): String {
        throw "Callback must be implemented by behavior user";
    }
    
    /**
     * Optional: Get processing statistics
     */
    @:optional_callback
    public function get_stats(): ProcessorStats {
        throw "Optional callback can be implemented by behavior user";
    }
    
    /**
     * Optional: Cleanup resources
     */
    @:optional_callback
    public function cleanup(state: ProcessorState): Void {
        throw "Optional callback can be implemented by behavior user";
    }
}

typedef ProcessorConfig = {
    var ?batchSize: Int;
}

typedef DataItem = {
    var id: Int;
    var payload: String;
}

typedef ProcessedItem = {
    var id: Int;
    var original: DataItem;
    var processed_at: Float;
    var ?batch_id: Int;
    var ?stream_id: String;
}

typedef ProcessorState = {
    var processed_count: Int;
    var errors: Int;
    var ?batches_processed: Int;
    var ?total_items: Int;
    var ?last_batch_time: Float;
    var ?last_processed: ProcessedItem;
    // Optional processor-specific state (used by BatchProcessor)
    var ?batch_size: Int;
    var ?current_batch: Array<DataItem>;
}

typedef InitResponse = {
    var ok: ProcessorState;
    var error: String;
}

typedef ProcessItemResponse = {
    var result: ProcessedItem;
    var newState: ProcessorState;
}

typedef ProcessBatchResponse = {
    var results: Array<ProcessedItem>;
    var newState: ProcessorState;
}

typedef ProcessorStats = {
    var type: String;
    var processed_count: Int;
    var error_count: Int;
    var status: String;
}
