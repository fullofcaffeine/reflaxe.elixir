// Differential fixture r12_binder_copy, from the PR #90 review probes (a kept match binder named g copied into another local).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture r12_binder_copy
enum Color {
	RGB(r:Int, g:Int, b:Int);
	Gray(v:Int);
}

enum Num {
	Num(g:Int);
	Zero;
}

class Main {
	static function run(name:String, f:Void->Dynamic) {
		try {
			Sys.println(name + "=" + Std.string(f()));
		} catch (e:Dynamic) {
			Sys.println(name + " THREW");
		}
	}

	static function copyBinder(c:Color):Int {
		var h = 0;
		switch (c) {
			case RGB(r, g, b):
				h = g;
			case Gray(v):
				h = v;
		}
		return h;
	}

	static function copyBinderDecl(c:Color):Int {
		switch (c) {
			case RGB(r, g, b):
				var h = g;
				return h + r + b;
			case Gray(v):
				return v;
		}
	}

	static function binderElseAlias(r:Num, c:Bool):Int {
		switch (r) {
			case Num(g):
				var h = 0;
				if (c) {
					h = 2;
				} else {
					h = g;
				}
				return g + h;
			case Zero:
				return -1;
		}
	}

	static function binderElseAliasQ(r:Num, c:Bool):Int {
		switch (r) {
			case Num(q):
				var h = 0;
				if (c) {
					h = 2;
				} else {
					h = q;
				}
				return q + h;
			case Zero:
				return -1;
		}
	}

	static function main() {
		run("copyBinder", () -> copyBinder(RGB(1, 9, 3)));
		run("copyBinderDecl", () -> copyBinderDecl(RGB(1, 9, 3)));
		run("binderElseAlias1", () -> binderElseAlias(Num(5), true));
		run("binderElseAlias2", () -> binderElseAlias(Num(5), false));
		run("binderElseAliasQ1", () -> binderElseAliasQ(Num(5), true));
		run("binderElseAliasQ2", () -> binderElseAliasQ(Num(5), false));
	}
}
