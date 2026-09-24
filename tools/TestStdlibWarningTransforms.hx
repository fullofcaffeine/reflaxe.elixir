package tools;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST.ElixirAST as ElixirASTNode;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.transformers.BareLiteralDropTransforms;
import reflaxe.elixir.ast.transformers.BinderTransforms;
import reflaxe.elixir.ast.transformers.LocalAssignUnusedUnderscoreScopedTransforms;
import reflaxe.elixir.ast.transformers.FinalUnderscoreRepairTransforms;
import reflaxe.elixir.ast.transformers.ShadowedInitAssignPruneTransforms;
import reflaxe.elixir.ast.transformers.IfConstSimplifyTransforms;
import reflaxe.elixir.ast.transformers.UnderscorePromoteByUseLateTransforms;
import reflaxe.elixir.ast.transformers.CaseTupleBinderUnshadowTransforms;

/** Focused executable contracts for warning-producing upstream stdlib AST shapes. */
@:nullSafety(Off)
class TestStdlibWarningTransforms {
	public static function run():Expr {
		testPatternExpressionReads();
		testNumericResultBlockKinds();
		testSuccessBinderLexicalScope();
		testSuccessCaseDoesNotGuessPayload();
		testLateSuccessCaseDoesNotGuessPayload();
		testDiscriminantInliningBoundary();
		testCaseMergeKeepsInputBindings();
		testNumericCleanupKeepsCapturedNames();
		testCaseAliasKeepsOuterBinding();
		testEnumExtractionKeepsLiveAliases();
		testEnumExtractionKeepsShadowedSource();
		testMapKeysStructuralDispatchBoundary();
		testNonEnumCaseKeepsCapturedBindings();
		testComplexConditionKeepsBothOperands();
		testLoopRenameKeepsMutationTarget();
		testNativeCaseAlternativesStayDistinct();
		testChangesetPassLeavesOrdinaryFunctions();
		testHeexAssignsRebinding();
		testUsedAliasBinding();
		testNestedTupleBinderScope();
		testBooleanAliasConditions();
		testLateBinderScope();
		testConstantCondBranches();
		testInterpolationKeepsBindingStructure();
		testFinalAssignmentValue();
		testOverwrittenLocalBinding();
		testUnaryOperandGrouping();
		testKnownNilRemovesUnreachableShift();
		testKnownNonNilFoldsNegatedCheck();
		testKnownNonNilFoldsBooleanIdentity();
		testTupleMatchForgetsKnownNil();
		testBranchAssignmentForgetsKnownNil();
		testDiscardedIfRemovesSignedBranchTail();

		Sys.println("Stdlib warning transform contracts passed");
		return macro null;
	}

	/** Nested patterns and guard-only uses participate in the same lexical binding contract. */
	static function testSuccessBinderLexicalScope():Void {
		var inner = makeAST(ECase(makeAST(EVar("inner")), [
			{
				pattern: PTuple([PLiteral(makeAST(EAtom("ok"))), PVar("_payload")]),
				body: makeAST(EString("#{payload.slug}"))
			}
		]));
		var outer = makeAST(ECase(makeAST(EVar("outer")), [
			{
				pattern: PTuple([PLiteral(makeAST(EAtom("ok"))), PVar("payload")]),
				body: inner
			}
		]));
		var source = makeAST(EDef("probe", [PVar("outer"), PVar("inner")], null, outer));
		var nestedResult = reflaxe.elixir.ast.transformers.SuccessVarAbsoluteReplaceUndefinedTransforms.replacePass(source);
		if (ElixirASTPrinter.printAST(nestedResult) != ElixirASTPrinter.printAST(source))
			fail("An inner underscore binder must not capture an outer pattern payload.");
		assertSuccessCleanupStable(nestedResult);
		for (hasOuter in [false, true]) {
			var args:Array<reflaxe.elixir.ast.ElixirAST.EPattern> = hasOuter ? [PVar("input"), PVar("payload")] : [PVar("input")];
			function guarded(binder:String):ElixirASTNode {
				return makeAST(EDef("probe", args, null, makeAST(ECase(makeAST(EVar("input")), [
					{
						pattern: PTuple([PLiteral(makeAST(EAtom("ok"))), PVar(binder)]),
						guard: makeAST(EVar("payload")),
						body: makeAST(EAtom("ok"))
					}
				]))));
			}
			var actual = reflaxe.elixir.ast.transformers.SuccessVarAbsoluteReplaceUndefinedTransforms.replacePass(guarded("_payload"));
			if (ElixirASTPrinter.printAST(actual) != ElixirASTPrinter.printAST(guarded(hasOuter ? "_payload" : "payload")))
				fail("Guard-only spelling alignment must retain outer bindings.");
			assertSuccessCleanupStable(actual);
		}
	}

	/** Registry replay must not change an already aligned binder or capture another scope. */
	static function assertSuccessCleanupStable(first:ElixirASTNode):Void {
		var before = ElixirASTPrinter.printAST(first);
		var second = reflaxe.elixir.ast.transformers.SuccessVarAbsoluteReplaceUndefinedTransforms.replacePass(first);
		if (ElixirASTPrinter.printAST(second) != before)
			fail("Repeating success binder cleanup must leave generated output unchanged.");
	}

	/** An undefined or captured name is not evidence that it denotes the nearest success payload. */
	static function testSuccessCaseDoesNotGuessPayload():Void {
		for (reference in ["record", "unresolved"]) {
			var inner = makeAST(ECase(makeAST(EVar("inner")), [
				{
					pattern: PTuple([PLiteral(makeAST(EAtom("ok"))), PVar("_value")]),
					body: makeAST(EString("#{" + reference + ".slug}"))
				}
			]));
			var outer = makeAST(ECase(makeAST(EVar("outer")), [
				{
					pattern: PTuple([PLiteral(makeAST(EAtom("ok"))), PVar("record")]),
					body: inner
				}
			]));
			var source = makeAST(EDef("probe", [PVar("outer"), PVar("inner")], null, outer));
			var actual = reflaxe.elixir.ast.transformers.SuccessVarAbsoluteReplaceUndefinedTransforms.replacePass(source);
			if (ElixirASTPrinter.printAST(actual) != ElixirASTPrinter.printAST(source))
				fail("Success-case cleanup must not guess which payload a reference denotes.");
		}
	}

