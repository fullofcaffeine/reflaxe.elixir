package tools;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST.ElixirAST as ElixirASTNode;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.transformers.BareLiteralDropTransforms;
import reflaxe.elixir.ast.transformers.BinderTransforms;
import reflaxe.elixir.ast.transformers.IfConstSimplifyTransforms;

/** Focused executable contracts for warning-producing upstream stdlib AST shapes. */
@:nullSafety(Off)
class TestStdlibWarningTransforms {
	public static function run():Expr {
		testKnownNilRemovesUnreachableShift();
		testDiscardedIfRemovesSignedBranchTail();

		Sys.println("Stdlib warning transform contracts passed");
		return macro null;
	}

	static function testKnownNilRemovesUnreachableShift():Void {
		var assignLength = makeAST(EMatch(PVar("length"), makeAST(ENil)));
		var nilCheck = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [makeAST(EVar("length"))]));
		var shift = makeAST(ERemoteCall(makeAST(EVar("Bitwise")), "bsl", [makeAST(EVar("length")), makeAST(EInteger(2))]));
		var body = makeAST(EBlock([assignLength, makeAST(EIf(nilCheck, makeAST(ENil), shift))]));
		var testMacro = makeAST(EMacroCall("test", [makeAST(EString("known nil length"))], body));

		var simplified = BinderTransforms.simplifyProvableIsNilFalsePass(testMacro);
		var folded = IfConstSimplifyTransforms.transformPass(simplified);

		switch (folded.def) {
			case EMacroCall("test", _, macroBody):
				switch (macroBody.def) {
					case EBlock([_, finalExpression]):
						assertNode(finalExpression, ENil, "known nil must remove the unreachable shift branch");
					default:
						fail("known-nil test macro body changed shape");
				}
			default:
				fail("known-nil test macro changed shape");
		}
	}

	static function testDiscardedIfRemovesSignedBranchTail():Void {
		var setter = makeAST(ERemoteCall(makeAST(EVar("Sample")), "set", [makeAST(EInteger(-2))]));
		var signedResult = makeAST(EUnary(Negate, makeAST(EInteger(2))));
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
