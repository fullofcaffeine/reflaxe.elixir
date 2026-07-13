package implementations;

import behaviors.RetryPolicy;

/**
 * Behavior implementation with fixed delay and low retry cap.
 */
@:use(RetryPolicy)
class ImmediateRetryPolicy {
	public function new() {}

	public function shouldRetry(attempt:Int, _lastError:String):Bool {
		return attempt < maxAttempts();
	}

	public function nextDelayMs(_attempt:Int):Int {
		return 0;
	}

	public function maxAttempts():Int {
		return 3;
	}
}