	/** Missing references must remain errors, not acquire the value of an unrelated result. */
	static function testLateSuccessCaseDoesNotGuessPayload():Void {
		// A free use of the exact spelling may restore that binder's underscore,
		// but a same-named function argument remains an independent outer value.
		for (hasOuter in [false, true]) {
			var body = makeAST(EString("#{payload.slug}"));
			var source = makeAST(EDef("probe", hasOuter ? [PVar("input"), PVar("payload")] : [PVar("input")], null, makeAST(ECase(makeAST(EVar("input")), [
				{
					pattern: PTuple([PLiteral(makeAST(EAtom("ok"))), PVar("_payload")]),
					body: body
				}
			]))));
			var expected = makeAST(EDef("probe", hasOuter ? [PVar("input"), PVar("payload")] : [PVar("input")], null, makeAST(ECase(makeAST(EVar("input")), [
				{
					pattern: PTuple([PLiteral(makeAST(EAtom("ok"))), PVar(hasOuter ? "_payload" : "payload")]),
					body: body
				}
			]))));
			var actual = reflaxe.elixir.ast.transformers.SuccessVarAbsoluteReplaceUndefinedTransforms.replacePass(source);
			if (ElixirASTPrinter.printAST(actual) != ElixirASTPrinter.printAST(expected))
				fail("Success binder spelling must preserve independently bound outer values.");
			assertSuccessCleanupStable(actual);
		}
		for (binder in ["payload", "_payload"]) {
			var branch = makeAST(ECase(makeAST(EVar("input")), [
				{
					pattern: PTuple([PLiteral(makeAST(EAtom("ok"))), PVar(binder)]),
					body: makeAST(EString("#{missing.slug}"))
				}
			]));
			var source = makeAST(EDef("probe", [PVar("input")], null, branch));
			var actual = reflaxe.elixir.ast.transformers.SuccessVarAbsoluteReplaceUndefinedTransforms.replacePass(source);
			if (ElixirASTPrinter.printAST(actual) != ElixirASTPrinter.printAST(source))
				fail("Late success cleanup must preserve unresolved references instead of assigning payload identity.");
		}
	}

	/** Keys and binary sizes read existing bindings even when no clause body does. */
	static function testPatternExpressionReads():Void {
		var patterns:Array<reflaxe.elixir.ast.ElixirAST.EPattern> = [
			PMap([{key: makeAST(EPin(makeAST(EVar("saved")))), value: PWildcard}]),
			PBinary([{pattern: PWildcard, size: makeAST(EVar("saved")), type: "binary"}])
		];
		for (pattern in patterns) {
			var branch = makeAST(ECase(makeAST(EVar("saved")), [{pattern: pattern, body: makeAST(EInteger(7))}]));
			var source = makeAST(EDef("probe", [], null, makeAST(EBlock([makeAST(EMatch(PVar("saved"), makeAST(ECall(null, "observe", [])))), branch]))));
			for (actual in [
				reflaxe.elixir.ast.transformers.DiscriminantRewriteTransforms.discriminantRewritePass(source),
				reflaxe.elixir.ast.transformers.CaseResultAssignmentMergeTransforms.pass(source)
			])
				if (ElixirASTPrinter.printAST(actual) != ElixirASTPrinter.printAST(source))
					fail("A pattern key or binary size must retain its input binding.");
		}
	}

	/** Ordinary blocks preserve numeric returns; legacy do-block printing still drops bare sentinels. */
	static function testNumericResultBlockKinds():Void {
		for (value in [0, 1]) {
			var tail = makeAST(EInteger(value));
			tail.metadata.sourceExpr = Context.typeExpr(macro $v{value});
			for (isDo in [false, true]) {
				var statements = [makeAST(ECall(null, "observe", [])), tail];
				var definition = makeAST(EDef("probe", [], null, makeAST(isDo ? EDo(statements) : EBlock(statements))));
				definition.metadata.functionResultContract = Value;
				var state = reflaxe.elixir.ast.validation.FunctionResultInvariant.capture(definition, "Probe").get("Probe.probe/0");
				if (state == null || (state.problem != null) != isDo)
					fail("Result validation must distinguish preserved block tails from discarded do-block tails.");
			}
		}
	}

	/** Only adjacent single-use inputs can move into a case without losing bindings or repeating effects. */
	static function testDiscriminantInliningBoundary():Void {
		function functionBody(statements:Array<ElixirASTNode>):ElixirASTNode {
			return makeAST(EDef("probe", [], null, makeAST(EBlock(statements))));
		}
		var init = makeAST(ECall(null, "observe", []));
		var binding = makeAST(EMatch(PVar("saved"), init));
		var simpleCase = makeAST(ECase(makeAST(EVar("saved")), [{pattern: PWildcard, body: makeAST(EInteger(1))}]));
		var source = functionBody([binding, simpleCase]);
		var actual = reflaxe.elixir.ast.transformers.DiscriminantRewriteTransforms.discriminantRewritePass(source);
		var expected = functionBody([makeAST(ECase(init, [{pattern: PWildcard, body: makeAST(EInteger(1))}]))]);
		if (ElixirASTPrinter.printAST(actual) != ElixirASTPrinter.printAST(expected))
			fail("An adjacent single-use named discriminant must evaluate its initializer exactly once.");
		var assigned = functionBody([binding, makeAST(EMatch(PVar("answer"), simpleCase)), makeAST(EVar("answer"))]);
		var assignedExpected = functionBody([
			makeAST(EMatch(PVar("answer"), makeAST(ECase(init, [{pattern: PWildcard, body: makeAST(EInteger(1))}])))),
			makeAST(EVar("answer"))
		]);
		var assignedResult = reflaxe.elixir.ast.transformers.DiscriminantRewriteTransforms.discriminantRewritePass(assigned);
		if (ElixirASTPrinter.printAST(assignedResult) != ElixirASTPrinter.printAST(assignedExpected))
			fail("Inlining a case input must preserve the separate case-result assignment.");
		var nested = functionBody([makeAST(EBlock([binding, simpleCase])), makeAST(EVar("saved"))]);
		var nestedResult = reflaxe.elixir.ast.transformers.DiscriminantRewriteTransforms.discriminantRewritePass(nested);
		if (ElixirASTPrinter.printAST(nestedResult) != ElixirASTPrinter.printAST(nested))
			fail("A nested block binding can still be read by its enclosing function.");
		var captured = functionBody([
			binding,
			simpleCase,
			makeAST(EFn([{args: [], guard: null, body: makeAST(EVar("saved"))}]))
		]);
		var capturedResult = reflaxe.elixir.ast.transformers.DiscriminantRewriteTransforms.discriminantRewritePass(captured);
		if (ElixirASTPrinter.printAST(capturedResult) != ElixirASTPrinter.printAST(captured))
			fail("A later closure must retain its captured case input.");
		var cases:Array<ElixirASTNode> = [
			makeAST(ECase(makeAST(EVar("saved")), [{pattern: PWildcard, body: makeAST(EVar("saved"))}])),
			makeAST(ECase(makeAST(EVar("saved")), [{pattern: PPin(PVar("saved")), body: makeAST(EInteger(1))}])),
			makeAST(ECase(makeAST(EVar("saved")), [{pattern: PWildcard, guard: makeAST(EVar("saved")), body: makeAST(EInteger(1))}]))
		];
		for (caseExpr in cases) {
			var retained = functionBody([binding, caseExpr]);
			var result = reflaxe.elixir.ast.transformers.DiscriminantRewriteTransforms.discriminantRewritePass(retained);
			if (ElixirASTPrinter.printAST(result) != ElixirASTPrinter.printAST(retained))
				fail("Discriminant inlining must preserve clause reads, pins, and guards.");
		}
		for (name in ["saved", "_g"]) {
			var bind = makeAST(EMatch(PVar(name), init));
			var match = makeAST(ECase(makeAST(EVar(name)), [{pattern: PWildcard, body: makeAST(EInteger(1))}]));
			for (statements in [
				[bind, match, makeAST(EVar(name))],
				[bind, makeAST(ECall(null, "effect", [])), match]
			]) {
				var retained = functionBody(statements);
				var result = reflaxe.elixir.ast.transformers.DiscriminantRewriteTransforms.discriminantRewritePass(retained);
				if (ElixirASTPrinter.printAST(result) != ElixirASTPrinter.printAST(retained))
					fail("Discriminant inlining must preserve later reads and intervening effects.");
			}
		}
	}

