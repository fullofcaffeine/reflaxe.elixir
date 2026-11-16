// Differential fixture p20_rw, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p20_rw
class Pair {
	var items:Array<Int>;
	var i:Int;

	public function new(items:Array<Int>) {
		this.items = items;
		this.i = 0;
	}
}

class Main {
	static function show(label:String, a:Array<Dynamic>) {
		var s = a.map(Std.string);
		s.sort(Reflect.compare);
		Sys.println(label + "=" + s.join(","));
	}

	static function keysOnly(m:Map<String, Int>):Array<String>
		return [for (k in m.keys()) k];

	static function keysA(m:Map<String, Int>, xs:Array<Int>):Array<String> {
		return [for (k in m.keys()) for (x in xs) k + x];
	}

	static function main() {
		var xs = [1, 2];
		var m = ["a" => 1, "b" => 2];
		var im = [1 => "one", 2 => "two"];
		var empty = new Map<String, Int>();
		show("keys_a", [for (k in m.keys()) for (x in xs) k + x]);
		show("keys_keys", [for (k in m.keys()) for (j in im.keys()) k + j]);
		show("r_keys", [for (i in 0...2) for (k in im.keys()) i * 10 + k]);
		show("r3_keys", [for (i in 0...3) for (k in im.keys()) i * 10 + k]);
		show("vals_a", [for (v in m) for (x in xs) v * 10 + x]);
		show("kv_a", [for (k => v in m) for (x in xs) k + (v + x)]);
		show("iter_a", [for (y in xs.iterator()) for (x in xs) y * 10 + x]);
		show("keys_only_ret", keysOnly(m));
		show("keys_a_ret", keysA(m, xs));
		show("keys_empty", [for (k in empty.keys()) for (x in xs) k + x]);
		show("keys_a_filter", [
			for (k in m.keys())
				if (k != "a") for (x in xs)
					if (x > 1)
						k + x
		]);
		var stored = [for (k in m.keys()) for (x in xs) k + x];
		show("stored_len", [stored.length]);
		show("keys_keys_keys", [for (k in m.keys()) for (j in im.keys()) for (k2 in m.keys()) k + j + k2]);
	}
}
