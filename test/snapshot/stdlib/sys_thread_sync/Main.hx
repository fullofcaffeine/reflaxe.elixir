import sys.thread.FixedThreadPool;
import sys.thread.Lock;
import sys.thread.Mutex;
import sys.thread.Semaphore;
import sys.thread.Thread;

class Main {
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
