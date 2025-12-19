package implementations;

import behaviors.DataProcessor;
import behaviors.DataProcessor.DataItem;
import behaviors.DataProcessor.InitResponse;
import behaviors.DataProcessor.ProcessBatchResponse;
import behaviors.DataProcessor.ProcessItemResponse;
import behaviors.DataProcessor.ProcessedItem;
import behaviors.DataProcessor.ProcessorConfig;
import behaviors.DataProcessor.ProcessorState;

/**
 * Batch implementation of DataProcessor behavior
 * 
 * Accumulates data and processes in large batches for efficiency
 * Ideal for high-throughput scenarios with periodic processing
 */
@:use(DataProcessor)
class BatchProcessor {
    
    private var batchSize: Int = 100;
    private var currentBatch: Array<DataItem> = [];
    
    // DataProcessor behavior implementation
    public function init(config: ProcessorConfig): InitResponse {
        if (config != null && config.batchSize != null) {
            this.batchSize = config.batchSize;
        }

        return {
            ok: {
                processed_count: 0,
                errors: 0,
                batches_processed: 0,
                total_items: 0,
                last_batch_time: 0
            },
            error: ""
        };
    }
    
    public function process_item(item: DataItem, state: ProcessorState): ProcessItemResponse {
        if (!validate_data(item)) {
            var newState: ProcessorState = {
                processed_count: state.processed_count,
                errors: state.errors + 1,
                batches_processed: state.batches_processed,
                total_items: state.total_items,
                last_batch_time: state.last_batch_time
            };

            return {
                result: {
                    id: item.id,
                    original: item,
                    processed_at: Date.now().getTime(),
                    batch_id: null
                },
                newState: newState
            };
        }
        
        // Add to batch instead of processing immediately
        currentBatch.push(item);

        // If batch is full, process it to advance state/counters.
        var newState = state;
        if (currentBatch.length >= batchSize) {
            var batchResult = process_batch(currentBatch, state);
            newState = batchResult.newState;
            currentBatch = [];
        }

        return {
            result: {
                id: item.id,
                original: item,
                processed_at: Date.now().getTime(),
                batch_id: null
            },
            newState: newState
        };
    }
    
    public function process_batch(items: Array<DataItem>, state: ProcessorState): ProcessBatchResponse {
        var results: Array<ProcessedItem> = [];
        var startTime = Date.now().getTime();
        
        for (item in items) {
            var processed: ProcessedItem = {
                id: item.id,
                original: item,
                processed_at: startTime,
                batch_id: Std.random(10000)
            };
            results.push(processed);
        }
        
        var newState: ProcessorState = {
            processed_count: state.processed_count + items.length,
            errors: state.errors,
            batches_processed: (state.batches_processed != null ? state.batches_processed : 0) + 1,
            total_items: (state.total_items != null ? state.total_items : 0) + items.length,
            last_batch_time: startTime
        };
        
        return {results: results, newState: newState};
    }
    
    public function validate_data(data: DataItem): Bool {
        // Batch processor has stricter validation
        if (data == null) return false;
        
        return data.id > 0 && data.payload != null;
    }
    
    public function handle_error(error: String, context: String): String {
        trace("Batch processor error: " + error);
        trace("Context: " + context);
        
        // Batch processors can retry failed batches
        return "error_queued_for_retry";
    }
    
    // Optional callbacks - BatchProcessor doesn't implement these
    // This tests that optional callbacks are truly optional
}
