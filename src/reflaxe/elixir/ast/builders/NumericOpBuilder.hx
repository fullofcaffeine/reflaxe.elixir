package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)
import haxe.macro.Expr;
import haxe.macro.Type.TypedExpr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.EBinaryOp;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.EUnaryOp;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.TypeUtils;

/**
 * NumericOpBuilder
 *
 * WHAT
 * - Chooses how Haxe numeric and equality operators should be emitted for Elixir.
 *
 * WHY
 * - Native BEAM numbers are fast and should remain the default for normal Elixir-first code.
 * - Portable Haxe code can use `Math.NaN` and infinities, which Elixir cannot represent with
 *   native numbers. Those values need `Reflaxe.Elixir.HaxeFloat` helpers at operator boundaries.
 *
 * HOW
 * - Concrete Int-only arithmetic stays native.
 * - Float-like, Dynamic, unresolved, and `/` operations use `HaxeFloat` helpers.
 * - String concatenation uses `HaxeFloat.to_string/1` for non-string operands so specials print
 *   as `NaN`, `Infinity`, and `-Infinity` instead of raw tagged tuples. It uses the same helper
 *   for a `Null<String>` operand, so a null value prints as `null`, as in Haxe.
 */
class NumericOpBuilder {
	public static function buildFromAST(op:Binop, leftAST:ElixirAST, rightAST:ElixirAST, leftExpr:TypedExpr, rightExpr:TypedExpr,
			metadata:ElixirMetadata = null):Null<ElixirAST> {
		var ast = switch (op) {
			case OpAdd:
				if (TypeUtils.isStringType(leftExpr.t) || TypeUtils.isStringType(rightExpr.t)) {
					buildStringConcat(leftAST, rightAST, leftExpr, rightExpr);
				} else if (shouldUseHaxeFloatHelper(op, leftExpr, rightExpr)) {
					haxeFloatCall("add", [safeOperand(leftAST), safeOperand(rightAST)]);
				} else {
					makeAST(EBinary(EBinaryOp.Add, safeOperand(leftAST), safeOperand(rightAST)));
				}
			case OpSub:
				buildArithmetic(op, "sub", EBinaryOp.Subtract, leftAST, rightAST, leftExpr, rightExpr);
			case OpMult:
				buildArithmetic(op, "mul", EBinaryOp.Multiply, leftAST, rightAST, leftExpr, rightExpr);
			case OpDiv:
				buildArithmetic(op, "divide", EBinaryOp.Divide, leftAST, rightAST, leftExpr, rightExpr);
			case OpMod:
				buildArithmetic(op, "remainder", EBinaryOp.Remainder, leftAST, rightAST, leftExpr, rightExpr);
			case OpEq:
				buildComparison("eq", EBinaryOp.Equal, leftAST, rightAST, leftExpr, rightExpr);
			case OpNotEq:
				buildComparison("neq", EBinaryOp.NotEqual, leftAST, rightAST, leftExpr, rightExpr);
			case OpLt:
				buildComparison("lt", EBinaryOp.Less, leftAST, rightAST, leftExpr, rightExpr);
			case OpLte:
				buildComparison("lte", EBinaryOp.LessEqual, leftAST, rightAST, leftExpr, rightExpr);
			case OpGt:
				buildComparison("gt", EBinaryOp.Greater, leftAST, rightAST, leftExpr, rightExpr);
			case OpGte:
				buildComparison("gte", EBinaryOp.GreaterEqual, leftAST, rightAST, leftExpr, rightExpr);
			default:
				null;
		};

		if (ast == null)
			return null;
		return metadata != null ? makeASTWithMeta(ast.def, metadata) : ast;
	}

	public static function buildUnaryNegation(exprAST:ElixirAST, expr:TypedExpr):ElixirAST {
		if (TypeUtils.mayContainHaxeFloat(expr.t))
			return haxeFloatCall("neg", [exprAST]);
		return makeAST(EUnary(EUnaryOp.Negate, exprAST));
	}

	public static function buildIncrementValue(op:EBinaryOp, currentValue:ElixirAST, one:ElixirAST, expr:TypedExpr):ElixirAST {
		if (TypeUtils.mayContainHaxeFloat(expr.t)) {
			var helperName = (op == EBinaryOp.Add) ? "add" : "sub";
			return haxeFloatCall(helperName, [currentValue, one]);
		}
		return makeAST(EBinary(op, currentValue, one));
	}

	static function buildArithmetic(op:Binop, helperName:String, nativeOp:EBinaryOp, leftAST:ElixirAST, rightAST:ElixirAST, leftExpr:TypedExpr,
			rightExpr:TypedExpr):ElixirAST {
		if (shouldUseHaxeFloatHelper(op, leftExpr, rightExpr))
			return haxeFloatCall(helperName, [leftAST, rightAST]);
		return makeAST(EBinary(nativeOp, leftAST, rightAST));
	}

