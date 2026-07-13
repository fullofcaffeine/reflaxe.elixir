package quality;

import abstractions.ProcessBoundary;
import haxe.test.Assert;
import haxe.test.ExUnit.TestCase;
import implementations.ExponentialRetryPolicy;
import implementations.ImmediateRetryPolicy;
import implementations.IntCommandRenderable;
import implementations.StringCommandRenderable;

/** Runtime evidence that the abstraction catalog preserves its documented behavior. */
@:exunit
class AbstractionLabRuntimeTest extends TestCase {
	@:test
	function retryPoliciesReturnTheirDocumentedValues() {
		var immediate = new ImmediateRetryPolicy();
		Assert.equals(true, immediate.shouldRetry(2, "failure"));
		Assert.equals(false, immediate.shouldRetry(3, "failure"));
		Assert.equals(0, immediate.nextDelayMs(99));
		Assert.equals(3, immediate.maxAttempts());

		var exponential = new ExponentialRetryPolicy();
		Assert.equals(100, exponential.nextDelayMs(-1));
		Assert.equals(800, exponential.nextDelayMs(3));
		Assert.equals(5, exponential.maxAttempts());
	}

	@:test
	function commandRenderersKeepTheirTypedContracts() {
		var strings = new StringCommandRenderable();
		Assert.equals("run:deploy", strings.renderCommand("deploy"));
		Assert.equals("command(6 chars)", strings.renderSummary("deploy"));

		var integers = new IntCommandRenderable();
		Assert.equals("retry:4", integers.renderCommand(4));
		Assert.equals("retry attempt #4", integers.renderSummary(4));
	}

	@:test
	function processBoundaryUsesRealBeamProcessPrimitives() {
		var current = ProcessBoundary.currentProcessId();
		Assert.equals("pid", ProcessBoundary.termType(current));
		Assert.equals("boolean", ProcessBoundary.termType(true));
		Assert.equals("boolean", ProcessBoundary.termType(false));
		Assert.equals(true, ProcessBoundary.sendIfPid(current, "quality-corpus"));
		Assert.equals(false, ProcessBoundary.sendIfPid("not-a-pid", "ignored"));
	}
}
