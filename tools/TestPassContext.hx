package tools;

#if macro
import haxe.macro.Expr;
import reflaxe.elixir.ast.AnalysisManager;
import reflaxe.elixir.ast.AnalysisManager.AnalysisDefinition;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTStructuralDigest;
import reflaxe.elixir.ast.PassApplicability.PassScope;
import reflaxe.elixir.ast.PassContext;
import reflaxe.elixir.ast.PassContext.PassChange;
import reflaxe.elixir.ast.PassContext.PassTempAllocator;

/** Focused executable contract for request-local pass state and invalidation. */
class TestPassContext {
	public static function run():Expr {
		testRequestIsolationAndDeterministicTemps();
		testOutcomeRevisionAndPreservation();
		testTransitiveInvalidation();
		testDependencyCyclesFailClosed();
		testForcedRecomputationDetectsStaleData();
		testPrinterIllegalStructuralDigest();

		Sys.println("Pass context and analysis contract passed");
		return macro null;
	}

	static function testRequestIsolationAndDeterministicTemps():Void {
		var ast = makeAST(EDef("run", [PVar("temp_2")], null, makeAST(EBlock([makeAST(EVar("temp"))]))));
		var first = new PassContext("Sample", ast);
		var second = new PassContext("Sample", ast);

		assertEquals("temp_3", first.allocateTemp("temp"), "structured variable and pattern names are reserved");
		assertEquals("temp_4", first.allocateTemp("temp"), "one request advances deterministically");
		assertEquals("temp_3", second.allocateTemp("temp"), "a second request has an isolated allocator");

		var opaque = new PassContext("Sample", makeAST(EVar("visible")));
		opaque.reserveTemp("contract_name");
		assertEquals("contract_name_2", opaque.allocateTemp("contract_name"), "contract-known opaque names can be reserved");

		var evolving = new PassContext("Sample", makeAST(EVar("visible")));
		assertEquals("generated", evolving.allocateTemp("generated"), "the first revision can use an available base");
		evolving.beginPass("introduce-structured-name", "core", PassScope.Core);
		evolving.finish({
			ast: makeAST(EBlock([makeAST(EVar("generated_2"))])),
			change: Changed,
			preservedAnalyses: []
		});
		assertEquals("generated_3", evolving.allocateTemp("generated"), "a changed revision inventories newly introduced names");

		var reordered = new PassTempAllocator(["temp_2", "temp"]);
		assertEquals("temp_3", reordered.allocate("temp"), "reservation order does not affect allocation");

		first.beginPass("sample-pass", "core", PassScope.Core);
		first.addDiagnostic("sample diagnostic");
		assertEquals(1, first.diagnostics.length, "diagnostics stay on their request");
		assertEquals(0, second.diagnostics.length, "diagnostics do not leak to another request");
	}

	static function testOutcomeRevisionAndPreservation():Void {
		var ast = makeAST(EVar("value"));
		var context = new PassContext("Sample", ast);
		var computations = 0;
		var definition = analysis("value", [], _ -> ++computations);

		assertEquals(1, context.analyses.get(definition), "analysis computes lazily");
		assertEquals(1, context.analyses.get(definition), "same revision reuses the cached result");

		context.beginPass("proved-unchanged", "core", PassScope.Core);
		context.finish({
			ast: ast,
			change: Unchanged,
			preservedAnalyses: []
		});
		assertEquals(0, context.revision, "proved unchanged keeps the AST revision");
		assertTrue(context.analyses.isCached("value"), "proved unchanged retains cached analyses");

		context.beginPass("proved-changed", "core", PassScope.Core);
		context.finish({
			ast: ast,
			change: Changed,
			preservedAnalyses: ["value"]
		});
		assertEquals(1, context.revision, "proved changed advances the AST revision");
		assertTrue(context.analyses.isCached("value"), "explicitly preserved analysis advances with the revision");

		context.beginPass("legacy", "core", PassScope.Core);
		context.finish(PassContext.legacyOutcome(ast));
		assertEquals(2, context.revision, "legacy unknown advances the AST revision conservatively");
		assertFalse(context.analyses.isCached("value"), "legacy unknown invalidates unproven analyses");
		assertEquals(0, context.analyses.cacheSize(), "invalidated analysis storage is empty");
		assertEquals(PassChange.Unknown, context.lastChange, "legacy adaptation remains visibly unknown");

		context.beginPass("invalid-outcome", "core", PassScope.Core);
		expectFailure("missing pass change classification", () -> context.finish({
			ast: ast,
			change: cast null,
			preservedAnalyses: []
		}), "no change classification");
	}

