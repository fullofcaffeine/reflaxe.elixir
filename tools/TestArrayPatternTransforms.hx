package tools;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.transformers.CaseLengthToListPatternTransforms;
import reflaxe.elixir.ast.transformers.GlobalNumericSentinelCleanupTransforms;
import reflaxe.elixir.ast.transformers.ArithmeticIncrementTransforms;
import reflaxe.elixir.ast.transformers.LocalAssignUnusedUnderscoreScopedTransforms;
import reflaxe.elixir.ast.transformers.CaseBinderUnderscoreAlignTransforms;
import reflaxe.elixir.ast.transformers.BinderTransforms;
import reflaxe.elixir.preprocessor.TypedExprPreprocessor;
import reflaxe.elixir.ast.validation.FunctionResultInvariant;
import reflaxe.elixir.ast.builders.LoopBuilder;
import reflaxe.elixir.ast.builders.BlockBuilder;

/** Checks exact matching independently of the compiler's pattern recovery. */
class TestArrayPatternTransforms {
	public static function run():Expr {
		testInterpolatedFallbackBinding();
		testOverwrittenCaseBinder();
		testPrintedReturnValues();
		testNestedExtractionBindings();
		testConsumedArrayCounterSeed();
		final list = makeAST(EList([makeAST(ECall(null, "read_once", []))]));
		final target = makeAST(ECall(null, "length", [list]));
		final guard = makeAST(EBinary(Equal, makeAST(EVar("arr")), makeAST(EInteger(7))));
		final body = makeAST(EInteger(9));
		final singleton = makeAST(ECase(target, [
			{pattern: PLiteral(makeAST(EInteger(0))), guard: null, body: body},
			{pattern: PLiteral(makeAST(EInteger(1))), guard: guard, body: body},
			{pattern: PWildcard, guard: null, body: body}
		]));
		switch (CaseLengthToListPatternTransforms.pass(singleton).def) {
			case ECase(actualList, clauses):
				if (actualList != list)
					fail("conversion must evaluate the original list exactly once");
				switch (clauses[0].pattern) {
					case PList([]):
					default: fail("zero length must match only an empty list");
				}
				switch (clauses[1].pattern) {
					case PList([PWildcard]):
					default: fail("one length must match exactly one element, not a nonempty list");
				}
				if (clauses[1].guard != guard || clauses[1].body != body)
					fail("conversion must not guess the owner of guard names or change the body");
			default:
				fail("zero/singleton cases must retain exact list matching");
		}
		for (unsupported in [PLiteral(makeAST(EInteger(2))), PVar("count"), PVar("_count")]) {
			final original = makeAST(ECase(target, [
				{pattern: PLiteral(makeAST(EInteger(1))), guard: null, body: body},
				{pattern: unsupported, guard: null, body: body}
			]));
			switch (CaseLengthToListPatternTransforms.pass(original).def) {
				case ECase(actualTarget, clauses):
					if (actualTarget != target || clauses[1].pattern != unsupported)
						fail("an unsupported clause must preserve the complete numeric switch");
				default:
					fail("an unsupported clause changed the switch shape");
			}
		}
		final unknownTarget = makeAST(ECall(null, "length", [makeAST(EVar("possibly_null"))]));
		final unknown = makeAST(ECase(unknownTarget, [
			{pattern: PLiteral(makeAST(EInteger(1))), guard: null, body: body},
			{pattern: PWildcard, guard: null, body: body}
		]));
		switch (CaseLengthToListPatternTransforms.pass(unknown).def) {
			case ECase(actualTarget, _) if (actualTarget == unknownTarget):
			default:
				fail("conversion must not bypass length errors for an unknown value");
		}
		Sys.println("Array pattern transform contracts passed");
		return macro null;
	}

	/** Interpolation reads keep fallback aliases alive after string lowering. */
	static function testInterpolatedFallbackBinding():Void {
		final binding = makeAST(EMatch(PVar("n"), makeAST(EVar("value"))));
		final result = makeAST(ERaw('"value #{n}"'));
		final original = makeAST(ECase(makeAST(EVar("category")), [{pattern: PWildcard, guard: null, body: makeAST(EBlock([binding, result]))}]));
		switch (BinderTransforms.casePatternTempAssignmentRemovalPass(original).def) {
			case ECase(_, [{body: {def: EBlock(statements)}}]):
				if (statements.length != 2)
					fail("fallback aliases used in interpolation must retain their binding");
			default:
				fail("fallback cleanup changed the case shape");
		}
	}

