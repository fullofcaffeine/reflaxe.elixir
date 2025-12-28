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

    // DataProcessor behavior implementation
    public function init(config: ProcessorConfig): InitResponse {
        var batchSize = 100;
        if (config != null && config.batchSize != null) batchSize = config.batchSize;

        return {
            ok: {
                processed_count: 0,
                errors: 0,
                batches_processed: 0,
                total_items: 0,
                last_batch_time: 0,
                batch_size: batchSize,
                current_batch: []
            },
            error: ""
        };
    }
    
    public function process_item(item: DataItem, state: ProcessorState): ProcessItemResponse {
        var batchSize = state.batch_size != null ? state.batch_size : 100;
        var currentBatch = state.current_batch != null ? state.current_batch : [];

        if (!validate_data(item)) {
            var newState: ProcessorState = {
                processed_count: state.processed_count,
                errors: state.errors + 1,
                batches_processed: state.batches_processed,
                total_items: state.total_items,
                last_batch_time: state.last_batch_time,
                batch_size: batchSize,
                current_batch: currentBatch
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
        var updatedBatch = currentBatch.copy();
        updatedBatch.push(item);

        // If batch is full, process it to advance state/counters.
        var newState: ProcessorState;
        if (updatedBatch.length >= batchSize) {
            var batchResult = process_batch(updatedBatch, state);
            var batchState = batchResult.newState;
            newState = {
                processed_count: batchState.processed_count,
                errors: batchState.errors,
                batches_processed: batchState.batches_processed,
                total_items: batchState.total_items,
                last_batch_time: batchState.last_batch_time,
                batch_size: batchSize,
                current_batch: []
            };
        } else {
            newState = {
                processed_count: state.processed_count,
                errors: state.errors,
                batches_processed: state.batches_processed,
                total_items: state.total_items,
                last_batch_time: state.last_batch_time,
                batch_size: batchSize,
                current_batch: updatedBatch
            };
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
        var batchSize = state.batch_size != null ? state.batch_size : 100;
        
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
            last_batch_time: startTime,
            batch_size: batchSize,
            current_batch: []
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
