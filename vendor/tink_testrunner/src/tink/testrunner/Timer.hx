package tink.testrunner;

interface Timer {
	function stop():Void;
}

interface TimerManager {
	function schedule(ms:Int, f:Void->Void):Timer;
}

#if ((haxe_ver >= 3.3) || flash || js || openfl)
class HaxeTimer implements Timer {
	
	var timer:haxe.Timer;
	var manager:HaxeTimerManager;
	
	public function new(ms:Int, f:Void->Void, ?timerManager:HaxeTimerManager) {
		this.manager = timerManager;
		timer = haxe.Timer.delay(function() {
			// Call original function
			f();
			// Auto-cleanup after execution
			cleanup();
		}, ms);
	}
	
	public function stop() {
		if(timer != null) {
			timer.stop();
			cleanup();
		}
	}
	
	// CRITICAL FIX: Ensure proper cleanup when timer completes or is stopped
	private function cleanup() {
		if (timer != null) {
			timer = null;
		}
		// Remove from manager's tracking if manager exists
		if (manager != null) {
			manager.removeTimer(this);
		}
	}
}

class HaxeTimerManager implements TimerManager {
	// CRITICAL FIX: Track active timers to prevent cross-suite corruption
	private var activeTimers:Array<HaxeTimer> = [];
	
	public function new() {}
	
	public function schedule(ms:Int, f:Void->Void):Timer {
		var timer = new HaxeTimer(ms, f, this);
		activeTimers.push(timer);
		return timer;
	}
	
	// CRITICAL FIX: Allow timers to remove themselves from tracking
	public function removeTimer(timer:HaxeTimer):Void {
		activeTimers.remove(timer);
	}
	
	// CRITICAL FIX: Add cleanup method for cross-suite timer management
	public function cleanupAllTimers():Void {
		// Stop and clear all active timers to prevent state corruption
		for (timer in activeTimers) {
			try {
				if (timer != null) {
					timer.stop();
				}
			} catch (e:Dynamic) {
				// Ignore errors during cleanup
			}
		}
		activeTimers = [];
	}
}
#end