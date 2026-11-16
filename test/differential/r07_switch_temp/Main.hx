// Differential fixture r07_switch_temp, from the PR #87 review probes (user g next to the subject temp of a switch on a computed value).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r07_switch_temp
enum Color {
	RGB(r:Int, g:Int, b:Int);
	Gray(v:Int);
}

class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static function side(x:Int):Int
		return x + 1;

	static function mk(x:Int):Color
		return x > 2 ? RGB(x, x + 1, x + 2) : Gray(x);

	static function litG(x:Int):Int {
		var g = 5;
		var r = switch (side(x)) {
			case 1: g;
			case v: v + g;
		}
		return r + g;
	}

	static function callG(x:Int):Int {
		var g = side(x);
		var r = switch (side(g)) {
			case 1: 10;
			case v: v + g;
		}
		return r + g;
	}

	static function arithG(x:Int):Int {
		var g = x + 1;
		var r = switch (side(x * 2)) {
			case 1: 10;
			case v: v + g;
		}
		return r + g;
	}

	static function arrayG(x:Int):String {
		var g = [1, 2];
		var r = switch (side(x)) {
			case 1: 10;
			case v: v + g.length;
		}
		g.push(r);
		return g.join(",");
	}

	static function enumSubject(x:Int):Int {
		var g = 10;
		var r = switch (mk(x)) {
			case RGB(r, _, b): r + b + g;
			case Gray(v): v + g;
		}
		return r + g;
	}

	static function enumSubjectMut(x:Int):Int {
		var g = 10;
		g += x;
		var r = switch (mk(x)) {
			case RGB(r, _, b): r + b + g;
			case Gray(v): v + g;
		}
		g += 1;
		return r + g;
	}

	static function tupleSubject(x:Int):Int {
		var g = 3;
		var g1 = 4;
		var r = switch [side(x), side(x + 1)] {
			case [1, _]: g;
			case [a, b]: a + b + g + g1;
		}
		return r + g + g1;
	}

	static function paramG(g:Int, x:Int):Int {
		var r = switch (side(x)) {
			case 1: g;
			case v: v + g;
		}
		return r + g;
	}

	static function stringSubject(s:String):String {
		var g = "pre";
		var r = switch (s.toUpperCase()) {
			case "A": g + "a";
			case other: g + other;
		}
		return r + g;
	}

	static function main() {
		run("litG", () -> litG(4));
		run("callG", () -> callG(4));
		run("arithG", () -> arithG(4));
		run("arrayG", () -> arrayG(4));
		run("enumSubject3", () -> enumSubject(3));
		run("enumSubject1", () -> enumSubject(1));
		run("enumSubjectMut3", () -> enumSubjectMut(3));
		run("enumSubjectMut1", () -> enumSubjectMut(1));
		run("tupleSubject", () -> tupleSubject(4));
		run("paramG", () -> paramG(7, 4));
		run("stringSubject", () -> stringSubject("b"));
	}
}
