package behaviors;

/**
 * Behavior contract for retry strategies.
 */
@:behaviour
class RetryPolicy {
	@:callback
	public function shouldRetry(attempt:Int, lastError:String):Bool {
		throw "Callback must be implemented by behavior user";
	}

	@:callback
	public function nextDelayMs(attempt:Int):Int {
		throw "Callback must be implemented by behavior user";
	}

	@:optional_callback
	public function maxAttempts():Int {
		throw "Optional callback can be implemented by behavior user";
	}
}
