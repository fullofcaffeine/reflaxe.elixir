package implementations;

import behaviors.DataProcessor;

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
    private var processingState: Dynamic;
    private var config: Dynamic;
    
    // GenServer callbacks
    public function genserver_init(args: Dynamic): {ok: Dynamic} {
        this.config = args;
        this.processingState = {
            processed_count: 0,
            errors: 0,
            last_processed: null
        };
        return {ok: this.processingState};
    }
    
    // DataProcessor behavior implementation
    public function init(config: Dynamic): {ok: Dynamic, error: String} {
        if (config == null) {
            return {ok: null, error: "Configuration required"};
        }
        return {ok: config, error: ""};
    }
    
    public function process_item(item: Dynamic, state: Dynamic): {result: Dynamic, newState: Dynamic} {
        if (!validate_data(item)) {
            return {
                result: {error: "Invalid data format", item: item},
                newState: state
            };
        }
        
        // Simulate stream processing
        var processed = {
            id: Std.random(1000),
            original: item,
            processed_at: Date.now().getTime(),
            stream_id: "stream_001"
        };
        
        var newState = {
            processed_count: state.processed_count + 1,
            errors: state.errors,
            last_processed: processed
        };
        
        return {result: processed, newState: newState};
    }
    
    public function process_batch(items: Array<Dynamic>, state: Dynamic): {results: Array<Dynamic>, newState: Dynamic} {
        var results = [];
        var currentState = state;
        
        for (item in items) {
            var itemResult = process_item(item, currentState);
            results.push(itemResult.result);
            currentState = itemResult.newState;
        }
        
        return {results: results, newState: currentState};
    }
    
    public function validate_data(data: Dynamic): Bool {
        // Stream processor accepts any non-null data
        return data != null;
    }
    
    public function handle_error(error: Dynamic, context: Dynamic): String {
        trace("Stream processor error: " + error + " in context: " + context);
        return "error_logged_to_stream";
    }
    
    // Optional callbacks implementation
    public function get_stats(): Map<String, Dynamic> {
        var stats = new Map<String, Dynamic>();
        stats.set("type", "stream_processor");
        stats.set("processed_count", processingState.processed_count);
        stats.set("error_count", processingState.errors);
        stats.set("status", "active");
        return stats;
    }
    
    public function cleanup(state: Dynamic): Void {
        trace("Stream processor cleaning up...");
        // Close streams, flush buffers, etc.
    }
}