// Differential fixture r08_catch_temp, from the PR #87 review probes (user g next to catch temps).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r08_catch_temp
class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static function risky(x:Int):Int {
		if (x > 2)
			throw "big";
		if (x < 0)
			throw 42;
		return x;
	}

	static function catchTyped(x:Int):Int {
		var g = 5;
		var r = 0;
		try {
			r = risky(x);
		} catch (e:String) {
			r = g + 100;
		} catch (e:Int) {
			r = g + e;
		}
		return r + g;
	}

	static function catchValue(x:Int):Int {
		var g = side(x);
		var r = try risky(x) catch (e:String) g * 2;
		return r + g;
	}

	static function side(x:Int):Int
		return x + 1;

	static function objTemp(x:Int):Int {
		var g = side(x);
		var o = {a: side(g), b: side(g + 1)};
		return o.a + o.b + g;
	}

	static function whileOnly(n:Int):Int {
		var g = 1;
		var g1 = 2;
		var i = 0;
		while (i < n) {
			g += g1;
			g1++;
			i++;
		}
		return g * 100 + g1;
	}

	static function main() {
		run("catchTyped0", () -> catchTyped(0));
		run("catchTyped5", () -> catchTyped(5));
		run("catchTypedNeg", () -> catchTyped(-1));
		run("catchValue1", () -> catchValue(1));
		run("catchValue5", () -> catchValue(5));
		run("objTemp", () -> objTemp(2));
		run("whileOnly", () -> whileOnly(3));
	}
}