	static function testTransitiveInvalidation():Void {
		var ast = makeAST(EVar("value"));
		var manager = new AnalysisManager(ast);
		var base = analysis("base", [], _ -> 1);
		var derived = analysis("derived", ["base"], _ -> 2);
		var transitive = analysis("transitive", ["derived"], _ -> 3);
		var unrelated = analysis("unrelated", [], _ -> 3);

		manager.get(base);
		manager.get(derived);
		manager.get(transitive);
		manager.get(unrelated);
		manager.invalidate("base");

		assertFalse(manager.isCached("base"), "invalidated analysis is removed");
		assertFalse(manager.isCached("derived"), "dependant analysis is invalidated transitively");
		assertFalse(manager.isCached("transitive"), "transitive dependant is invalidated");
		assertTrue(manager.isCached("unrelated"), "unrelated analysis remains cached");
		assertEquals(1, manager.cacheSize(), "cache accounting keeps only the unrelated result");

		manager.get(base);
		manager.get(derived);
		manager.get(transitive);
		manager.advanceRevision(ast, 1, ["derived", "transitive"]);
		assertFalse(manager.isCached("derived"), "a dependant cannot survive without its dependency");
		assertFalse(manager.isCached("transitive"), "transitive preservation also requires the full dependency chain");
	}

	static function testDependencyCyclesFailClosed():Void {
		var manager = new AnalysisManager(makeAST(EVar("value")));
		manager.get(analysis("left", ["right"], _ -> 1));
		expectFailure("analysis dependency cycle", () -> manager.get(analysis("right", ["left"], _ -> 2)), "dependency cycle");
	}

	static function testForcedRecomputationDetectsStaleData():Void {
		var computations = 0;
		var first = makeAST(EInteger(1));
		var second = makeAST(EInteger(2));
		var manager = new AnalysisManager(first, true);
		var definition = analysis("integer-value", [], ast -> {
			computations++;
			return switch (ast.def) {
				case EInteger(value): value;
				default: -1;
			};
		});

		assertEquals(1, manager.get(definition), "initial analysis result");
		manager.retainRevision(second);
		expectFailure("forced cached-versus-fresh validation", () -> manager.get(definition), "returned stale data");
		assertEquals(2, manager.get(definition, true), "explicit forced recomputation refreshes the cache");
		assertTrue(computations >= 3, "validation and forced refresh both execute the analysis");
	}

	static function testPrinterIllegalStructuralDigest():Void {
		var before = receiverEffect("before");
		var after = receiverEffect("after");
		var firstDigest = ElixirASTStructuralDigest.digest(before);

		assertEquals(firstDigest, ElixirASTStructuralDigest.digest(before), "structural digest is deterministic");
		assertTrue(firstDigest != ElixirASTStructuralDigest.digest(after), "marker child changes alter the digest");
	}

	static function receiverEffect(operationName:String) {
		return makeAST(EReceiverEffect({
			receiver: {
				varId: 1,
				name: "receiver"
			},
			operation: makeAST(EVar(operationName)),
			resultShape: UpdatedReceiver,
			valueProjection: ReceiverValue,
			writeback: Always
		}));
	}

	static function analysis(id:String, dependencies:Array<String>, compute:reflaxe.elixir.ast.ElixirAST->Int):AnalysisDefinition<Int> {
		return {
			id: id,
			dependencies: dependencies,
			compute: compute,
			equals: (left, right) -> left == right
		};
	}

	static function expectFailure(label:String, operation:Void->Void, expectedMessage:String):Void {
		try {
			operation();
		} catch (error:Dynamic) {
			var message = Std.string(error);
			if (message.indexOf(expectedMessage) < 0)
				throw '$label produced the wrong diagnostic: $message';
			return;
		}
		throw '$label did not fail';
	}

	static function assertTrue(condition:Bool, label:String):Void {
		if (!condition)
			throw label;
	}

	static function assertFalse(condition:Bool, label:String):Void {
		assertTrue(!condition, label);
	}

	static function assertEquals<T>(expected:T, actual:T, label:String):Void {
		if (expected != actual)
			throw '$label: expected $expected, got $actual';
	}
}
#end