	/** A case result cannot replace an input still read in a branch, pin, guard, or suffix. */
	static function testCaseMergeKeepsInputBindings():Void {
		var initializer = makeAST(EMatch(PVar("effect_result"), makeAST(ECall(null, "observe", []))));
		var clauses:Array<reflaxe.elixir.ast.ElixirAST.ECaseClause> = [{pattern: PWildcard, body: makeAST(EInteger(1))}];
		var eligible = makeAST(EDef("probe", [], null, makeAST(EBlock([
			makeAST(EMatch(PVar("saved"), initializer)),
			makeAST(ECase(makeAST(EVar("saved")), clauses))
		]))));
		var expected = makeAST(EDef("probe", [], null, makeAST(EBlock([makeAST(EMatch(PVar("saved"), makeAST(ECase(initializer, clauses))))]))));
		if (ElixirASTPrinter.printAST(reflaxe.elixir.ast.transformers.CaseResultAssignmentMergeTransforms.pass(eligible)) != ElixirASTPrinter.printAST(expected))
			fail("Eligible case merging must retain the complete effectful initializer exactly once.");
		var binding = makeAST(EMatch(PVar("saved"), makeAST(EInteger(7))));
		var cases:Array<ElixirASTNode> = [
			makeAST(ECase(makeAST(EVar("saved")), [{pattern: PWildcard, body: makeAST(EVar("saved"))}])),
			makeAST(ECase(makeAST(EVar("saved")), [{pattern: PPin(PVar("saved")), body: makeAST(EInteger(1))}])),
			makeAST(ECase(makeAST(EVar("saved")), [{pattern: PWildcard, guard: makeAST(EVar("saved")), body: makeAST(EInteger(1))}]))
		];
		for (caseExpr in cases) {
			var source = makeAST(EDef("probe", [], null, makeAST(EBlock([binding, caseExpr]))));
			var actual = reflaxe.elixir.ast.transformers.CaseResultAssignmentMergeTransforms.pass(source);
			if (ElixirASTPrinter.printAST(actual) != ElixirASTPrinter.printAST(source))
				fail("Case merging must retain a captured input binding.");
		}
		var simpleCase = makeAST(ECase(makeAST(EVar("saved")), [{pattern: PWildcard, body: makeAST(EInteger(1))}]));
		var withSuffix = makeAST(EDef("probe", [], null, makeAST(EBlock([binding, simpleCase, makeAST(EVar("saved"))]))));
		var actual = reflaxe.elixir.ast.transformers.CaseResultAssignmentMergeTransforms.pass(withSuffix);
		if (ElixirASTPrinter.printAST(actual) != ElixirASTPrinter.printAST(withSuffix))
			fail("Case merging must not replace the input read after the case.");
	}

	/** Cosmetic names must not capture an outer value, including after underscore promotion. */
	static function testNumericCleanupKeepsCapturedNames():Void {
		for (captured in ["g_value", "_g_value", "_g"]) {
			var input = makeAST(ECase(makeAST(EVar("input")), [
				{
					pattern: PTuple([PVar("_g3"), PVar("_g")]),
					body: makeAST(EVar(captured))
				}
			]));
			var actual = reflaxe.elixir.ast.transformers.NumericSuffixVarNormalizeTransforms.normalizePass(input);
			switch (actual.def) {
				case ECase(_, [{pattern: PTuple([PVar(name), _]), body: {def: EVar(read)}}]):
					if (read != captured || name == captured || name == "_" + captured)
						fail("Cosmetic numeric cleanup must not capture a distinct enclosing variable.");
				default:
					fail("Numeric cleanup changed the case shape.");
			}
		}
	}

	/** A case body can read a saved value from its enclosing lexical scope. */
	static function testCaseAliasKeepsOuterBinding():Void {
		var source = makeAST(ECase(makeAST(EVar("input")), [
			{
				pattern: PWildcard,
				body: makeAST(EBlock([makeAST(EMatch(PVar("value"), makeAST(EVar("_g2")))), makeAST(EVar("value"))]))
			}
		]));
		var actual = BinderTransforms.casePatternTempAssignmentRemovalPass(source);
		if (ElixirASTPrinter.printAST(actual) != ElixirASTPrinter.printAST(source))
			fail("A case-local scan cannot declare an enclosing temporary undefined.");
	}

