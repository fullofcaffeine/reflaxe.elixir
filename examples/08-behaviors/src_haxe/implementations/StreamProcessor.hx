package implementations;

import behaviors.DataProcessor;
import behaviors.DataProcessor.DataItem;
import behaviors.DataProcessor.InitResponse;
import behaviors.DataProcessor.ProcessBatchResponse;
import behaviors.DataProcessor.ProcessItemResponse;
import behaviors.DataProcessor.ProcessedItem;
import behaviors.DataProcessor.ProcessorConfig;
import behaviors.DataProcessor.ProcessorState;
import behaviors.DataProcessor.ProcessorStats;

/**
 * Streaming implementation of DataProcessor behavior
 * 
 * Processes data items one by one with low memory footprint
 * Ideal for real-time processing scenarios
 */
@:use(DataProcessor)
@:genserver  
class StreamProcessor {
    
    // GenServer state
    private var processingState: ProcessorState;
    private var config: ProcessorConfig;
    
    // GenServer callbacks
    public function genserver_init(args: ProcessorConfig): {ok: ProcessorState} {
        this.config = args;
        this.processingState = {
            processed_count: 0,
            errors: 0,
            last_processed: null
        };
        return {ok: this.processingState};
    }
    
    // DataProcessor behavior implementation
    public function init(config: ProcessorConfig): InitResponse {
        if (config == null) {
            return {ok: {processed_count: 0, errors: 0}, error: "Configuration required"};
        }
        return {ok: {processed_count: 0, errors: 0}, error: ""};
    }
    
    public function process_item(item: DataItem, state: ProcessorState): ProcessItemResponse {
        if (!validate_data(item)) {
            var newState: ProcessorState = {
                processed_count: state.processed_count,
                errors: state.errors + 1,
                last_processed: state.last_processed
            };
            return {result: {id: item.id, original: item, processed_at: Date.now().getTime()}, newState: newState};
        }
        
        // Simulate stream processing
        var processed: ProcessedItem = {
            id: item.id,
            original: item,
            processed_at: Date.now().getTime(),
            stream_id: "stream_001"
        };
        
        var newState: ProcessorState = {
            processed_count: state.processed_count + 1,
            errors: state.errors,
            last_processed: processed
        };
        
        return {result: processed, newState: newState};
    }
    
    public function process_batch(items: Array<DataItem>, state: ProcessorState): ProcessBatchResponse {
        var results: Array<ProcessedItem> = [];
        var currentState = state;
        
        for (item in items) {
            var itemResult = process_item(item, currentState);
            results.push(itemResult.result);
            currentState = itemResult.newState;
        }
        
        return {results: results, newState: currentState};
    }
    
    public function validate_data(data: DataItem): Bool {
        // Stream processor accepts any non-null data
        return data != null;
    }
    
    public function handle_error(error: String, context: String): String {
        trace("Stream processor error: " + error + " in context: " + context);
        return "error_logged_to_stream";
    }
    
    // Optional callbacks implementation
    public function get_stats(): ProcessorStats {
        return {
            type: "stream_processor",
            processed_count: processingState.processed_count,
            error_count: processingState.errors,
            status: "active"
        };
    }
    
    public function cleanup(state: ProcessorState): Void {
        trace("Stream processor cleaning up...");
        // Close streams, flush buffers, etc.
    }
}
