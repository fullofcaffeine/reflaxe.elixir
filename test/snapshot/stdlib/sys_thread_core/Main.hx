import sys.thread.Deque;
import sys.thread.EventLoop;
import sys.thread.Thread;
import sys.thread.Tls;

class Main {
	public static function main() {
		var current = Thread.current();
		current.sendMessage("self-message");
		if (Thread.readMessage(false) != "self-message") {
			throw "Thread self message mismatch";
		}
		if (Thread.readMessage(false) != null) {
			throw "Thread non-blocking empty read should return null";
		}

		var deque = new Deque<String>();
		deque.add("tail");
		deque.push("head");
		if (deque.pop(false) != "head" || deque.pop(false) != "tail" || deque.pop(false) != null) {
			throw "Deque order mismatch";
		}

		var mailbox = Thread.current();
		var blockingDeque = new Deque<String>();
		Thread.create(function() {
			blockingDeque.add("from-child");
			mailbox.sendMessage("child-finished");
		});
		if (blockingDeque.pop(true) != "from-child") {
			throw "Deque blocking pop mismatch";
		}
		if (Thread.readMessage(true) != "child-finished") {
			throw "Thread child message mismatch";
		}

		var tls = new Tls<String>();
		tls.value = "main";
		var tlsMailbox = Thread.current();
		Thread.create(function() {
			tls.value = "child";
			tlsMailbox.sendMessage(tls.value);
		});
		if (Thread.readMessage(true) != "child") {
			throw "Tls child value mismatch";
		}
		if (tls.value != "main") {
			throw "Tls main value mismatch";
		}

		var loop = new EventLoop();
		var loopMailbox = Thread.current();
		loop.run(function() {
			loopMailbox.sendMessage("loop-ran");
		});
		switch loop.progress() {
			case Now:
			case other:
				throw 'EventLoop progress should return Now, got $other';
		}
		if (Thread.readMessage(true) != "loop-ran") {
			throw "EventLoop run did not execute callback";
		}
	}
}
