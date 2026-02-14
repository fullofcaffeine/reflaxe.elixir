package implementations;

import behaviors.RetryPolicy;

/**
 * Behavior implementation with exponential backoff.
 */
@:use(RetryPolicy)
class ExponentialRetryPolicy {
	public function shouldRetry(attempt:Int, _lastError:String):Bool {
		return attempt < maxAttempts();
	}

	public function nextDelayMs(attempt:Int):Int {
		var boundedAttempt = attempt < 0 ? 0 : attempt;
		return Std.int(Math.pow(2, boundedAttempt) * 100);
	}

	public function maxAttempts():Int {
		return 5;
	}
}
