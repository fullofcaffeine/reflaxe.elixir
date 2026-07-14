package;

import elixir.Agent;
import elixir.Kernel;
import elixir.Process;
import elixir.Task;
import elixir.types.AgentRef;
import elixir.types.Atom;
import elixir.types.Pid;
import haxe.functional.Result;

/**
 * Runtime evidence for the small OTP subset promised for 1.0.
 *
 * This deliberately exercises only typed, local-process APIs whose behavior is
 * part of the stable contract. Custom GenServer callbacks, supervisor restart
 * policy, registries, and distributed OTP remain outside that promise.
 */
class Main {
	static function assertTrue(label:String, condition:Bool):Void {
		if (!condition) {
			Kernel.raise('OTP contract failed: $label');
		}
	}

	static function assertEquals(label:String, expected:Int, actual:Int):Void {
		if (expected != actual) {
			Kernel.raise('OTP contract failed: $label');
		}
	}

	static function waitUntilStopped(pid:Pid):Void {
		var attempts = 0;
		while (Process.alive(pid) && attempts < 50) {
			Process.sleep(2);
			attempts++;
		}
		assertTrue("spawned process stops after an exit signal", !Process.alive(pid));
	}

	static function testLocalProcessLifecycle():Void {
		var current = Process.self();
		assertTrue("Process.self returns a live pid", Process.alive(current));

		var child = Process.spawn(() -> Process.sleep(200));
		assertTrue("Process.spawn starts a live local process", Process.alive(child));
		Process.exit(child, Atom.SHUTDOWN);
		waitUntilStopped(child);
	}

	static function testTaskSuccessAndTimeout():Void {
		var completed = Task.async(() -> 42);
		assertEquals("Task.async and Task.await return the function result", 42, Task.await(completed));

		var slow = Task.async(() -> {
			Process.sleep(200);
			return 7;
		});
		var slowPid = slow.pid();
		var early = Task.yieldWithTimeout(slow, 1);
		assertTrue("Task.yield returns null before a slow task completes", early == null);
		Task.shutdown(slow);
		waitUntilStopped(slowPid);
	}

	static function testAgentStateAndStop():Void {
		var started = Agent.start(() -> 10);
		switch (started) {
			case Ok(agent):
				testStartedAgent(agent);
			case Error(reason):
				Kernel.raise('OTP contract failed: Agent.start returned $reason');
		}
	}

	static function testStartedAgent(agent:AgentRef):Void {
		assertEquals("Agent.get reads initial state", 10, Agent.get(agent, (value:Int) -> value));
		Agent.update(agent, (value:Int) -> value + 5);
		assertEquals("Agent.update changes state", 15, Agent.get(agent, (value:Int) -> value));
		Agent.sendCast(agent, (value:Int) -> value + 2);
		assertEquals("Agent.cast is observed by a later call from the same process", 17, Agent.get(agent, (value:Int) -> value));
		Agent.stop(agent);
		assertTrue("Agent.stop ends the process", !Process.alive(cast agent));
	}

	public static function main():Void {
		testLocalProcessLifecycle();
		testTaskSuccessAndTimeout();
		testAgentStateAndStop();
	}
}
