// Differential fixture r05_closures, from the PR #87 review probes (user g captured by closures).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r05_closures
class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static function captureRead(n:Int):Int {
		var g = 3;
		var add = function(x:Int) return x + g;
		var acc = 0;
		for (i in 0...n)
			acc += add(i);
		return acc + g;
	}

	static function captureInLoop(n:Int):String {
		var g = [10, 20];
		var out = [];
		for (i in 0...n)
			out.push(g.map(x -> x + i).join("+"));
		return out.join(",");
	}

	static function nestedFn(n:Int):Int {
		var g = 10;
		function inner(m:Int):Int {
			var g = 0;
			for (j in 0...m)
				g += j;
			return g;
		}
		var t = 0;
		while (t < n) {
			g += inner(t);
			t++;
		}
		return g;
	}

	static function nestedReadsOuter(n:Int):Int {
		var g = 10;
		for (i in 0...n)
			g += i;
		function inner(m:Int):Int {
			var acc = 0;
			for (j in 0...m)
				acc += j + g;
			return acc;
		}
		return inner(2) + g;
	}

	static function lambdaParamG(xs:Array<Int>):String {
		var g = 2;
		for (i in 0...2)
			g += i;
		var ys = xs.map(g -> g * 10);
		var zs = xs.filter(function(g1) return g1 > g);
		return ys.join(",") + "|" + zs.join(",") + "|" + g;
	}

	static function closureLocalG(xs:Array<Int>):String {
		var f = function(k:Int):Int {
			var g = k;
			for (i in 0...k)
				g += i;
			return g;
		};
		var out = [];
		for (x in xs)
			out.push(f(x));
		return out.join(",");
	}

	static function closureAfterLoopValue(n:Int):Int {
		var g = 0;
		for (i in 0...n)
			g += i;
		var f = () -> g * 2;
		return f();
	}

	static function main() {
		run("captureRead", () -> captureRead(3));
		run("captureInLoop", () -> captureInLoop(2));
		run("nestedFn", () -> nestedFn(4));
		run("nestedReadsOuter", () -> nestedReadsOuter(3));
		run("lambdaParamG", () -> lambdaParamG([1, 5, 9]));
		run("closureLocalG", () -> closureLocalG([1, 2, 3]));
		run("closureAfterLoopValue", () -> closureAfterLoopValue(4));
	}
}
