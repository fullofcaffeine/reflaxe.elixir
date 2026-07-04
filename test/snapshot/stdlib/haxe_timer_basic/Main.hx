import haxe.Timer;
import sys.thread.Thread;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function requireMessage(expected:String):Void {
		var actual = Thread.readMessage(false);
		if (actual != expected)
			throw 'expected $expected, got $actual';
	}

	static function driveTimerOnce():Void {
		var events = Thread.current().events;
		assertThat(events.wait(0.2), "timer event did not become ready");
		events.progress();
	}

	static function main():Void {
		var manual = new Timer(1000);
		manual.run = function() {
			Thread.current().sendMessage("manual-1");
		};
		manual.run();
		requireMessage("manual-1");

		var runRef = manual.run;
		runRef();
		requireMessage("manual-1");

		manual.run = function() {
			Thread.current().sendMessage("manual-2");
		};
		manual.run();
		requireMessage("manual-2");
		manual.stop();

		var repeated = new Timer(1);
		repeated.run = function() {
			Thread.current().sendMessage("tick");
		};
		driveTimerOnce();
		requireMessage("tick");
		driveTimerOnce();
		requireMessage("tick");
		repeated.stop();

		Timer.delay(function() {
			Thread.current().sendMessage("delay");
		}, 1);
		driveTimerOnce();
		requireMessage("delay");

		var start = Timer.stamp();
		Sys.sleep(0.001);
		assertThat(Timer.stamp() >= start, "stamp should be monotonic");
		assertThat(Timer.measure(function() return "ok") == "ok", "measure should return result");
	}
}
