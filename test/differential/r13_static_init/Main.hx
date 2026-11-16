// Differential fixture r13_static_init, from the PR #90 review probes (locals named g in static and instance initializers).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r13_static_init
class Tables {
	public static var doubled:Array<Int> = {
		var g = [];
		for (i in 0...4)
			g.push(i * 2);
		g;
	};

	public static var fun:Int->Int = function(g:Int):Int {
		var acc = 0;
		for (i in 0...4)
			acc += i;
		return g * 100 + acc;
	};

	public static var alias:Int = {
		var g = 10;
		var h = 0;
		if (doubled.length > 100) {
			g = 1;
			h = 2;
		} else {
			h = g;
		}
		g + h;
	};

	public static final lam = (g:String) -> '$g!';
}

class Inst {
	public var items:Array<Int> = {
		var g = [];
		for (i in 0...3)
			g.push(i + 1);
		g;
	};

	public function new() {}
}

class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static function main() {
		run("staticBlock", () -> Tables.doubled.join(","));
		run("staticFn", () -> Tables.fun(7));
		run("staticAlias", () -> Tables.alias);
		run("staticLam", () -> Tables.lam("x"));
		run("instInit", () -> new Inst().items.join(","));
	}
}
