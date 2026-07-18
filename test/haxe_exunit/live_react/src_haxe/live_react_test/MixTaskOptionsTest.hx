package live_react_test;

import haxe.test.Assert;
import haxe.test.ExUnit.TestCase;
import live_react_test.LifecycleApi.LiveReactTaskApi;

/** Option parsing remains sequential because Mix task state is process-global. */
@:exunit
@:native("Mix.Tasks.Haxe.Phoenix.LiveReactTest")
class MixTaskOptionsTest extends TestCase {
	@:test("SSR and conflicting modes are rejected before project discovery")
	function testSsrAndConflictingModesAreRejectedBeforeDiscovery():Void {
		Assert.raisesRuntimeErrorMatching(function():Void {
			LiveReactTaskApi.run(["--ssr"]);
		}, "--ssr is not supported");

		Assert.raisesRuntimeErrorMatching(function():Void {
			LiveReactTaskApi.run(["--check", "--remove"]);
		}, "mutually exclusive");
	}
}
