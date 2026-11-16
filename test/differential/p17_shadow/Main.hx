// Differential fixture p17_shadow, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p17_shadow
enum Opt {
	Some(v:Int);
	None;
}

class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function withParam(count:Int, xs:Array<Int>):Array<Int> {
		var out:Array<Int> = [];
		for (x in xs) {
			for (y in xs)
				count += y;
			out.push(count + x);
		}
		return out.concat([count]);
	}

	static function main() {
		var xs = [1, 2, 3];
		var ys = [10, 20];
		var count = 0;
		var out:Array<Int> = [];
		for (x in xs) {
			var count = 10;
			for (y in ys)
				count += y;
			out.push(count + x);
		}
		show("shadow_inner", out);
		show("outer_count", [count]);
		show("param", withParam(5, [1, 2]));
		var opts = [Some(1), None, Some(3)];
		var got:Array<Int> = [];
		for (o in opts)
			switch (o) {
				case Some(v):
					for (y in ys)
						got.push(v + y);
				case None:
					got.push(0);
			}
		show("enum_payload", got);
		var r = [
			for (o in opts)
				switch (o) {
					case Some(v):
						v;
					case None:
						-1;
				}
		];
		show("enum_comp", r);
		var r2 = [
			for (o in opts)
				for (y in ys)
					switch (o) {
						case Some(v):
							v + y;
						case None:
							y;
					}
		];
		show("enum_nested_comp", r2);
		var total = 0;
		try {
			for (x in xs)
				for (y in ys)
					total += x * y;
		} catch (e:Dynamic) {}
		show("try_total", [total]);
	}
}