	/** The first assignment replaces a case capture unless its old value is read. */
	static function testOverwrittenCaseBinder():Void {
		final input = makeAST(EVar("input"));
		final value = makeAST(EVar("value"));
		for (readsOld in [false, true]) {
			for (guarded in [false, true]) {
				final guard = guarded ? makeAST(EBinary(Greater, value, makeAST(EInteger(0)))) : null;
				final body = makeAST(EBlock([makeAST(EMatch(PVar("value"), readsOld ? value : input)), value]));
				final original = makeAST(EDef("probe", [PVar("input")], null, makeAST(ECase(input, [{pattern: PVar("value"), guard: guard, body: body}]))));
				final result = CaseBinderUnderscoreAlignTransforms.pass(LocalAssignUnusedUnderscoreScopedTransforms.pass(original));
				switch (result.def) {
					case EDef(_, _, _, {def: ECase(_, [clause])}):
						final expected = readsOld || guarded ? PVar("value") : PWildcard;
						if (!Type.enumEq(clause.pattern, expected))
							fail("case capture must follow reads before its first overwrite");
					default:
						fail("case-binding cleanup changed the function shape");
				}
			}
		}
	}

	/** Ordinary blocks preserve numeric results; the invariant rejects legacy do-block loss. */
	static function testPrintedReturnValues():Void {
		for (value in [makeAST(EInteger(0)), makeAST(EInteger(1)), makeAST(EFloat(0.0))]) {
			value.metadata.sourceExpr = Context.typeExpr(macro 0);
			final literal = ElixirASTPrinter.print(value);
			final block = makeAST(EBlock([makeAST(ECall(null, "observe", [])), value]));
			if (StringTools.trim(ElixirASTPrinter.print(block)) != "observe()\n" + literal)
				fail("printer discarded a numeric block result");
			for (sequence in [block, makeAST(EDo([makeAST(ECall(null, "observe", [])), value]))]) {
				final definition = makeAST(EDef("numeric_result", [], null, sequence));
				definition.metadata.functionResultContract = Value;
				definition.metadata.functionResultMayBeNil = false;
				final state = FunctionResultInvariant.capture(definition, "Probe").get("Probe.numeric_result/0");
				final legacyDo = sequence.def.match(EDo(_));
				if (state == null || (state.problem != null) != legacyDo)
					fail("result validation must accept ordinary block tails and reject legacy do-block loss");
				for (cleanup in [
					GlobalNumericSentinelCleanupTransforms.cleanupPass,
					ArithmeticIncrementTransforms.transformPass
				]) {
					final cleaned = cleanup(sequence);
					switch (cleaned.def) {
						case EBlock(items) | EDo(items):
							if (items.length != 2 || items[1].def != value.def)
								fail("numeric cleanup discarded a block result");
						default:
							fail("numeric cleanup changed the sequence kind");
					}
				}
			}
			final lambda = makeAST(EFn([{args: [], guard: null, body: value}]));
			if (ElixirASTPrinter.print(lambda).indexOf(literal) < 0)
				fail("printer discarded a numeric anonymous-function result");
		}
	}

	/** Removing intermediate reads must never leave references to their removed bindings. */
	static function testNestedExtractionBindings():Void {
		final input = Context.typeExpr(macro {
			var rows:Array<Array<Int>> = [[1, 2], [3, 4]];
			var g = rows[0];
			var g1 = g[1];
			g1;
		});
		final result = TypedExprPreprocessor.preprocess(input);
		final declared = new Map<Int, Bool>();
		function collect(expr:TypedExpr):Void {
			switch (expr.expr) {
				case TVar(variable, _):
					declared.set(variable.id, true);
				default:
			}
			TypedExprTools.iter(expr, collect);
		}
		collect(result);
		function verify(expr:TypedExpr):Void {
			switch (expr.expr) {
				case TLocal(variable) if (!declared.exists(variable.id)):
					fail("nested extraction retained a reference to removed local " + variable.name);
				default:
			}
			TypedExprTools.iter(expr, verify);
		}
		verify(result);
	}

	/** Counter elimination needs the exact local, zero seed and absence of later captures. */
	static function testConsumedArrayCounterSeed():Void {
		var source = Context.typeExpr(macro {
			var values = [1, 2];
			var cursor = 0;
			while (cursor < values.length) {
				var value = values[cursor];
				cursor++;
				if (value < 0)
					throw "negative";
			}
			function() return cursor;
		});
		switch (source.expr) {
			case TBlock([_, {expr: TVar(counter, initializer)}, loop, capture]):
				if (!LoopBuilder.consumesArrayCounterSeed(counter, initializer, loop))
					fail("A zero seed for the exact array-loop counter must be consumed.");
				if (LoopBuilder.consumesArrayCounterSeed(counter, Context.typeExpr(macro 3), loop))
					fail("A nonzero initializer must not be removed.");

				var other = Context.typeExpr(macro {var cursor = 0; cursor;});
				switch (other.expr) {
					case TBlock([{expr: TVar(otherCounter, _)}, _]):
						if (LoopBuilder.consumesArrayCounterSeed(otherCounter, initializer,
							loop)) fail("Same-spelled counters with different IDs must remain independent.");
					default: fail("Unexpected independent-counter fixture shape.");
				}

				if (! @:privateAccess BlockBuilder.typedExprsUseLocal([capture], counter, true))
					fail("A later closure must keep its captured counter declaration.");
			default:
				fail("Unexpected array-loop fixture shape.");
		}
	}

	static function fail(message:String):Void {
		Context.fatalError(message, Context.currentPos());
	}
}
#end
