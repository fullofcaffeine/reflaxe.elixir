// Differential fixture p23_scopes, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p23_scopes
class Main {
	static function show(label:String, a:Array<Dynamic>) {
		var s = a.map(Std.string);
		s.sort(Reflect.compare);
		Sys.println(label + "=" + s.join(","));
	}

	static function inSwitch(k:Int, m:Map<String, Int>):Array<String> {
		return switch (k) {
			case 0: [for (k in m.keys()) k];
			case 1: [for (k in m.keys()) for (j in m.keys()) k + j];
			default: [];
		};
	}

	static function inTry(m:Map<String, Int>):Array<String> {
		try {
			return [for (k in m.keys()) for (j in m.keys()) k + j];
		} catch (e:Dynamic) {
			return [];
		}
	}

	static function inIf(c:Bool, m:Map<String, Int>):Array<String> {
		if (c)
			return [for (k in m.keys()) k + "!"];
		return [for (k in m.keys()) k + "?"];
	}

	static function main() {
		var m = ["a" => 1, "b" => 2];
		show("sw0", inSwitch(0, m));
		show("sw1", inSwitch(1, m));
		show("try", inTry(m));
		show("if_t", inIf(true, m));
		show("if_f", inIf(false, m));
		show("map_cb", [1, 2].map(x -> [for (k in m.keys()) k + x].length));
	}
}
