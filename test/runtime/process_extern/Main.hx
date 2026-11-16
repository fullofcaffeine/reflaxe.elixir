package;

import elixir.Kernel;
import elixir.Process;
import elixir.types.Atom;
import elixir.types.DemonitorOption;
import elixir.types.SendOption;
import elixir.types.Pid;
import elixir.types.MessageQueueData;
import elixir.types.Priority;
import elixir.types.ProcessFlag;
import elixir.types.Term;

/**
 * Runtime contract for every function of the `elixir.Process` extern.
 *
 * Each extern names a native Elixir or Erlang function. A wrong name still
 * compiles and only fails when the call runs, so this fixture calls every
 * extern function on the BEAM: it spawns, links, monitors, kills, sends,
 * receives, registers, hibernates, and uses timers and the process dictionary.
 * A failed check raises, which fails the runtime smoke run.
 */
class Main {
	static inline var NAME:Atom = "reflaxe_process_extern_main";

	static function check(label:String, condition:Bool):Void {
		if (!condition) {
			Kernel.raise('Process extern contract failed: $label');
		}
	}

	/** Receive the next message, or the atom `reflaxe_receive_timeout` after 1 s. */
	static function receiveNext():Term {
		return untyped __elixir__('receive do message -> message after 1000 -> :reflaxe_receive_timeout end');
	}

	/** Assert that the next message prints as `expected`. */
	static function expectMessage(label:String, expected:String):Void {
		var actual = Kernel.inspect(receiveNext());
		check('$label: expected $expected, got $actual', actual == expected);
	}

	static function waitUntilStopped(pid:Pid):Void {
		var attempts = 0;
		while (Process.alive(pid) && attempts < 100) {
			Process.sleep(2);
			attempts++;
		}
		check("process stops", !Process.alive(pid));
	}

	static function sleeper():Pid {
		return Process.spawn(() -> Process.sleep(5000));
	}

	static function testIdentity(current:Pid):Void {
		check("self is alive", Process.alive(current));
		check("pidFromString parses inspect output", Process.pidFromString(current.toString()) == current);
		check("pidFromString parses the bare form", Process.pidFromString(Kernel.inspect(current).substr(4)) == current);
		var fromString:Pid = Pid.fromString(current.toString());
		check("Pid.fromString parses inspect output", fromString == current);
		check("list contains self", Process.list().indexOf(current) >= 0);
	}

	static function testRegistration(current:Pid):Void {
		check("register returns true", Process.register(current, NAME));
		check("whereis finds the name", Process.whereis(NAME) == current);
		check("registered lists the name", Process.registered().indexOf(NAME) >= 0);
		Process.sendToName(NAME, "by-name");
		expectMessage("sendToName", '"by-name"');
		check("unregister returns true", Process.unregister(NAME));
		check("whereis returns null after unregister", Process.whereis(NAME) == null);
	}

	static function testSend(current:Pid):Void {
		Process.send(current, "hello");
		expectMessage("send", '"hello"');
		Process.sendWithOptions(current, "with-options", [SendOption.NoConnect]);
		expectMessage("sendWithOptions", '"with-options"');
	}

	static function testSpawn(current:Pid):Void {
		var child = sleeper();
		check("spawn starts a process", Process.alive(child));
		check("exit returns true", Process.exit(child, Atom.SHUTDOWN));
		waitUntilStopped(child);

		var byModule = Process.spawnModule("timer", "sleep", [5000]);
		check("spawnModule starts a process", Process.alive(byModule));
		check("kill returns true", Process.kill(byModule));
		waitUntilStopped(byModule);
	}

	/** Runs with trap_exit on, so linked exits arrive as messages. */
	static function testLinks(current:Pid):Void {
		var linked = Process.spawnLink(() -> Process.sleep(5000));
		Process.kill(linked);
		expectMessage("spawnLink exit signal", '{:EXIT, ${Kernel.inspect(linked)}, :killed}');

		var linkedModule = Process.spawnLinkModule("timer", "sleep", [5000]);
		Process.kill(linkedModule);
		expectMessage("spawnLinkModule exit signal", '{:EXIT, ${Kernel.inspect(linkedModule)}, :killed}');

		var child = sleeper();
		check("link returns true", Process.link(child));
		check("unlink returns true", Process.unlink(child));
		Process.kill(child);
		waitUntilStopped(child);
	}