	/** Pattern extraction must not delete saved payloads still read by the clause. */
	static function testEnumExtractionKeepsLiveAliases():Void {
		var statements = [
			makeAST(EMatch(PVar("_g"), makeAST(EVar("first")))),
			makeAST(EMatch(PVar("_g2"), makeAST(EVar("last")))),
			makeAST(EMatch(PVar("first"), makeAST(EVar("_g")))),
			makeAST(EMatch(PVar("last"), makeAST(EVar("_g2")))),
			makeAST(ETuple([makeAST(EVar("first")), makeAST(EVar("middle")), makeAST(EVar("last"))]))
		];
		var input = makeAST(ECase(makeAST(EVar("input")), [
			{
				pattern: PTuple([
					PLiteral(makeAST(EAtom("channels"))),
					PVar("first"),
					PVar("middle"),
					PVar("last")
				]),
				guard: null,
				body: makeAST(EBlock(statements))
			}
		]));
		for (result in [ElixirASTTransformer.alias_removeRedundantEnumExtractionPass(input)]) {
			switch (result.def) {
				case ECase(_, [{body: {def: EBlock(actual)}}]):
					if (actual.length != statements.length)
						fail("enum extraction must retain live payload aliases instead of leaving undefined reads");
					for (i in 0...statements.length)
						assertNode(actual[i], statements[i].def, "enum extraction must preserve distinct payload values");
				default:
					fail("live enum payload alias block changed shape");
			}
		}

		var read = makeAST(EVar("value"));
		var extraction = makeAST(EMatch(PVar("value"), makeAST(ECall(null, "elem", [makeAST(EVar("input")), makeAST(EInteger(1))]))));
		var otherSlot = makeAST(EMatch(PVar("value"), makeAST(ECall(null, "elem", [makeAST(EVar("input")), makeAST(EInteger(2))]))));
		var effect = makeAST(ECall(null, "observe", []));
		for (example in [
			{input: [extraction, read], expected: [read]},
			{input: [otherSlot, read], expected: [otherSlot, read]},
			{input: [effect, extraction, read], expected: [effect, extraction, read]},
			{input: [extraction], expected: [extraction]}
		]) {
			var source = makeAST(ECase(makeAST(EVar("input")), [
				{
					pattern: PTuple([PLiteral(makeAST(EAtom("some"))), PVar("value")]),
					guard: null,
					body: makeAST(EBlock(example.input))
				}
			]));
			var actual = ElixirASTTransformer.alias_removeRedundantEnumExtractionPass(source);
			switch (actual.def) {
				case ECase(_, [{body: {def: EBlock(statements)}}]):
					if (statements.length != example.expected.length)
						fail("enum extraction must prove the exact payload slot and preserve later or final assignments");
					for (i in 0...statements.length)
						assertNode(statements[i], example.expected[i].def, "enum extraction changed a retained expression");
				default:
					fail("exact extraction contract changed shape");
			}
		}
	}

	/** A clause can bind the source name to a different tuple before extraction. */
	static function testEnumExtractionKeepsShadowedSource():Void {
		var patterns:Array<reflaxe.elixir.ast.ElixirAST.EPattern> = [PVar("input"), PTuple([PVar("input")])];
		for (sourcePattern in patterns) {
			var input = makeAST(ECase(makeAST(EVar("input")), [
				{
					pattern: PTuple([PLiteral(makeAST(EAtom("pair"))), PVar("value"), sourcePattern]),
					guard: null,
					body: makeAST(EBlock([
						makeAST(EMatch(PVar("value"), makeAST(ECall(null, "elem", [makeAST(EVar("input")), makeAST(EInteger(1))])))),
						makeAST(EVar("value"))
					]))
				}
			]));
			if (ElixirASTPrinter.printAST(ElixirASTTransformer.alias_removeRedundantEnumExtractionPass(input)) != ElixirASTPrinter.printAST(input))
				fail("enum extraction must retain reads from a source rebound by the clause pattern");
		}
	}

