// Differential fixture o02_scopes, from the PR #81 review probes (binder names, nested Ok/Error switches, catch arms).
// Reference: haxe --interp. Run: scripts/test-differential.sh --fixture o02_scopes
enum Verdict {
	Ok(v:String);
	Error(v:String);
}

class Main {
	static function note(s:String):Void {
		Sys.println("  note " + s);
	}

	// catch var `reason`, inner switch with Error arm, moved code reads reason
	static function catchReason(r:Verdict, fail:Bool):String {
		try {
			if (fail)
				throw "boom";
			return "nofail";
		} catch (reason:String) {
			switch (r) {
				case Error(e):
					note(e);
				case Ok(o):
					return "ok " + o + reason;
			}
			return "caught " + reason;
		}
	}

	// catch var `value`, Ok arm
	static function catchValue(r:Verdict, fail:Bool):String {
		try {
			if (fail)
				throw "boom";
			return "nofail";
		} catch (value:String) {
			switch (r) {
				case Ok(o):
					note(o);
				case Error(e):
					return "err " + e + value;
			}
			return "caught " + value;
		}
	}

	// switch in try body, catch var reason unrelated
	static function inTry(r:Verdict, reason:String):String {
		try {
			switch (r) {
				case Ok(v):
					note(v);
				case Error(e):
					return "err " + e;
			}
			return "t " + reason;
		} catch (x:String) {
			return "c " + x;
		}
	}

	// closure capturing outer `reason` and called inside an Error arm
	static function closureInArm(r:Verdict):String {
		var reason = "LOCAL";
		var f = function() return "f:" + reason;
		switch (r) {
			case Error(e):
				note(e);
			case Ok(o):
				return "ok " + o + f();
		}
		return f() + reason;
	}

	// fn arg reason inside map; Error arm with unused binder
	static function mapReason(rs:Array<Verdict>):String {
		return rs.map(function(reason:Verdict):String {
			return switch (reason) {
				case Error(_): "E";
				case Ok(v): "O" + v;
			};
		}).join(",");
	}

	// fn arg value inside map; Ok arm reads closure arg not payload
	static function mapValue(r:Verdict, items:Array<String>):String {
		return items.map(function(value:String):String {
			return switch (r) {
				case Ok(_): "ok/" + value;
				case Error(e): "err/" + e + value;
			};
		}).join(",");
	}

	// Error arm with unused binder reading closure arg reason
	static function mapReasonUnused(r:Verdict, items:Array<String>):String {
		return items.map(function(reason:String):String {
			return switch (r) {
				case Error(_): "err/" + reason;
				case Ok(o): "ok/" + o + reason;
			};
		}).join(",");
	}

	// Local var declared after the switch inside moved code, named value.
	static function laterLocal(r:Verdict):String {
		switch (r) {
			case Ok(v):
				note(v);
			case Error(e):
				return "err " + e;
		}
		var value = "later";
		return "r=" + value;
	}

	// Later local named reason; Error arm moved
	static function laterReason(r:Verdict):String {
		switch (r) {
			case Error(e):
				note(e);
			case Ok(o):
				return "ok " + o;
		}
		var reason = "later";
		return "r=" + reason;
	}

	// Variable assigned after switch from payload-named outer
	static function reassigned(r:Verdict, value:String):String {
		switch (r) {
			case Ok(v):
				note(v);
			case Error(e):
				return "err " + e;
		}
		value = value + "!";
		return "r=" + value;
	}

	// Switch in a nested block-closed scope then a later switch: both may use value
	static function twoBlocks(r:Verdict, s:Verdict):String {
		var acc = "";
		{
			var value = "blk";
			acc += value;
		}
		switch (r) {
			case Ok(v):
				acc += v;
			case Error(e):
				return "err " + e + acc;
		}
		switch (s) {
			case Ok(v):
				acc += v;
			case Error(e):
				return "err2 " + e + acc;
		}
		return acc;
	}

	static function main() {
		for (r in [Ok("o"), Error("x")]) {
			Sys.println("catchReason " + catchReason(r, true) + " " + catchReason(r, false));
			Sys.println("catchValue " + catchValue(r, true) + " " + catchValue(r, false));
			Sys.println("inTry " + inTry(r, "R"));
			Sys.println("closureInArm " + closureInArm(r));
			Sys.println("mapValue " + mapValue(r, ["1", "2"]));
			Sys.println("mapReasonUnused " + mapReasonUnused(r, ["1", "2"]));
			Sys.println("laterLocal " + laterLocal(r));
			Sys.println("laterReason " + laterReason(r));
			Sys.println("reassigned " + reassigned(r, "V"));
			for (s in [Ok("p"), Error("y")])
				Sys.println("twoBlocks " + twoBlocks(r, s));
		}
		Sys.println("mapReason " + mapReason([Ok("o"), Error("x")]));
	}
}
