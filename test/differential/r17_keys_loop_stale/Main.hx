// Differential fixture r17_keys_loop_stale, from the PR #92 review probes (haxe.elixir.codex-p2ms).
// Each loop here uses a map-keys iterator in a way that a loop over the keys list cannot copy:
// the iterator is read again after the loop (to resume it, drain it or pass it on), or the
// loop does not take one key per step. The compiler must leave these loops alone, so they
// fail loudly (THREW) on the BEAM (unsupported: haxe.elixir.codex-tvfb). They must never
// give a silent wrong value: an earlier version dropped `it = Map.keys(n)` and a later
// read saw the older argument `it`.
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

	// Loops inside a closure that writes a captured local or rebinds a captured iterator.
	// A write from a closure to a captured local can be lost (haxe.elixir.codex-rrsr item
	// 5), so inside a closure the compiler keeps to the loops that main rewrote, and these
	// throw as on main instead of giving a wrong value.
	static function closureAssigns(it:Iterator<Int>, n:Map<Int, Int>):String {
		var g = function():Int {
			var a = 0;
			it = n.keys();
			while (it.hasNext()) {
				var x = it.next();
				a += x;
			}
			return a;
		};
		var r = g();
		return r + ":" + drain(it);
	}

	static function closureAssignsFor(it:Iterator<Int>, n:Map<Int, Int>):String {
		var g = function():Int {
			var a = 0;
			it = n.keys();
			for (x in it)
				a += x;
			return a;
		};
		var r = g();
		return r + ":" + drain(it);
	}

	static function captureAccHeldKeys(m:Map<Int, Int>):String {
		var a = 0;
		var g = function():Void {
			var it = m.keys();
			for (x in it)
				a += x;
		};
		g();
		return a + "";
	}

	static function captureAccShadowKeys(m:Map<Int, Int>):String {
		var a = 0;
		var k = 100;
		var g = function():Void {
			for (k in m.keys())
				a += k;
			a += k;
		};
		g();
		return a + "";
	}

	// Raw Elixir after the loop reads the iterator in a form that a tokenizer can miss
	// (a charlist, a sigil, a character literal, a comment, a newline, `it.current`,
	// `1..it`). The raw code is the shape under test: no typed Haxe surface emits it.
	// The compiler cannot parse raw code, so any mention of the iterator's name keeps the
	// loop unchanged, and these throw as on main. On the interpreter the read is
	// `it.hasNext()`.
	static function charlistInterp(it:Iterator<Int>, n:Map<Int, Int>):String {
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a += x;
		}
		var h:Bool = #if elixir untyped __elixir__("'#{is_map(it)}' == 'true'") #else it.hasNext() #end;
		return a + ":" + h;
	}

	static function sigilSquote(it:Iterator<Int>, n:Map<Int, Int>):String {
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a += x;
		}
		var h:Bool = #if elixir untyped __elixir__("~s'#{is_map(it)}' == \"true\"") #else it.hasNext() #end;
		return a + ":" + h;
	}

	static function apostropheSigil(it:Iterator<Int>, n:Map<Int, Int>):String {
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a += x;
		}
		var h:Bool = #if elixir untyped __elixir__("~s(don't) != \"\" and is_map(it)") #else it.hasNext() #end;
		return a + ":" + h;
	}

	static function charQuote(it:Iterator<Int>, n:Map<Int, Int>):String {
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a += x;
		}
		var h:Bool = #if elixir untyped __elixir__("?' == 39 and is_map(it)") #else it.hasNext() #end;
		return a + ":" + h;
	}

	static function charDquote(it:Iterator<Int>, n:Map<Int, Int>):String {
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a += x;
		}
		var h:Bool = #if elixir untyped __elixir__("?\" == 34 and is_map(it)") #else it.hasNext() #end;
		return a + ":" + h;
	}

	static function apostropheComment(it:Iterator<Int>, n:Map<Int, Int>):String {
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a += x;
		}
		var h:Bool = #if elixir untyped __elixir__("(\n# don't drop this\nis_map(it)\n)") #else it.hasNext() #end;
		return a + ":" + h;
	}

	static function newlineParen(it:Iterator<Int>, n:Map<Int, Int>):String {
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a += x;
		}
		var h:Bool = #if elixir untyped __elixir__("(\ny = it\n(1 + 2)\nis_map(y)\n)") #else it.hasNext() #end;
		return a + ":" + h;
	}

	static function itCurrent(it:Iterator<Int>, n:Map<Int, Int>):String {
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a += x;
		}
		var h:Bool = #if elixir untyped __elixir__("it.current == 0") #else it.hasNext() #end;
		return a + ":" + h;
	}

	static function rangeIt(it:Iterator<Int>, n:Map<Int, Int>):String {
		var a = 0;
		it = n.keys();
		while (it.hasNext()) {
			var x = it.next();
			a += x;
		}
		var h:Bool = #if elixir untyped __elixir__("is_function(fn -> 1..it end)") #else it.hasNext() #end;
		return a + ":" + h;
	}

	static function heldCharlistInterp(n:Map<Int, Int>):String {
		var it = n.keys();
		var a = 0;
		for (x in it)
			a += x;
		var h:Bool = #if elixir untyped __elixir__("'#{is_list(it)}' == 'true'") #else it.hasNext() #end;
		return a + ":" + h;
	}

	static function heldCharQuote(n:Map<Int, Int>):String {
		var it = n.keys();
		var a = 0;
		for (x in it)
			a += x;
		var h:Bool = #if elixir untyped __elixir__("?' == 39 and is_list(it)") #else it.hasNext() #end;
		return a + ":" + h;
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
		run("closureAssigns", () -> closureAssigns([100, 200, 300, 400].iterator(), [4 => 1, 5 => 2]));
		run("closureAssignsFor", () -> closureAssignsFor([100, 200, 300, 400].iterator(), [4 => 1, 5 => 2]));
		run("captureAccHeldKeys", () -> captureAccHeldKeys([1 => 10, 2 => 20, 3 => 30]));
		run("captureAccShadowKeys", () -> captureAccShadowKeys([1 => 10, 2 => 20, 3 => 30]));
		run("charlistInterp", () -> charlistInterp([7, 8, 9].iterator(), [4 => 1, 5 => 2]));
		run("sigilSquote", () -> sigilSquote([7, 8, 9].iterator(), [4 => 1, 5 => 2]));
		run("apostropheSigil", () -> apostropheSigil([7, 8, 9].iterator(), [4 => 1, 5 => 2]));
		run("charQuote", () -> charQuote([7, 8, 9].iterator(), [4 => 1, 5 => 2]));
		run("charDquote", () -> charDquote([7, 8, 9].iterator(), [4 => 1, 5 => 2]));
		run("apostropheComment", () -> apostropheComment([7, 8, 9].iterator(), [4 => 1, 5 => 2]));
		run("newlineParen", () -> newlineParen([7, 8, 9].iterator(), [4 => 1, 5 => 2]));
		run("itCurrent", () -> itCurrent([7, 8, 9].iterator(), [4 => 1, 5 => 2]));
		run("rangeIt", () -> rangeIt([7, 8, 9].iterator(), [4 => 1, 5 => 2]));
		run("heldCharlistInterp", () -> heldCharlistInterp([4 => 1, 5 => 2]));
		run("heldCharQuote", () -> heldCharQuote([4 => 1, 5 => 2]));
	}
}
