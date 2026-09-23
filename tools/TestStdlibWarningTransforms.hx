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