	static function buildComparison(helperName:String, nativeOp:EBinaryOp, leftAST:ElixirAST, rightAST:ElixirAST, leftExpr:TypedExpr,
			rightExpr:TypedExpr):ElixirAST {
		// `elixir.types.Term` is an explicit native BEAM boundary, unlike ordinary
		// `Dynamic`. Its equality contract is Elixir term equality, so do not route
		// comparisons through the portable Haxe Float special-value helpers.
		if ((nativeOp == EBinaryOp.Equal || nativeOp == EBinaryOp.NotEqual)
			&& (TypeUtils.isElixirTermType(leftExpr.t) || TypeUtils.isElixirTermType(rightExpr.t))) {
			return makeAST(EBinary(nativeOp, leftAST, rightAST));
		}

		if (TypeUtils.mayContainHaxeFloat(leftExpr.t) || TypeUtils.mayContainHaxeFloat(rightExpr.t))
			return haxeFloatCall(helperName, [leftAST, rightAST]);
		return makeAST(EBinary(nativeOp, leftAST, rightAST));
	}

	static function buildStringConcat(leftAST:ElixirAST, rightAST:ElixirAST, leftExpr:TypedExpr, rightExpr:TypedExpr):ElixirAST {
		return makeAST(EBinary(EBinaryOp.StringConcat, stringConcatOperand(leftAST, leftExpr), stringConcatOperand(rightAST, rightExpr)));
	}

	/**
	 * Returns one operand of a Haxe string concatenation as Elixir text.
	 *
	 * WHY: Haxe prints a null operand as the text `null`: `"x/" + a` gives `"x/null"` when `a`
	 * is null. On the BEAM, `"x/" <> nil` raises and `"x/#{nil}"` gives `"x/"`, so a null
	 * operand must be converted before the target sees it. Haxe rewrites `'x/$a'` to the same
	 * `+` expression, so this one place also covers string interpolation. `text += a` stays a
	 * compound assignment in Haxe; `AssignmentBuilder` lowers its `+` through this builder,
	 * so it gets the same conversion.
	 *
	 * WHAT: A non-String operand, or a String operand whose type can hold null, goes through
	 * `Reflaxe.Elixir.HaxeFloat.to_string/1`, which returns a binary unchanged and maps `nil`
	 * to `"null"`. A plain `String` operand stays as it is, with no run-time check. A literal
	 * `null` becomes the text directly.
	 *
	 * HOW: Control-flow shape does not show the result type: `Std.random` lowers to a `case`
	 * that still returns an Int. So the decision reads the Haxe type and expression only.
	 *
	 * EXAMPLES
	 * - `"x/" + name` with `name:String`: `"x/" <> name`
	 * - `"x/" + name` with `name:Null<String>`: `"x/" <> Reflaxe.Elixir.HaxeFloat.to_string(name)`
	 * - `"x/" + null`: `"x/" <> "null"`
	 *
	 * LIMIT: A value declared as plain `String` that holds null at run time is not converted.
	 */
	static function stringConcatOperand(operandAST:ElixirAST, operandExpr:TypedExpr):ElixirAST {
		if (isNullLiteral(operandExpr))
			return makeAST(EString("null"));
		if (TypeUtils.isStringType(operandExpr.t) && !TypeUtils.mayBeNil(operandExpr.t))
			return operandAST;
		return toHaxeString(operandAST);
	}

	static function isNullLiteral(expr:TypedExpr):Bool {
		return switch (expr.expr) {
			case TConst(TNull): true;
			case TParenthesis(inner) | TMeta(_, inner): isNullLiteral(inner);
			default: false;
		}
	}

	static function shouldUseHaxeFloatHelper(op:Binop, leftExpr:TypedExpr, rightExpr:TypedExpr):Bool {
		return op == OpDiv || TypeUtils.mayContainHaxeFloat(leftExpr.t) || TypeUtils.mayContainHaxeFloat(rightExpr.t);
	}

	static function toHaxeString(expr:ElixirAST):ElixirAST {
		return haxeFloatCall("to_string", [expr]);
	}

	static function haxeFloatCall(functionName:String, args:Array<ElixirAST>):ElixirAST {
		return makeAST(ERemoteCall(makeAST(EVar("Reflaxe.Elixir.HaxeFloat")), functionName, args));
	}

	static function safeOperand(expr:Null<ElixirAST>):ElixirAST {
		return expr != null ? expr : makeAST(EInteger(0));
	}
}
#end
