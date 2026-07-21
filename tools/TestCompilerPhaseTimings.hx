package tools;

#if macro
import haxe.macro.Expr;
import reflaxe.elixir.debug.CompilerPhaseTimings;

/** Focused executable contract for opt-in coarse compiler phase timing. */
class TestCompilerPhaseTimings {
	public static function run():Expr {
		var disabled = new CompilerPhaseTimings(false);
		disabled.record("ignored", 4.0);
		assertEquals(0, disabled.snapshot().length, "disabled instrumentation records nothing");

		var timings = new CompilerPhaseTimings(true);
		timings.record("printer", 2.5);
		timings.record("ast_construction", 3.0);
		timings.record("printer", 1.5);
		var snapshot = timings.snapshot();

		assertEquals(2, snapshot.length, "phase count");
		assertEquals("ast_construction", snapshot[0].name, "snapshots use stable name order");
		assertEquals(3.0, snapshot[0].durationMs, "AST duration");
		assertEquals("printer", snapshot[1].name, "second stable phase");
		assertEquals(4.0, snapshot[1].durationMs, "repeated phases accumulate");
		assertEquals(2, snapshot[1].count, "repeated phase count");

		timings.reset();
		assertEquals(0, timings.snapshot().length, "a new server request starts empty");

		expectFailure(() -> timings.record("", 1.0), "must not be empty");
		expectFailure(() -> timings.record("bad", -1.0), "negative duration");

		Sys.println("Compiler phase timing contract passed");
		return macro null;
	}

	static function expectFailure(operation:Void->Void, expected:String):Void {
		try {
			operation();
		} catch (error:Dynamic) {
			if (Std.string(error).indexOf(expected) >= 0)
				return;
			throw 'wrong timing diagnostic: $error';
		}
		throw 'expected timing failure containing `$expected`';
	}

	static function assertEquals<T>(expected:T, actual:T, label:String):Void {
		if (expected != actual)
			throw '$label: expected $expected, got $actual';
	}
}
#end
