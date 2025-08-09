package implementations;

import behaviors.DataProcessor;

/**
 * Batch implementation of DataProcessor behavior
 * 
 * Accumulates data and processes in large batches for efficiency
 * Ideal for high-throughput scenarios with periodic processing
 */
@:use(DataProcessor)
class BatchProcessor {
    
    private var batchSize: Int = 100;
    private var currentBatch: Array<Dynamic> = [];
    
    // DataProcessor behavior implementation
    public function init(config: Dynamic): {ok: Dynamic, error: String} {
        if (config != null && config.batchSize != null) {
            this.batchSize = config.batchSize;
        }
        
        return {
            ok: {
                batch_size: this.batchSize,
                mode: "batch_processing",
                created_at: Date.now().getTime()
            },
            error: ""
        };
    }
    
    public function process_item(item: Dynamic, state: Dynamic): {result: Dynamic, newState: Dynamic} {
        if (!validate_data(item)) {
            return {
                result: {error: "Invalid data format", item: item},
                newState: state
            };
        }
        
        // Add to batch instead of processing immediately
        currentBatch.push(item);
        
        var result: Dynamic;
        var newState = state;
        
        if (currentBatch.length >= batchSize) {
            // Process the full batch
            var batchResult = process_batch(currentBatch, state);
            result = {
                type: "batch_completed",
                batch_id: Std.random(10000),
                items_processed: currentBatch.length,
                results: batchResult.results
            };
            
            newState = batchResult.newState;
            currentBatch = []; // Reset batch
        } else {
            // Item queued for batch processing
            result = {
                type: "queued_for_batch",
                queue_position: currentBatch.length,
                batch_size: batchSize
            };
        }
        
        return {result: result, newState: newState};
    }
    
    public function process_batch(items: Array<Dynamic>, state: Dynamic): {results: Array<Dynamic>, newState: Dynamic} {
        var results = [];
        var startTime = Date.now().getTime();
        
        for (item in items) {
            var processed = {
                id: Std.random(1000),
                original: item,
                batch_processed_at: startTime,
                batch_id: Std.random(10000)
            };
            results.push(processed);
        }
        
        var newState = {
            batches_processed: state.batches_processed != null ? state.batches_processed + 1 : 1,
            total_items: state.total_items != null ? state.total_items + items.length : items.length,
            last_batch_time: startTime
        };
        
        return {results: results, newState: newState};
    }
    
    public function validate_data(data: Dynamic): Bool {
        // Batch processor has stricter validation
        if (data == null) return false;
        
        // Require data to have an 'id' field for batch tracking
        return Reflect.hasField(data, "id") || Std.isOfType(data, String);
    }
    
    public function handle_error(error: Dynamic, context: Dynamic): String {
        trace("Batch processor error: " + error);
        trace("Context: " + context);
        
        // Batch processors can retry failed batches
        return "error_queued_for_retry";
    }
    
    // Optional callbacks - BatchProcessor doesn't implement these
    // This tests that optional callbacks are truly optional
}