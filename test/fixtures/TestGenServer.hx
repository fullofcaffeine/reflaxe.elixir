package;

/**
 * Test GenServer class for compiler validation
 */
@:genserver
class TestGenServer {
    public var state: Dynamic;
    
    public function init(args: Dynamic): Dynamic {
        return {ok: {counter: 0}};
    }
    
    public function handle_call(request: Dynamic, from: Dynamic, state: Dynamic): Dynamic {
        switch(request) {
            case "get_counter":
                return {reply: state.counter, state: state};
            default:
                return {reply: "unknown", state: state};
        }
    }
    
    public function handle_cast(msg: Dynamic, state: Dynamic): Dynamic {
        switch(msg) {
            case "increment":
                state.counter++;
                return {noreply: state};
            default:
                return {noreply: state};
        }
    }
}