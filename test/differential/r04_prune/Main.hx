// Differential fixture r04_prune, from the PR #87 review probes (dead initializers of locals named g).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r04_prune
abstract Vec(Array<Int>) from Array<Int> to Array<Int> {
	public static var log:Array<String> = [];

	@:op(A + B) public function add(o:Vec):Vec {
		log.push("add");
		return [this[0] + o.first()];
	}

	@:op(A * B) public function mul(k:Int):Vec {
		log.push("mul");
		return [this[0] * k];
	}

	public function first():Int
		return this[0];
}

class Main {
	static var calls = 0;

	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static function bump(x:Int):Int {
		calls++;
		return x;
	}

	static function initElse(c:Bool, x:Int):Int {
		var g = x * 2;
		var h = 0;
		if (c) {
			g = 1;
			h = 2;
		} else {
			h = g;
		}
		return g + h;
	}

	static function initBoth(c:Bool, x:Int):Int {
		var a = x * 2;
		var b = x + 1;
		if (c) {
			a = 0;
			b = 0;
		}
		return a + b;
	}

	static function initLoopZero(n:Int, x:Int):Int {
		var a = x * 3;
		var b = 1;
		var i = 0;
		while (i < n) {
			a = i;
			b = b + i;
			i++;
		}
		return a + b;
	}

	static function initOverwritten(x:Int):Int {
		var g = x + 1;
		var seen = g;
		g = 9;
		return seen + g;
	}

	static function initDead(x:Int, y:Int):Int {
		var g = x * y - 1;
		g = x;
		return g;
	}

	static function initCall(x:Int):Int {
		var g = bump(x) + 1;
		g = 4;
		return g + calls;
	}

	static function initAbstract():String {
		var a:Vec = [2];
		var b:Vec = [3];
		var g = a + b;
		g = a * 5;
		var h = a + b;
		h = b;
		return g.first() + "," + h.first() + "," + Vec.log.join("/");
	}

	static function initClosure(x:Int):Int {
		var g = x + 1;
		var f = () -> g;
		var before = f();
		g = 50;
		return before + g;
	}

	static function initSwitch(k:Int, x:Int):Int {
		var g = x * 2;
		var h = x - 1;
		switch (k) {
			case 0:
				g = 1;
				h = 1;
			case 1:
				h = g + 1;
			default:
		}
		return g * 100 + h;
	}

	static function initTry(x:Int):Int {
		var g = x + 2;
		var h = 0;
		try {
			if (x > 0)
				throw "boom";
			g = 1;
			h = 1;
		} catch (e:Dynamic) {
			h = 7;
		}
		return g * 10 + h;
	}

	static function initNestedLoop(n:Int):Int {
		var g = 0;
		var total = 0;
		for (i in 0...n) {
			g = i * 2;
			var j = 0;
			while (j < i) {
				g = g + 1;
				j++;
			}
			total += g;
		}
		return total + g;
	}

	static function main() {
		run("initElse1", () -> initElse(true, 5));
		run("initBoth1", () -> initBoth(true, 5));
		run("initBoth2", () -> initBoth(false, 5));
		run("initLoopZero0", () -> initLoopZero(0, 4));
		run("initLoopZero2", () -> initLoopZero(2, 4));
		run("initOverwritten", () -> initOverwritten(3));
		run("initDead", () -> initDead(3, 4));
		run("initClosure", () -> initClosure(3));
		run("initSwitch0", () -> initSwitch(0, 5));
		run("initSwitch1", () -> initSwitch(1, 5));
		run("initSwitch2", () -> initSwitch(2, 5));
		run("initTry1", () -> initTry(1));
		run("initTry0", () -> initTry(0));
		run("initNestedLoop", () -> initNestedLoop(4));
	}
}
