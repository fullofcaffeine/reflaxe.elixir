// Differential fixture r17_keys_loop_stale, from the PR #92 review probes (haxe.elixir.codex-p2ms).
// Each loop here uses a map-keys iterator in a way that a loop over the keys list cannot copy:
// the iterator is read again after the loop (to resume it, drain it or pass it on), or the
// loop does not take one key per step. The compiler must leave these loops alone, so they
// fail loudly (THREW) on the BEAM. They must never give a silent wrong value: an earlier
// version dropped `it = Map.keys(n)` and a later read saw the older argument `it`.
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r17_keys_loop_stale
class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static function staleParam(it:Iterator<Int>, n:Map<Int, Int>):String {
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a++;
		}
		var b = 0;
		while (it.hasNext()) {
			it.next();
			b++;
		}
		return a + ":" + b;
	}

	static function staleParamFor(it:Iterator<Int>, n:Map<Int, Int>):String {
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a++;
		}
		var b = 0;
		for (y in it)
			b++;
		return a + ":" + b;
	}

	static function staleKeys(m:Map<Int, Int>, n:Map<Int, Int>):String {
		var it = m.keys();
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a++;
		}
		var b = 0;
		for (y in it)
			b++;
		return a + ":" + b;
	}

	static function staleKeysBreak(m:Map<Int, Int>, n:Map<Int, Int>):String {
		var it = m.keys();
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a++;
			if (a == 1)
				break;
		}
		var b = 0;
		for (y in it)
			b++;
		return a + ":" + b;
	}

	// An older local binding with the same name, not an argument.
	static function staleLocal(xs:Array<Int>, n:Map<Int, Int>):String {
		var it:Iterator<Int> = xs.iterator();
		var first = it.next();
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a++;
		}
		var b = 0;
		while (it.hasNext()) {
			it.next();
			b++;
		}
		return first + ":" + a + ":" + b;
	}

	// Find, then resume with the same iterator.
	static function staleResume(it:Iterator<Int>, n:Map<Int, Int>):String {
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a++;
			if (a == 1)
				break;
		}
		var b = 0;
		while (it.hasNext()) {
			it.next();
			b++;
		}
		return a + ":" + b;
	}

	static function drain(it:Iterator<Int>):Int {
		var c = 0;
		while (it.hasNext()) {
			it.next();
			c++;
		}
		return c;
	}

	// The iterator is passed on after the loop.
	static function stalePassedOn(it:Iterator<Int>, n:Map<Int, Int>):String {
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a += x;
		}
		return a + ":" + drain(it);
	}

	// The same-name shape `var g = g.next()`, with an older `g`.
	static function staleSameName(g:Iterator<Int>, n:Map<Int, Int>):String {
		var a = 0;
		g = n.keys();
		while (g.hasNext()) {
			var g = g.next();
			a++;
		}
		var b = 0;
		while (g.hasNext()) {
			g.next();
			b++;
		}
		return a + ":" + b;
	}

	static function staleSameNameZ(z:Iterator<Int>, n:Map<Int, Int>):String {
		var a = 0;
		z = n.keys();
		while (z.hasNext()) {
			var z = z.next();
			a++;
		}
		var b = 0;
		while (z.hasNext()) {
			z.next();
			b++;
		}
		return a + ":" + b;
	}

	// A program-held iterator read after its for loop.
	static function iterUsedAfter(m:Map<Int, Int>):String {
		var it = m.keys();
		var acc = 0;
		for (x in it)
			acc += x;
		return acc + ":" + it.hasNext();
	}

	// Loops that do not take one key per step.
	static function hasNextNoAdvance(m:Map<Int, Int>):Int {
		var cnt = 0;
		var it = m.keys();
		while (it.hasNext()) {
			cnt++;
			if (cnt > 5)
				break;
		}
		return cnt;
	}

	static function hasNextNoAdvanceHeld(m:Map<Int, Int>):Int {
		var it = m.keys();
		var cnt = 0;
		while (it.hasNext()) {
			cnt++;
			if (cnt > 5)
				break;
		}
		return cnt;
	}

	static function rareAdvanceHeld(m:Map<Int, Int>):Int {
		var it = m.keys();
		var cnt = 0;
		while (it.hasNext()) {
			cnt++;
			if (cnt > 100)
				it.next();
			if (cnt > 5)
				break;
		}
		return cnt;
	}

	static function main() {
		run("staleParam", () -> staleParam([7, 8, 9, 10].iterator(), [1 => 10, 2 => 20, 3 => 30]));
		run("staleParamFor", () -> staleParamFor([7, 8, 9, 10].iterator(), [1 => 10, 2 => 20, 3 => 30]));
		run("staleKeys", () -> staleKeys([7 => 1, 8 => 1, 9 => 1, 10 => 1], [1 => 10, 2 => 20, 3 => 30]));
		run("staleKeysBreak", () -> staleKeysBreak([7 => 1, 8 => 1, 9 => 1, 10 => 1], [1 => 10, 2 => 20, 3 => 30]));
		run("staleLocal", () -> staleLocal([7, 8, 9, 10, 11], [1 => 10, 2 => 20, 3 => 30]));
		run("staleResume", () -> staleResume([7, 8, 9, 10].iterator(), [1 => 10, 2 => 20, 3 => 30]));
		run("stalePassedOn", () -> stalePassedOn([7, 8, 9, 10].iterator(), [1 => 10, 2 => 20, 3 => 30]));
		run("staleSameName", () -> staleSameName([7, 8, 9, 10].iterator(), [1 => 10, 2 => 20, 3 => 30]));
		run("staleSameNameZ", () -> staleSameNameZ([7, 8, 9, 10].iterator(), [1 => 10, 2 => 20, 3 => 30]));
		run("iterUsedAfter", () -> iterUsedAfter([1 => 10, 2 => 20, 3 => 30]));
		run("hasNextNoAdvance", () -> hasNextNoAdvance([1 => 10, 2 => 20, 3 => 30]));
		run("hasNextNoAdvanceHeld", () -> hasNextNoAdvanceHeld([1 => 10, 2 => 20, 3 => 30]));
		run("rareAdvanceHeld", () -> rareAdvanceHeld([1 => 10, 2 => 20, 3 => 30]));
	}
}
