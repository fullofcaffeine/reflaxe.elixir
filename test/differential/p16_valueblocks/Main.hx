// Differential fixture p16_valueblocks, from the PR #82 and #83 review probes (nested and reduce_while comprehensions).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture p16_valueblocks
class Main {
	static function show(label:String, a:Array<Dynamic>)
		Sys.println(label + "=[" + a.map(Std.string).join(",") + "]");

	static function main() {
		var xs = [1, 2, 3];
		var ys = [10, 20];
		var out:Array<Int> = [];
		var vals:Array<Int> = [];
		for (x in xs) {
			var v = if (x > 1) {
				out.push(x);
				x * 2;
			} else 0;
			vals.push(v);
		}
		show("if_value_push", out);
		show("if_value_vals", vals);
		var out2:Array<Int> = [];
		for (x in xs) {
			try {
				for (y in ys) {
					if (y == 20 && x == 2)
						throw "stop";
					out2.push(x + y);
				}
			} catch (e:String) {
				out2.push(-x);
			}
		}
		show("try_in_loop", out2);
		var out3:Array<Int> = [];
		for (x in xs) {
			switch (x) {
				case 1:
					out3.push(1);
				case 2:
					for (y in ys)
						out3.push(y);
				default:
					out3.push(x * 100);
			}
		}
		show("switch_in_loop", out3);
		var out4:Array<Int> = [];
		for (x in xs) {
			var w = switch (x) {
				case 2: {for (y in ys) out4.push(y + x); out4.length;}
				default: 0;
			};
			out4.push(w);
		}
		show("switch_value_loop", out4);
		var out5:Array<Int> = [];
		var i = 0;
		while (i < 3) {
			for (y in ys)
				out5.push(i * 100 + y);
			i++;
			if (i == 2)
				continue;
		}
		show("while_for", out5);
		var out6:Array<Int> = [];
		do {
			for (y in ys)
				out6.push(y);
		} while (out6.length < 3);
		show("do_while_for", out6);
	}
}
