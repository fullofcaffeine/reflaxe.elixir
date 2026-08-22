package tools;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST.ElixirAST as ElixirASTNode;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.transformers.BareLiteralDropTransforms;
import reflaxe.elixir.ast.transformers.BinderTransforms;

/** Focused executable contracts for warning-producing upstream stdlib AST shapes. */
@:nullSafety(Off)
class TestStdlibWarningTransforms {
	public static function run():Expr {
		testKnownNilRemovesUnreachableShift();
		testKnownNonNilFoldsNegatedCheck();
		testTupleMatchForgetsKnownNil();
		testBranchAssignmentForgetsKnownNil();
		testDiscardedIfRemovesSignedBranchTail();

		Sys.println("Stdlib warning transform contracts passed");
		return macro null;
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
