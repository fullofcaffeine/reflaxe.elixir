package;

/**
 * Basic GenServer test case
 * Tests @:genserver annotation compilation
 */
@:genserver
class CounterServer {
	
	// State structure
	var count: Int;
	
	public function init(args: Dynamic): Dynamic {
		return {ok: {count: 0}};
	}
	
	public function handle_call_get_count(from: Dynamic, state: Dynamic): Dynamic {
		return {reply: state.count, state: state};
	}
	
	public function handle_call_increment(from: Dynamic, state: Dynamic): Dynamic {
		var newState = {count: state.count + 1};
		return {reply: newState.count, state: newState};
	}
	
	public function handle_cast_reset(state: Dynamic): Dynamic {
		return {noreply: {count: 0}};
	}
	
	public function handle_info(msg: Dynamic, state: Dynamic): Dynamic {
		trace('Received info: $msg');
		return {noreply: state};
	}
}