	static function testMonitors():Void {
		var monitored = Process.spawnMonitor(() -> {});
		expectMessage("spawnMonitor down message", '{:DOWN, ${Kernel.inspect(monitored._1)}, :process, ${Kernel.inspect(monitored._0)}, :normal}');

		var monitoredModule = Process.spawnMonitorModule("timer", "sleep", [1]);
		expectMessage("spawnMonitorModule down message",
			'{:DOWN, ${Kernel.inspect(monitoredModule._1)}, :process, ${Kernel.inspect(monitoredModule._0)}, :normal}');

		var child = sleeper();
		var ref = Process.monitor(child);
		check("demonitor returns true", Process.demonitor(ref));
		check("demonitorWithOptions returns true", Process.demonitorWithOptions(Process.monitor(child), [DemonitorOption.Flush]));
		Process.kill(child);
		waitUntilStopped(child);
		expectMessage("demonitor leaves no down message", ":reflaxe_receive_timeout");
	}

	static function testInfo(current:Pid):Void {
		check("info returns data for a live process", Process.info(current) != null);
		var status = Process.infoKey(current, "status");
		check("infoKey returns {key, value}", Kernel.inspect(status) == "{:status, :running}");
		var items = Process.infoKeys(current, [("status" : Atom), ("message_queue_len" : Atom)]);
		check("infoKeys returns one entry per key", items != null && items.length == 2);
	}

	static function testDictionary():Void {
		check("put returns null for a new key", Process.put("pe_key", 1) == null);
		check("getKey reads a value", Process.getKey("pe_key") == 1);
		check("getWithDefault uses the default", Process.getWithDefault("pe_missing", 9) == 9);
		check("get lists the entry", Kernel.inspect(Process.get()).indexOf('{"pe_key", 1}') >= 0);
		check("getKeys lists the key", Process.getKeys().indexOf("pe_key") >= 0);
		check("getKeysForValue finds the key", Process.getKeysForValue(1).indexOf("pe_key") >= 0);
		check("delete returns the old value", Process.delete("pe_key") == 1);
		check("getKey returns null after delete", Process.getKey("pe_key") == null);
	}

	static function testTimers(current:Pid):Void {
		var slow = Process.sendAfter(current, "late", 5000);
		var remaining = Process.readTimer(slow);
		check("readTimer returns remaining time", remaining != null && remaining > 0);
		var cancelled = Process.cancelTimer(slow);
		check("cancelTimer returns remaining time", cancelled != null && cancelled > 0);
		Process.sendAfter(current, "tick", 1);
		expectMessage("sendAfter delivers", '"tick"');
		Process.sleep(1);
	}

	static function testHibernate(current:Pid):Void {
		var sleeperPid = Process.spawn(() -> Process.hibernate("erlang", "send", [current, "woke"]));
		Process.sleep(20);
		Process.send(sleeperPid, "wake");
		expectMessage("hibernate resumes in the given function", '"woke"');
	}

	static function testGroupLeader():Void {
		var leader = Process.groupLeader();
		check("groupLeader returns a live pid", Process.alive(leader));
		var child = sleeper();
		check("setGroupLeader returns true", Process.setGroupLeader(leader, child));
		Process.kill(child);
		waitUntilStopped(child);
	}

	public static function main():Void {
		var current = Process.self();
		testIdentity(current);
		testRegistration(current);
		testSend(current);
		testSpawn(current);
		check("flag returns the old trap_exit value", Process.flag(ProcessFlag.trapExit(), true) == false);
		testLinks(current);
		Process.flag(ProcessFlag.trapExit(), false);
		check("flag sets priority", Process.flag(ProcessFlag.priority(), Priority.low()) == Priority.normal());
		check("flag sets message_queue_data", Process.flag(ProcessFlag.messageQueueData(), MessageQueueData.offHeap()) == MessageQueueData.onHeap());
		testMonitors();
		testInfo(current);
		testDictionary();
		testTimers(current);
		testHibernate(current);
		testGroupLeader();
	}
}
