package;

import elixir.types.Atom;
import elixir.types.Tuple2;

enum abstract FixtureMode(Atom) to Atom {
	var Read = "read";
	var Binary = "binary";
}

enum abstract FixtureOrigin(Atom) to Atom {
	var Begin = "bof";
	var End = "eof";
}

class Main {
	public static function modes():Array<FixtureMode> {
		return [FixtureMode.Read, FixtureMode.Binary];
	}

	public static function position():Tuple2<FixtureOrigin, Int> {
		return {_0: FixtureOrigin.Begin, _1: 7};
	}

	public static function isEnd(value:FixtureOrigin):Bool {
		return value == FixtureOrigin.End;
	}

	static function main():Void {
		trace(modes());
		trace(position());
		trace(isEnd(FixtureOrigin.End));
	}
}
