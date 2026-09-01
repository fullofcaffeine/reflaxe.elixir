import sys.thread.FixedThreadPool;
import sys.thread.Condition;
import sys.thread.Lock;
import sys.thread.Mutex;
import sys.thread.Semaphore;
import sys.thread.Thread;

class Main {
	static function requireLock(lock:Lock, message:String):Void {
		if (!lock.wait(2)) {
			throw message;
		}
	}

	static function testConditionSignal():Void {
		var condition = new Condition();
		var ready = new Lock();
		var resumed = new Lock();
		var allowFinalRelease = new Lock();
		var done = new Lock();

		Thread.create(function() {
			condition.acquire();
			condition.acquire();
			ready.release();
			condition.wait();
			condition.release();
			resumed.release();
			allowFinalRelease.wait();
			condition.release();
			done.release();
		});

		requireLock(ready, "Condition waiter did not acquire the mutex");
		condition.acquire();
		condition.signal();
		if (resumed.wait(0)) {
			throw "Condition waiter resumed before the signaling owner released the mutex";
		}
		condition.release();

		requireLock(resumed, "Condition signal did not resume the waiter");
		if (condition.tryAcquire()) {
			throw "Condition wait did not restore the recursive mutex hold count";
		}
		allowFinalRelease.release();
		requireLock(done, "Condition waiter did not release its restored mutex holds");
		if (!condition.tryAcquire()) {
			throw "Condition mutex stayed locked after the waiter released every hold";
		}
		condition.release();
	}

	static function testConditionBroadcast():Void {
		var condition = new Condition();
		var ready = new Lock();
		var done = new Lock();

		for (_ in 0...3) {
			Thread.create(function() {
				condition.acquire();
				ready.release();
				condition.wait();
				condition.release();
				done.release();
			});
		}

		requireLock(ready, "First Condition broadcast waiter did not start");
		requireLock(ready, "Second Condition broadcast waiter did not start");
		requireLock(ready, "Third Condition broadcast waiter did not start");
		condition.acquire();
		condition.signal();
		if (done.wait(0)) {
			throw "Condition signal waiter resumed before mutex release";
		}
		condition.release();
		requireLock(done, "Condition signal did not resume one waiter");
		if (done.wait(0)) {
			throw "Condition signal resumed more than one waiter";
		}

		condition.acquire();
		condition.broadcast();
		if (done.wait(0)) {
			throw "Condition broadcast waiter resumed before mutex release";
		}
		condition.release();
		requireLock(done, "Condition broadcast did not resume the first remaining waiter");
		requireLock(done, "Condition broadcast did not resume the second remaining waiter");
	}

	public static function main() {
		var lock = new Lock();
		if (lock.wait(0)) {
			throw "new Lock should not be released";
		}
		lock.release();
		if (!lock.wait(0)) {
			throw "released Lock should allow one waiter";
		}

		var mutex = new Mutex();
		mutex.acquire();
		mutex.acquire();
		if (!mutex.tryAcquire()) {
			throw "Mutex should be re-entrant for owner";
		}
		mutex.release();
		mutex.release();
		mutex.release();

		var semaphore = new Semaphore(1);
		if (!semaphore.tryAcquire()) {
			throw "Semaphore first acquire failed";
		}
		if (semaphore.tryAcquire(0)) {
			throw "Semaphore second acquire should time out";
		}
		semaphore.release();
		semaphore.acquire();
		semaphore.release();

		testConditionSignal();
		testConditionBroadcast();

		var done = new Lock();
		var pool = new FixedThreadPool(2);
		pool.run(function() {
			Thread.current().sendMessage("pool-local");
			done.release();
		});
		if (!done.wait(1)) {
			throw "FixedThreadPool task did not run";
		}
		pool.shutdown();
		if (!pool.isShutdown) {
			throw "FixedThreadPool shutdown flag mismatch";
		}
	}
}