	/** Recognizing iterator scaffolding must not erase altered dispatch or effects. */
	@:access(reflaxe.elixir.ast.transformers.MapKeysIteratorReduceWhileRewriteTransforms)
	static function testMapKeysStructuralDispatchBoundary():Void {
		function call(method:String, fallbackMethod:String, withEffect:Bool):ElixirASTNode {
			var receiver = makeAST(EVar("bound"));
			var module = makeAST(EBinary(OrElse, makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [receiver, makeAST(EAtom("__reflaxe_class__"))])),
				makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [receiver, makeAST(EAtom("__struct__"))]))));
			var callback = makeAST(ECall(makeAST(EVar("callback")), "", []));
			if (withEffect)
				callback = makeAST(EBlock([makeAST(ECall(null, "effect", [])), callback]));
			var dispatch = makeAST(ECase(makeAST(ERemoteCall(makeAST(EVar("Map")), "fetch", [receiver, makeAST(EAtom(method))])), [
				{pattern: PTuple([PLiteral(makeAST(EAtom("ok"))), PVar("callback")]), body: callback},
				{
					pattern: PLiteral(makeAST(EAtom("error"))),
					body: makeAST(ECall(null, "apply", [module, makeAST(EAtom(fallbackMethod)), makeAST(EList([receiver]))]))
				}
			]));
			return makeAST(ECase(makeAST(EVar("keys")), [{pattern: PVar("bound"), body: dispatch}]));
		}
		for (method in ["has_next", "next"]) {
			var matched = reflaxe.elixir.ast.transformers.MapKeysIteratorReduceWhileRewriteTransforms.extractStructuralCallReceiver(call(method, method,
				false), method);
			if (matched != "keys")
				fail("Map-key loop recognition must support exact structural dispatch.");
			for (different in [
				call(method, "other", false),
				call(method, method, true),
				call("other", "other", false)
			]) {
				if (reflaxe.elixir.ast.transformers.MapKeysIteratorReduceWhileRewriteTransforms.extractStructuralCallReceiver(different, method) != null)
					fail("Map-key loop recognition must preserve extra effects and changed dispatch.");
			}
		}
	}

	/** Renaming loop state must rename the write target as well as its value. */
	@:access(reflaxe.elixir.ast.builders.LoopBuilder)
	static function testLoopRenameKeepsMutationTarget():Void {
		var effect = makeAST(EReceiverEffect({
			receiver: {varId: 73, name: "count"},
			operation: makeAST(ETuple([
				makeAST(EBinary(Add, makeAST(EVar("count")), makeAST(EInteger(1)))),
				makeAST(EVar("count"))
			])),
			resultShape: UpdatedReceiverAndValue,
			valueProjection: CompanionValue,
			writeback: Always
		}));
		var actual = reflaxe.elixir.ast.builders.LoopBuilder.transformExpressionWithMapping(effect, ["count" => "carried_count"]);
		switch (actual.def) {
			case EReceiverEffect(updated):
				if (updated.receiver.name != "carried_count" || updated.receiver.varId != 73)
					fail("Loop state renaming must preserve mutation identity and update its write target.");
				switch (updated.operation.def) {
					case ETuple([
						{def: EBinary(Add, {def: EVar("carried_count")}, _)},
						{def: EVar("carried_count")}
					]):
					default: fail("Loop mutation reads and writes must select the same state binding.");
				}
			default:
				fail("Loop state renaming must preserve the mutation contract.");
		}
	}

	/** Parenthesizing conditions must preserve distinct operands and lazy right-side effects. */
	static function testComplexConditionKeepsBothOperands():Void {
		var left = makeAST(EIf(makeAST(EVar("choose_left")), makeAST(EBoolean(true)), makeAST(EBoolean(false))));
		var right = makeAST(EIf(makeAST(EVar("choose_right")), makeAST(ECall(null, "right_effect", [])), makeAST(EBoolean(false))));
		for (condition in [
			makeAST(EBinary(OrElse, left, right)),
			makeAST(EBinary(AndAlso, makeAST(EVar("gate")), right))
		]) {
			var branch = makeAST(EAtom("matched"));
			var input = makeAST(EIf(condition, branch, null));
			var expected = makeAST(EIf(makeAST(EParen(condition)), branch, null));
			var actual = reflaxe.elixir.ast.transformers.IfConditionComplexHoistTransforms.pass(input);
			if (ElixirASTPrinter.printAST(actual) != ElixirASTPrinter.printAST(expected))
				fail("Complex condition repair must not duplicate the left operand or eagerly evaluate the right operand.");
		}
	}

	/** An array-length branch has no enum payload that can replace its locals. */
	static function testNonEnumCaseKeepsCapturedBindings():Void {
		var patterns:Array<reflaxe.elixir.ast.ElixirAST.EPattern> = [PLiteral(makeAST(EInteger(3))), PList([PVar("item")])];
		for (pattern in patterns) {
			var source = makeAST(ECase(makeAST(EVar("input")), [
				{
					pattern: pattern,
					body: makeAST(EBlock([makeAST(EMatch(PVar("_g"), makeAST(EVar("saved")))), makeAST(EVar("_g"))]))
				}
			]));
			var actual = ElixirASTTransformer.alias_removeRedundantEnumExtractionPass(source);
			if (ElixirASTPrinter.printAST(actual) != ElixirASTPrinter.printAST(source))
				fail("Enum extraction must preserve ordinary numeric/list case bindings.");
		}
	}

	/** Native atoms and tagged tuples are distinct values, not style variants. */
	static function testNativeCaseAlternativesStayDistinct():Void {
		var body = makeAST(ECase(makeAST(EVar("input")), [
			{pattern: PTuple([PLiteral(makeAST(EAtom("ok"))), PVar("value")]), body: makeAST(EVar("value"))},
			{pattern: PLiteral(makeAST(EAtom("error"))), body: makeAST(EInteger(2))},
			{pattern: PTuple([PLiteral(makeAST(EAtom("error")))]), body: makeAST(EInteger(3))}
		]));
		var actual = makeAST(EDef("native_result", [PVar("input")], null, body));
		for (pass in reflaxe.elixir.ast.transformers.registry.ElixirASTPassRegistry.getEnabledPasses()) {
			actual = pass.pass(actual);
			var printed = ElixirASTPrinter.printAST(actual);
			if (printed.indexOf(":error ->") < 0 || printed.indexOf("{:error} ->") < 0)
				fail("Native atom and tuple alternatives must remain distinct after " + pass.name);
		}
	}

	/** Diagnostic defines must not turn an Ecto-only repair into a generic rewrite. */
	static function testChangesetPassLeavesOrdinaryFunctions():Void {
		var source = makeAST(EDef("probe", [], null, makeAST(EInteger(42))));
		var actual = reflaxe.elixir.ast.transformers.ChangesetEnsureReturnTransforms.pass(source);
		if (ElixirASTPrinter.print(actual) != ElixirASTPrinter.print(source))
			fail("changeset return repair must leave a non-Ecto function unchanged");
	}

	/** HEEx reads the current assigns map even without an explicit EVar node. */
	static function testHeexAssignsRebinding():Void {
		for (sigil in ["H", "h"]) {
			for (name in ["assigns", "message"]) {
				var template = name == "assigns" ? "<p>{@message}</p>" : "<p><%= message %></p>";
				var body = makeAST(EBlock([
					makeAST(EMatch(PVar(name), makeAST(EVar("updated")))),
					makeAST(ESigil(sigil, template, ""))
				]));
				var source = makeAST(EDef("render", [PVar(name), PVar("updated")], null, body));
				var actual = ElixirASTPrinter.print(LocalAssignUnusedUnderscoreScopedTransforms.pass(source));
				if (actual != ElixirASTPrinter.print(source))
					fail("HEEx must consume the updated binding, including implicit assigns: " + name + "\n" + actual);
			}
		}
	}

	/** A used local stays bound even when its spelling resembles a web helper. */
	static function testUsedAliasBinding():Void {
		for (name in ["data", "json", "conn"]) {
			var binding = makeAST(EMatch(PVar(name), makeAST(ECall(null, "observe", []))));
			var body = makeAST(EBlock([binding, makeAST(EVar(name))]));
			var source = makeAST(EDefmodule("SampleWeb.Probe", makeAST(EDef("probe", [], null, body))));
			if (ElixirASTPrinter.print(LocalAssignUnusedUnderscoreScopedTransforms.pass(source)) != ElixirASTPrinter.print(source))
				fail("used alias binding must retain its value and declaration: " + name);
			// Native extern bodies retain their references as opaque target code.
			// The compiler must not rename a binder without updating those reads.
			for (nested in [false, true]) {
				var nativeBody = makeAST(EBlock([binding, makeAST(ERaw('consume(' + name + ')'))]));
				var body = nested ? makeAST(EIf(makeAST(EVar("enabled")), nativeBody, makeAST(EInteger(0)))) : nativeBody;
				var nativeSource = makeAST(EDefmodule("SampleWeb.Probe", makeAST(EDef("probe", nested ? [PVar("enabled")] : [], null, body))));
				nativeSource.metadata.isPhoenixWeb = true;
				var emitted = ElixirASTPrinter.print(ElixirASTTransformer.transform(nativeSource));
				var lines = emitted.split("\n").map(StringTools.trim);
				if (!lines.contains(name + ' = observe()') || !lines.contains('consume(' + name + ')'))
					fail("native extern reads must keep their declared local through the full pipeline: " + name + "\n" + emitted);
			}
		}
	}

	/** A name bound by a nested pattern or closure is not an undefined outer local. */
	static function testNestedTupleBinderScope():Void {
		var value = makeAST(EVar("value"));
		var inner = makeAST(ECase(value, [
			{pattern: PTuple([PLiteral(makeAST(EAtom("success"))), PVar("number")]), guard: null, body: makeAST(EVar("number"))},
			{pattern: PWildcard, guard: null, body: makeAST(EInteger(-1))}
		]));
		var closure = makeAST(EFn([{args: [PVar("number")], guard: null, body: makeAST(EVar("number"))}]));
		for (body in [inner, closure]) {
			var source = makeAST(EDefp("probe", [PVar("value")], null, makeAST(ECase(value, [
				{pattern: PTuple([PLiteral(makeAST(EAtom("success"))), PVar("value")]), guard: null, body: body}
			]))));
			switch (CaseTupleBinderUnshadowTransforms.pass(source).def) {
				case EDefp(_, _, _, {def: ECase(_, [{body: actual}])}):
					if (ElixirASTPrinter.print(actual) != ElixirASTPrinter.print(body))
						fail("nested binders must not create an outer repair assignment");
				default:
					fail("tuple binder repair changed the function shape");
			}
		}
		var missing = makeAST(EDefp("probe", [PVar("value")], null, makeAST(ECase(value, [
			{pattern: PTuple([PLiteral(makeAST(EAtom("success"))), PVar("value")]), guard: null, body: makeAST(EVar("payload"))}
		]))));
		switch (CaseTupleBinderUnshadowTransforms.pass(missing).def) {
			case EDefp(_, _, _, {
				def: ECase(_, [
					{body: {def: EBlock([{def: EBinary(Match, {def: EVar("payload")}, {def: EVar("value")})}, _])}}
				])
			}):
			default:
				fail("the existing genuinely free payload repair must remain available");
		}
	}

	/** Boolean facts follow sequential aliases, but unknown writes invalidate them. */
	static function testBooleanAliasConditions():Void {
		var source = makeAST(EMatch(PVar("source"), makeAST(EBoolean(true))));
		var alias = makeAST(EMatch(PVar("active"), makeAST(EVar("source"))));
		var condition = makeAST(EIf(makeAST(EUnary(Not, makeAST(EVar("active")))), makeAST(EInteger(1)), makeAST(EInteger(2))));
		var folded = IfConstSimplifyTransforms.transformPass(makeAST(EBlock([source, alias, condition])));
		switch (folded.def) {
			case EBlock([_, _, {def: EInteger(2)}]):
			default:
				fail("a known Boolean alias must fold a negated condition");
		}
		var unknown = makeAST(EMatch(PVar("active"), makeAST(ECall(null, "observe", []))));
		var changed = IfConstSimplifyTransforms.transformPass(makeAST(EBlock([source, alias, unknown, condition])));
		switch (changed.def) {
			case EBlock([_, _, {def: EMatch(_, {def: ECall(null, "observe", [])})}, {def: EIf(_, _, _)}]):
			default:
				fail("an unknown reassignment must retain its effect and invalidate the Boolean fact");
		}
		var closure = makeAST(EFn([{args: [PVar("active")], guard: null, body: condition}]));
		var scoped = IfConstSimplifyTransforms.transformPass(makeAST(EBlock([source, alias, closure])));
		switch (scoped.def) {
			case EBlock([_, _, {def: EFn([{body: {def: EIf(_, _, _)}}])}]):
			default:
				fail("a closure parameter must not inherit the outer Boolean fact");
		}
		var conditionalWrite = makeAST(EIf(makeAST(EVar("enabled")), makeAST(EMatch(PVar("active"), makeAST(EBoolean(false)))), null));
		var afterBranch = IfConstSimplifyTransforms.transformPass(makeAST(EBlock([source, alias, conditionalWrite, condition])));
		switch (afterBranch.def) {
			case EBlock([_, _, _, {def: EIf(_, _, _)}]):
			default:
				fail("a conditional write must invalidate facts after the branch");
		}
		var nested = makeAST(EIf(makeAST(EVar("enabled")), makeAST(EInteger(0)), makeAST(EBlock([alias, condition]))));
		var nestedOutput = IfConstSimplifyTransforms.transformPass(makeAST(EBlock([source, nested])));
		switch (nestedOutput.def) {
			case EBlock([_, {def: EIf(_, _, {def: EBlock([_, {def: EInteger(2)}])})}]):
			default:
				fail("a branch must retain safe incoming facts for its sequential aliases");
		}
		var patternScope = makeAST(ECase(makeAST(EVar("input")), [{pattern: PVar("active"), guard: null, body: condition}]));
		var patternOutput = IfConstSimplifyTransforms.transformPass(makeAST(EBlock([source, alias, patternScope])));
		switch (patternOutput.def) {
			case EBlock([_, _, {def: ECase(_, [{body: {def: EIf(_, _, _)}}])}]):
			default:
				fail("a case pattern must not inherit a same-named outer fact");
		}
	}

	/** Late repairs may promote a missing outer read, never a same-named inner local. */
	static function testLateBinderScope():Void {
		var read = makeAST(EVar("value"));
		for (example in [
			{tail: read, expected: "value"},
			{tail: makeAST(EFn([{args: [], guard: null, body: read}])), expected: "value"},
			{tail: makeAST(EFn([{args: [PVar("value")], guard: null, body: read}])), expected: "_value"},
			{
				tail: makeAST(EBlock([makeAST(EMatch(PVar("value"), makeAST(EInteger(2)))), read])),
				expected: "_value"
			}
		]) {
			var input = makeAST(EBlock([
				makeAST(EMatch(PVar("_value"), makeAST(ECall(null, "observe", [])))),
				example.tail
			]));
			var output = UnderscorePromoteByUseLateTransforms.resultBinderPass(input);
			switch (output.def) {
				case EBlock([{def: EMatch(PVar(name), {def: ECall(null, "observe", [])})}, _]) if (name == example.expected):
				default:
					fail("late binder repair must distinguish captured reads from inner bindings");
			}
		}
	}

	/** Removing literal-false arms must retain dynamic conditions and no-match behavior. */
	static function testConstantCondBranches():Void {
		var impossible = {condition: makeAST(EBoolean(false)), body: makeAST(ECall(null, "unreachable", []))};
		var fallback = {condition: makeAST(EBoolean(true)), body: makeAST(EInteger(42))};
		var simplified = IfConstSimplifyTransforms.transformPass(makeAST(ECond([impossible, fallback])));
		if (!Type.enumEq(simplified.def, fallback.body.def))
			fail("literal-false cond arm must not survive a known fallback");
		var dynamicArm = {condition: makeAST(ECall(null, "observe", [])), body: makeAST(EInteger(7))};
		var dynamicInput = makeAST(ECond([dynamicArm, impossible, fallback]));
		var dynamicOutput = IfConstSimplifyTransforms.transformPass(dynamicInput);
		switch (dynamicOutput.def) {
			case ECond([
				{condition: {def: ECall(null, "observe", [])}, body: {def: EInteger(7)}},
				{condition: {def: EBoolean(true)}, body: {def: EInteger(42)}}
			]):
			default:
				fail("cond simplification must preserve dynamic condition order and effects: " + ElixirASTPrinter.printAST(dynamicOutput));
		}
		var noMatch = makeAST(ECond([impossible]));
		if (!Type.enumEq(IfConstSimplifyTransforms.transformPass(noMatch).def, noMatch.def))
			fail("all-false cond must preserve its no-match failure");
	}

	/** Later hygiene must still be able to see bindings inside a concatenated expression. */
	static function testInterpolationKeepsBindingStructure():Void {
		var binding = makeAST(EMatch(PVar("items"), makeAST(EList([]))));
		var body = makeAST(EBlock([binding, makeAST(EVar("items"))]));
		var closure = makeAST(EFn([{args: [], guard: null, body: body}]));
		var rendered = makeAST(ERemoteCall(makeAST(EVar("Enum")), "join", [makeAST(ECall(closure, "", [])), makeAST(EString(","))]));
		var input = makeAST(EBinary(StringConcat, makeAST(EString("values: ")), rendered));
		var output = ElixirASTTransformer.alias_stringInterpolationPass(input);
		if (!Type.enumEq(output.def, input.def))
			fail("retaining a binding scope must preserve its complete expression and evaluation order");
		switch (output.def) {
			case EBinary(StringConcat, _, _):
			default:
				fail("interpolation serialized a binding before later hygiene could inspect it");
		}
		var simple = makeAST(EBinary(StringConcat, makeAST(EString("value: ")), makeAST(EVar("value"))));
		switch (ElixirASTTransformer.alias_stringInterpolationPass(simple).def) {
			case ERaw(_):
			default:
				fail("simple interpolation should retain its existing representation");
		}
		// A binding need not have a surrounding closure or block to require hygiene.
		for (operand in [binding, makeAST(EBinary(Match, makeAST(EVar("items")), makeAST(EList([]))))]) {
			var call = makeAST(ECall(null, "render", [operand]));
			var concat = makeAST(EBinary(StringConcat, makeAST(EString("items: ")), call));
			if (!Type.enumEq(ElixirASTTransformer.alias_stringInterpolationPass(concat).def, concat.def))
				fail("interpolation must retain nested assignment operands");
		}
	}

	/** A final assignment is also the block's value, including inside another assignment. */
	static function testFinalAssignmentValue():Void {
		for (binary in [false, true]) {
			for (doBlock in [false, true]) {
				var payload = makeAST(ETuple([makeAST(EAtom("success")), makeAST(EInteger(42))]));
				var assignment = binary ? makeAST(EBinary(Match, makeAST(EVar("result")), payload)) : makeAST(EMatch(PVar("result"), payload));
				var body = makeAST(doBlock ? EDo([assignment]) : EBlock([assignment]));
				var input = makeAST(EMatch(PVar("value"), body));
				var output = ShadowedInitAssignPruneTransforms.pass(input);
				switch (output.def) {
					case EMatch(_, {def: EBlock([last]) | EDo([last])}):
						if (!Type.enumEq(last.def, assignment.def))
							fail("final assignment must preserve its value and binding");
					default:
						fail("pruning erased a block's final assignment value");
				}
			}
		}
	}

	/** Later reads use the replacement value, but RHS effects and earlier reads survive. */
	static function testOverwrittenLocalBinding():Void {
		var value = makeAST(EVar("value"));
		var effect = makeAST(ECall(null, "observe", []));
		var replace = makeAST(EMatch(PVar("value"), makeAST(EInteger(2))));
		var read = makeAST(ECall(null, "consume", [value]));
		var capture = makeAST(EMatch(PVar("saved"), makeAST(EFn([{args: [], guard: null, body: value}]))));
		var conditional = makeAST(EIf(makeAST(EVar("enabled")), replace, makeAST(ENil)));
		for (binary in [false, true]) {
			var initial = binary ? makeAST(EBinary(Match, value, effect)) : makeAST(EMatch(PVar("value"), effect));
			for (example in [
				{rest: [replace, value], expectedName: "_value"},
				{
					rest: [
						makeAST(EIf(makeAST(EVar("enabled")), makeAST(EBlock([replace, value])), makeAST(EInteger(0))))
					],
					expectedName: "_value"
				},
				{rest: [makeAST(ERaw("consume(value)"))], expectedName: "value"},
				{rest: [read, replace, value], expectedName: "value"},
				{
					rest: [
						makeAST(EMatch(PVar("value"), makeAST(EBinary(Add, value, makeAST(EInteger(1)))))),
						value
					],
					expectedName: "value"
				},
				{rest: [conditional, value], expectedName: "value"},
				{rest: [capture, replace, makeAST(ETuple([makeAST(EVar("saved")), value]))], expectedName: "value"}
			]) {
				var input = makeAST(EDef("probe", [PVar("enabled")], null, makeAST(EBlock([initial].concat(example.rest)))));
				var output = UnderscorePromoteByUseLateTransforms.resultBinderPass(FinalUnderscoreRepairTransforms.transformPass(LocalAssignUnusedUnderscoreScopedTransforms.pass(input)));
				switch (output.def) {
					case EDef(_, _, _, {def: EBlock(statements)}):
						switch (statements[0].def) {
							case EMatch(PVar(name), {def: ECall(null, "observe", [])}) if (!binary && name == example.expectedName):
							case EBinary(Match, {def: EVar(name)}, {def: ECall(null, "observe", [])}) if (binary && name == example.expectedName):
							default:
								fail("overwritten locals must retain effects and all reads before replacement: expected binder "
									+ example.expectedName
									+ ", got "
									+ ElixirASTPrinter.printAST(statements[0]));
						}
					default:
						fail("local-binding test changed function shape");
				}
			}
		}
		var actualUse = makeAST(EBlock([
			makeAST(EMatch(PVar("_value"), effect)),
			makeAST(ECall(null, "consume", [makeAST(EVar("_value"))]))
		]));
		switch (FinalUnderscoreRepairTransforms.transformPass(actualUse).def) {
			case EBlock([
				{def: EMatch(PVar("value"), {def: ECall(null, "observe", [])})},
				{def: ECall(null, "consume", [{def: EVar("value")}])}
			]):
			default:
				fail("an exact underscored read must still repair its binder and reference");
		}
	}

	/** Prefix operators apply to the complete operand, not its first printed term. */
	static function testUnaryOperandGrouping():Void {
		var left = makeAST(EVar("left"));
		var right = makeAST(EVar("right"));
		var conjunction = makeAST(EBinary(And, left, right));
		var sum = makeAST(EBinary(Add, left, right));
		for (example in [
			{input: makeAST(EUnary(Not, conjunction)), expected: "not (left and right)"},
			{input: makeAST(EUnary(Bang, conjunction)), expected: "!(left and right)"},
			{input: makeAST(EUnary(Negate, sum)), expected: "-(left + right)"},
			{input: makeAST(EUnary(Positive, sum)), expected: "+(left + right)"},
			{input: makeAST(EUnary(Not, makeAST(ERaw("left != nil")))), expected: "not (left != nil)"},
			{input: makeAST(EUnary(Negate, makeAST(ERaw("left + right")))), expected: "-(left + right)"},
			{input: makeAST(EUnary(Not, left)), expected: "not left"}
		]) {
			if (ElixirASTPrinter.printAST(example.input) != example.expected)
				fail("unary printing must preserve the complete binary operand and leave atomic operands unchanged");
		}
	}

	static function testKnownNonNilFoldsBooleanIdentity():Void {
		var assignArgs = makeAST(EMatch(PVar("args"), makeAST(EList([makeAST(EInteger(1))]))));
		var nilCheck = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [makeAST(EVar("args"))]));
		var hasValues = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "length", [makeAST(EVar("args"))]));
		var remainingCondition = makeAST(EBinary(Greater, hasValues, makeAST(EInteger(0))));
		var combined = makeAST(EBinary(And, makeAST(EUnary(Not, nilCheck)), remainingCondition));
		var conditional = makeAST(EIf(combined, makeAST(EAtom("present")), makeAST(EAtom("missing"))));
		var functionNode = makeAST(EDef("children", [], null, makeAST(EBlock([assignArgs, conditional]))));

		var result = BinderTransforms.simplifyProvableIsNilFalsePass(functionNode);

		switch (result.def) {
			case EDef("children", _, _, {def: EBlock([_, {def: EIf(condition, _, _)}])}):
				assertNode(condition, remainingCondition.def, "true and a remaining condition must fold to the remaining condition");
			default:
				fail("boolean-identity function changed shape");
		}
	}

	static function testBranchAssignmentForgetsKnownNil():Void {
		var assignKnownNil = makeAST(EMatch(PVar("found"), makeAST(ENil)));
		var branchAssignment = makeAST(EMatch(PVar("found"), makeAST(EMap([]))));
		var branch = makeAST(EIf(makeAST(EVar("condition")), makeAST(EBlock([branchAssignment])), makeAST(EBlock([]))));
		var nilCheck = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [makeAST(EVar("found"))]));
		var conditional = makeAST(EIf(nilCheck, makeAST(EAtom("missing")), makeAST(EAtom("present"))));
		var functionNode = makeAST(EDef("find", [], null, makeAST(EBlock([assignKnownNil, branch, conditional]))));

		var result = BinderTransforms.simplifyProvableIsNilFalsePass(functionNode);

		switch (result.def) {
			case EDef("find", _, _, {def: EBlock([_, _, {def: EIf(condition, _, _)}])}):
				switch (condition.def) {
					case ERemoteCall({def: EVar("Kernel")}, "is_nil", [{def: EVar("found")}]):
					default:
						fail("an assignment inside a branch must forget the earlier known-nil value");
				}
			default:
				fail("branch-rebinding function changed shape");
		}
	}

	static function testTupleMatchForgetsKnownNil():Void {
		var assignKnownNil = makeAST(EMatch(PVar("validated_email"), makeAST(ENil)));
		var tupleMatch = makeAST(EMatch(PTuple([PVar("errors"), PVar("validated_email")]), makeAST(ECall(null, "validate", []))));
		var nilCheck = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [makeAST(EVar("validated_email"))]));
		var conditional = makeAST(EIf(nilCheck, makeAST(EAtom("error")), makeAST(EAtom("ok"))));
		var body = makeAST(EBlock([assignKnownNil, tupleMatch, conditional]));
		var functionNode = makeAST(EDef("validate_user_input", [], null, body));

		var result = BinderTransforms.simplifyProvableIsNilFalsePass(functionNode);

		switch (result.def) {
			case EDef("validate_user_input", _, _, {def: EBlock([_, _, {def: EIf(condition, _, _)}])}):
				switch (condition.def) {
					case ERemoteCall({def: EVar("Kernel")}, "is_nil", [{def: EVar("validated_email")}]):
					default:
						fail("a tuple match must forget the earlier known-nil value");
				}
			default:
				fail("tuple-rebinding function changed shape");
		}
	}

	static function testKnownNilRemovesUnreachableShift():Void {
		var assignLength = makeAST(EMatch(PVar("length"), makeAST(ENil)));
		var nilCheck = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [makeAST(EVar("length"))]));
		var shift = makeAST(ERemoteCall(makeAST(EVar("Bitwise")), "bsl", [makeAST(EVar("length")), makeAST(EInteger(2))]));
		var nestedArgument = makeAST(EBlock([assignLength, makeAST(EIf(nilCheck, makeAST(ENil), shift))]));
		var body = makeAST(EBlock([makeAST(ERemoteCall(makeAST(EVar("Sample")), "consume", [nestedArgument]))]));
		var testMacro = makeAST(EMacroCall("test", [makeAST(EString("known nil length"))], body));

		var folded = BinderTransforms.simplifyProvableIsNilFalsePass(testMacro);

		switch (folded.def) {
			case EMacroCall("test", _, macroBody):
				switch (macroBody.def) {
					case EBlock([{def: ERemoteCall(_, "consume", [{def: EBlock([_, finalExpression])}])}]):
						assertNode(finalExpression, ENil, "known nil in a nested argument block must remove the unreachable shift branch");
					default:
						fail("known-nil test macro body changed shape");
				}
			default:
				fail("known-nil test macro changed shape");
		}
	}

	static function testKnownNonNilFoldsNegatedCheck():Void {
		var assignValue = makeAST(EMatch(PVar("value"), makeAST(EString("set"))));
		var nilCheck = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [makeAST(EVar("value"))]));
		var conditional = makeAST(EIf(makeAST(EUnary(Not, nilCheck)), makeAST(EAtom("ok")), makeAST(EAtom("error"))));
		var functionNode = makeAST(EDef("check", [], null, makeAST(EBlock([assignValue, conditional]))));

		var result = BinderTransforms.simplifyProvableIsNilFalsePass(functionNode);

		switch (result.def) {
			case EDef("check", _, _, {def: EBlock([_, finalExpression])}):
				assertNode(finalExpression, EAtom("ok"), "a negated known non-nil check must fold to its true branch");
			default:
				fail("known-non-nil function changed shape");
		}
	}

	static function testDiscardedIfRemovesSignedBranchTail():Void {
		var setter = makeAST(ERemoteCall(makeAST(EVar("Sample")), "set", [makeAST(EInteger(-2))]));
		var signedResult = makeAST(EInteger(-2));
		var conditional = makeAST(EIf(makeAST(EBoolean(true)), makeAST(EBlock([setter, signedResult])), makeAST(EInteger(0))));
		var assertion = makeAST(ECall(null, "assert", [makeAST(EBoolean(true))]));

		var result = BareLiteralDropTransforms.pass(makeAST(EBlock([conditional, assertion])));

		switch (result.def) {
			case EBlock([first, finalExpression]):
				assertNode(finalExpression, assertion.def, "the following assertion must remain final");
				switch (first.def) {
					case EIf(_, thenBranch, elseBranch):
						assertNode(elseBranch, EInteger(0), "the unsigned else result must remain");
						switch (thenBranch.def) {
							case EBlock([remainingSetter]):
								assertNode(remainingSetter, setter.def, "the setter side effect must remain");
							default:
								fail("the signed branch tail was not removed");
						}
					default:
						fail("discarded if changed shape");
				}
			default:
				fail("discarded-if test block changed shape");
		}
	}

	static function assertNode(actual:ElixirASTNode, expectedDef:ElixirASTDef, message:String):Void {
		if (!Type.enumEq(actual.def, expectedDef))
			fail(message);
	}

	static function fail(message:String):Void {
		Context.fatalError("Stdlib warning transform contract failed: " + message, Context.currentPos());
	}
}
#end
