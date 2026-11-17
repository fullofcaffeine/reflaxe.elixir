// Differential fixture r19_loop_branch_assign, for haxe.elixir.codex-g4xy and haxe.elixir.codex-3qab
// (review probes y10 reassignIf, p2ms probes2, and PR #91 round 3 g01 and g05).
// A loop body writes a local that the loop does not carry to the next iteration: the loop element
// itself, or a local declared in the body (often in a branch) and then written again. Each write
// must change the value that the rest of this iteration reads.
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r19_loop_branch_assign
class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	// g4xy: the array element is written in an `if`.
	static function arrayElemIf(xs:Array<Int>):Int {
		var acc = 0;
		for (k in xs) {
			if (k > 1)
				k = 0;
			acc += k + 1;
		}
		return acc;
	}

	// g4xy: the array element is written without a branch.
	static function arrayElemWrite(xs:Array<Int>):Int {
		var acc = 0;
		for (k in xs) {
			k = k * 2;
			acc += k;
		}
		return acc;
	}

	// g4xy: compound write in an `if`, and the value 1.
	static function arrayElemIfCompound(xs:Array<Int>):String {
		var acc = 0;
		var ones = 0;
		for (k in xs) {
			var j = k;
			if (k > 1)
				k += 10;
			if (j > 1)
				j = 1;
			acc += k;
			ones += j;
		}
		return acc + ":" + ones;
	}

	// g4xy: the element write in a loop with `break` (Enum.reduce_while).
	static function arrayElemIfBreak(xs:Array<Int>):Int {
		var acc = 0;
		for (k in xs) {
			if (k == 99)
				break;
			if (k > 1)
				k = 0;
			acc += k + 1;
		}
		return acc;
	}

	// g4xy: the written element is copied to an outer local.
	static function arrayElemIfLast(xs:Array<Int>):Int {
		var last = -1;
		for (k in xs) {
			if (k > 1)
				k = 0;
			last = k;
		}
		return last;
	}

	// g4xy: the inner element of a nested loop is written.
	static function nestedElemIf(xs:Array<Int>, ys:Array<Int>):Int {
		var acc = 0;
		for (x in xs)
			for (y in ys) {
				if (y > x)
					y = x;
				acc += y;
			}
		return acc;
	}

	// g4xy: a map key is written in an `if`, with the values 0, 1 and 5.
	static function mapKeyIf(m:Map<Int, Int>):String {
		var zero = 0;
		var one = 0;
		var five = 0;
		for (k in m.keys()) {
			var a = k;
			var b = k;
			if (k > 1)
				k = 0;
			if (a > 1)
				a = 1;
			if (b > 1)
				b = 5;
			zero += k + 1;
			one += a * 3;
			five += b;
		}
		return zero + ":" + one + ":" + five;
	}

	// g4xy: a key-value value is written in an `if`.
	static function keyValueIf(m:Map<Int, Int>):Int {
		var acc = 0;
		for (k => v in m) {
			if (v > 10)
				v = 0;
			acc += v + k;
		}
		return acc;
	}

	// g4xy: a List element is written in an `if`.
	static function listElemIf(l:List<Int>):Int {
		var acc = 0;
		for (k in l) {
			if (k > 1)
				k = 0;
			acc += k + 1;
		}
		return acc;
	}

	// 3qab: a body local copied from the element and then written.
	static function bodyLocal(xs:Array<Int>):Int {
		var sum = 0;
		for (x in xs) {
			var t = x;
			t += 100;
			sum += t;
		}
		return sum;
	}

	// 3qab: the written copy is appended to an array (the append reads the copy, not the element).
	static function pushCopy(xs:Array<Int>):String {
		var out = [];
		for (x in xs) {
			var t = x;
			t += 100;
			out.push(t);
		}
		return out.join(",");
	}

	// 3qab: the same in a branch, and with the second write in an inner `if`.
	static function branchLocal(xs:Array<Int>):String {
		var sum = 0;
		var cond = 0;
		for (x in xs) {
			if (x > 0) {
				var t = x;
				t += 100;
				sum += t;
			}
			if (x > 0) {
				var u = x;
				if (x > 1)
					u += 100;
				cond += u;
			}
		}
		return sum + ":" + cond;
	}

	// 3qab: a range index copied to a local and then written in an `if`.
	static function rangeLocalIf(n:Int):Int {
		var acc = 0;
		for (i in 0...n) {
			var j = i;
			if (j > 1)
				j = 0;
			acc += j + 1;
		}
		return acc;
	}

	// 3qab, probe g01: the branch local shadows a dead outer local.
	static function shadowBranch(xs:Array<Int>):String {
		var t = 1000;
		var sum = 0;
		for (x in xs) {
			if (x > 0) {
				var t = x;
				if (x > 1)
					t += 100;
				sum += t;
			}
		}
		return t + ":" + sum;
	}

	// 3qab, probe g05: two branch locals with the same shadowing name.
	static function twoShadows(xs:Array<Int>):String {
		var t = 1000;
		var out = "";
		for (x in xs) {
			if (x % 2 == 0) {
				var t = x * 10;
				t += 1;
				out += "a" + t;
			}
			if (x > 0) {
				var t = x;
				t += 5;
				out += "b" + t;
			}
		}
		return t + ":" + out;
	}

	// g4xy, no carried local (Enum.each): the element is written, then printed.
	static function eachElemWrite(xs:Array<Int>):Int {
		for (k in xs) {
			k = k * 2;
			Sys.println("  write k" + k);
		}
		return 0;
	}

	// g4xy, no carried local: the element is written in an `if`.
	static function eachElemIfWrite(xs:Array<Int>):Int {
		for (k in xs) {
			if (k > 1)
				k = 0;
			Sys.println("  if k" + k);
		}
		return 0;
	}

	// g4xy, no carried local: the element has the name of an outer local, read after the loop.
	static function eachOuterSame(xs:Array<Int>):Int {
		var k = 100;
		for (k in xs) {
			k = 5;
			Sys.println("  outer k" + k);
		}
		return k;
	}

	// g4xy, no carried local: the element has the name of a parameter, read after the loop.
	static function eachParamSame(k:Int, xs:Array<Int>):Int {
		for (k in xs) {
			k = k + 5;
			Sys.println("  param k" + k);
		}
		return k;
	}

	// g4xy, no carried local: the usual trim of each line.
	static function eachTrim(lines:Array<String>):Int {
		for (line in lines) {
			line = StringTools.trim(line);
			if (line == "")
				Sys.println("  <empty>");
			else
				Sys.println("  [" + line + "]");
		}
		return 0;
	}

	// g4xy, no carried local: a null element gets a default.
	static function eachNullDefault(xs:Array<Null<Int>>):Int {
		for (v in xs) {
			if (v == null)
				v = -1;
			Sys.println("  v" + v);
		}
		return 0;
	}

	// 3qab, no carried local: a copy of the element is written, then printed.
	static function eachCopyWrite(xs:Array<Int>):Int {
		for (x in xs) {
			var t = x;
			t = t * 2;
			Sys.println("  copy t" + t);
		}
		return 0;
	}

	// g4xy: the element list is extended (`concat` and `push`); the outer list is not.
	static function elemSelfAppend(xss:Array<Array<Int>>):String {
		var out:Array<Int> = [];
		var total = 0;
		for (a in xss) {
			a = a.concat([0]);
			out = out.concat(a);
		}
		for (b in xss) {
			b.push(1);
			total += b.length;
		}
		return out.join(",") + ":" + total;
	}

	// 3qab: a body-local copy of the element is extended.
	static function copySelfAppend(xss:Array<Array<Int>>):Int {
		var total = 0;
		for (x in xss) {
			var a = x.copy();
			a.push(1);
			total += a.length;
		}
		return total;
	}

	// The copy is read in a closure that runs after the loop.
	static function copyInClosure(xs:Array<Int>):Int {
		var fs:Array<Void->Int> = [];
		for (x in xs) {
			var t = x;
			fs.push(() -> t);
		}
		var acc = 0;
		for (f in fs)
			acc += f();
		return acc;
	}

	// Control: a copy that is only read (the output keeps reading the element directly).
	static function copyReadOnly(xs:Array<Int>):Int {
		var acc = 0;
		for (k in xs) {
			var t = k;
			acc += t * 2;
		}
		return acc;
	}

	// Control: the element is written after the copy; the copy keeps the old value.
	static function copyThenElemWrite(xs:Array<Int>):Int {
		var acc = 0;
		for (k in xs) {
			var t = k;
			k = 0;
			acc += t * 10 + k;
		}
		return acc;
	}

	// Control: a branch value 0 in a loop with `break`, not a write.
	static function valueZeroWithBreak(xs:Array<Int>):Int {
		var acc = 0;
		for (k in xs) {
			if (k == 99)
				break;
			var r = if (k > 1) 0 else k;
			acc += r + 1;
		}
		return acc;
	}

	// Control: a while loop with the same branch-local write.
	static function whileLocalIf():Int {
		var i = 0;
		var sum = 0;
		while (i < 3) {
			var t = i;
			if (i > 0)
				t += 100;
			sum += t;
			i++;
		}
		return sum;
	}

	static function main() {
		run("arrayElemIf", () -> arrayElemIf([1, 2, 3]));
		run("arrayElemWrite", () -> arrayElemWrite([1, 2, 3]));
		run("arrayElemIfCompound", () -> arrayElemIfCompound([1, 2, 3]));
		run("arrayElemIfBreak", () -> arrayElemIfBreak([1, 2, 3, 99, 4]));
		run("arrayElemIfLast", () -> arrayElemIfLast([1, 2, 3]));
		run("nestedElemIf", () -> nestedElemIf([1, 2], [1, 2, 3]));
		run("mapKeyIf", () -> mapKeyIf([1 => 10, 2 => 20, 3 => 30]));
		run("keyValueIf", () -> keyValueIf([1 => 10, 2 => 20, 3 => 30]));
		var l = new List<Int>();
		l.add(1);
		l.add(2);
		l.add(3);
		run("listElemIf", () -> listElemIf(l));
		run("bodyLocal", () -> bodyLocal([1, 2, 3]));
		run("pushCopy", () -> pushCopy([1, 2, 3]));
		run("branchLocal", () -> branchLocal([1, 2, 3]));
		run("rangeLocalIf", () -> rangeLocalIf(4));
		run("shadowBranch", () -> shadowBranch([1, 2, 3]));
		run("twoShadows", () -> twoShadows([1, 2, 3, 4]));
		run("eachElemWrite", () -> eachElemWrite([1, 2, 3]));
		run("eachElemIfWrite", () -> eachElemIfWrite([1, 2, 3]));
		run("eachOuterSame", () -> eachOuterSame([1, 2]));
		run("eachParamSame", () -> eachParamSame(9, [1, 2]));
		run("eachTrim", () -> eachTrim([" a ", "  ", "b"]));
		run("eachNullDefault", () -> eachNullDefault([1, null, 3]));
		run("eachCopyWrite", () -> eachCopyWrite([1, 2, 3]));
		run("elemSelfAppend", () -> elemSelfAppend([[1], [2, 3]]));
		run("copySelfAppend", () -> copySelfAppend([[1], [2, 3], []]));
		run("copyInClosure", () -> copyInClosure([1, 2, 3]));
		run("copyReadOnly", () -> copyReadOnly([1, 2, 3]));
		run("copyThenElemWrite", () -> copyThenElemWrite([1, 2, 3]));
		run("valueZeroWithBreak", () -> valueZeroWithBreak([1, 2, 3, 99, 4]));
		run("whileLocalIf", () -> whileLocalIf());
	}
}
