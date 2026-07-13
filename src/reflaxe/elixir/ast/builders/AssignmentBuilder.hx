package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)
import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTHelpers;
import reflaxe.elixir.ast.NameUtils;
import reflaxe.elixir.helpers.PatternDetector;

private typedef LocalFieldAssign = {
	baseVarName:String,
	baseVarId:Int,
	fieldNameSnake:String,
	isStruct:Bool,
	tupleIndex:Null<Int>
};

/**
 * AssignmentBuilder
 *
 * WHAT
 * - Lowers Haxe assignment operators that need special handling for Elixir:
 *   - `OpAssign` (`=`)
 *   - `OpAssignOp` (`+=`, `-=`, etc.)
 *
 * WHY
 * - Elixir is immutable; assignments to local variables are always rebinding.
 * - "Field assignment" on a local (e.g. `spec.restart = Temporary`) must become an immutable
 *   update of the base value (`spec = Map.put(spec, :restart, ...)` or `%{spec | restart: ...}`).
 * - Regular typed anonymous objects compile as atom-keyed maps; tuple-shaped
 *   anonymous objects require `put_elem/3` instead of a map update.
 *
 * HOW
 * - Detect local-field assignment shapes:
 *   - `TField(TLocal(base), <non-this field>) = rhs`
 * - Rewrite to:
 *   - Struct (`TInst`): `%{base | field: rhs}`
 *   - Map/anonymous (`TAnonymous`): `Map.put(base, :field, rhs)`
 *   - Tuple-shaped anonymous: `put_elem(base, index, rhs)`
 * - Apply the same update strategy to compound assignments by computing the new field value.
 *
 * EXAMPLES
 * Haxe:
 *   spec.restart = Temporary;
 * Elixir (after):
 *   spec = Map.put(spec, :restart, {:temporary})
 *
 * Haxe:
 *   buffer.byteLength += 1;
 * Elixir (after):
 *   buffer = %{buffer | byte_length: buffer.byte_length + 1}
 */
class AssignmentBuilder {
	public static function build(op:Binop, e1:TypedExpr, e2:TypedExpr, expr:TypedExpr, context:CompilationContext):Null<ElixirASTDef> {
		return switch (op) {
			case OpAssign:
				buildAssign(e1, e2, context);
			case OpAssignOp(innerOp):
				buildAssignOp(innerOp, e1, e2, context);
			default:
				null;
		}
	}

	static function buildAssign(e1:TypedExpr, e2:TypedExpr, context:CompilationContext):Null<ElixirASTDef> {
		// Abstract constructors assign to `this` to define the underlying value:
		//   this = expr;
		// In Elixir there is no mutable `this`, so the assignment expression should
		// simply evaluate to the RHS (constructor return value).
		switch (e1.expr) {
			case TConst(TThis):
				var rhsAst = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e2, context);
				return rhsAst != null ? rhsAst.def : ENil;
			default:
		}

		var timerRunAssign = buildTimerRunAssign(e1, e2, context);
		if (timerRunAssign != null)
			return timerRunAssign.def;

		var localField = detectLocalFieldAssign(e1, context);
		var pattern:EPattern = (localField != null) ? EPattern.PVar(localField.baseVarName) : PatternBuilder.extractPattern(e1, context);

		// Flatten nested underscore assignment: x = _ = expr → x = expr
		var rhsExpr = e2;
		switch (e2.expr) {
			case TBinop(OpAssign, innerLhs, innerRhs):
				switch (innerLhs.expr) {
					case TLocal(v) if (v.name == "_"):
						rhsExpr = innerRhs;
					default:
				}
			default:
		}

		var rightAST = if (localField != null) {
			buildLocalFieldAssignUpdate(localField, rhsExpr, context);
		} else {
			reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(rhsExpr, context);
		}

		// Skip redundant self-assign patterns (e.g. temp = temp) introduced by Haxe lowering.
		var shouldSkipAssign = false;
		switch (pattern) {
			case PVar(name):
				var valueName = switch (rightAST != null ? rightAST.def : null) {
					case EVar(varName): varName;
					default: null;
				};

				if (PatternDetector.isTempPatternVarName(name)) {
					shouldSkipAssign = switch (rightAST != null ? rightAST.def : null) {
						case EVar(varName) if (varName == name || PatternDetector.isTempPatternVarName(varName)):
							true;
						default:
							false;
					};
				} else if (valueName != null) {
					if (valueName == name) {
						shouldSkipAssign = true;
					} else if (PatternDetector.isTempPatternVarName(valueName)) {
						shouldSkipAssign = true;
					}
				}
			default:
		}

		if (shouldSkipAssign)
			return null;

		var matchNode = makeAST(EMatch(pattern, rightAST));
		attachVarIdMetadata(matchNode, e1, localField);
		return matchNode.def;
	}

	static function buildTimerRunAssign(targetExpr:TypedExpr, valueExpr:TypedExpr, context:CompilationContext):Null<ElixirAST> {
		return switch (targetExpr.expr) {
			case TField(baseExpr, fa) if (isHaxeTimerExpr(baseExpr) && fieldName(fa) == "run"):
				var timerAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(baseExpr, context);
				var callbackAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(valueExpr, context);
				makeAST(ERemoteCall(makeAST(EVar("Haxe.Timer")), "__set_run", [timerAST, callbackAST]));
			default:
				null;
		}
	}

	static function fieldName(fa:FieldAccess):String {
		return switch (fa) {
			case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
				cf.get().name;
			case FDynamic(s):
				s;
			case FEnum(_, ef):
				ef.name;
		}
	}

	static function isHaxeTimerExpr(e:TypedExpr):Bool {
		var followed = haxe.macro.TypeTools.follow(e.t);
		var typeName = haxe.macro.TypeTools.toString(followed);
		if (typeName == "haxe.Timer" || typeName == "Haxe.Timer")
			return true;
		return switch (followed) {
			case TInst(classRef, _):
				var classType = classRef.get();
				classType != null
				&& classType.name == "Timer"
				&& classType.pack != null
				&& (classType.pack.join(".") == "haxe" || classType.pack.join(".") == "Haxe");
			default:
				false;
		}
	}

	static function buildAssignOp(innerOp:Binop, e1:TypedExpr, e2:TypedExpr, context:CompilationContext):Null<ElixirASTDef> {
		var localField = detectLocalFieldAssign(e1, context);
		if (localField != null) {
			// base.field <op>= rhs  ->  base = update(base, field, base.field <op> rhs)
			var leftAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e1, context);
			var rightAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e2, context);

			var innerBinop = BinaryOpBuilder.buildBinopFromAST(innerOp, leftAST, rightAST, e1, e2, s -> NameUtils.toSnakeCase(s));

			var updated = buildLocalFieldAssignUpdateFromValue(localField, innerBinop);
			var matchNode = makeAST(EMatch(EPattern.PVar(localField.baseVarName), updated));
			if (matchNode.metadata == null)
				matchNode.metadata = {};
			matchNode.metadata.varId = localField.baseVarId;
			return matchNode.def;
		}

		// Default: x += y -> x = x + y
		var pattern = PatternBuilder.extractPattern(e1, context);
		var leftAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e1, context);
		var rightAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e2, context);

		var innerBinop = BinaryOpBuilder.buildBinopFromAST(innerOp, leftAST, rightAST, e1, e2, s -> NameUtils.toSnakeCase(s));

		var matchNode = makeAST(EMatch(pattern, innerBinop));
		attachVarIdMetadata(matchNode, e1, null);
		return matchNode.def;
	}

	static function detectLocalFieldAssign(e:TypedExpr, context:CompilationContext):Null<LocalFieldAssign> {
		return switch (e.expr) {
			case TField(baseExpr, fa):
				switch (baseExpr.expr) {
					case TLocal(v):
						var baseVarName = ElixirASTHelpers.toElixirVarName(v.name);
						// Avoid rewriting instance field assignment on this/_this (handled elsewhere)
						if (baseVarName == "this" || baseVarName == "_this")
							return null;

						var rawFieldName = switch (fa) {
							case FInstance(_, _, cf): cf.get().name;
							case FStatic(_, cf): cf.get().name;
							case FAnon(cf): cf.get().name;
							case FClosure(_, cf): cf.get().name;
							case FEnum(_, ef): ef.name;
							case FDynamic(s): s;
						};

						var fieldNameSnake = NameUtils.toSnakeCase(rawFieldName);
						var tupleIndex = AnonymousTupleShape.fieldIndexForType(baseExpr.t, rawFieldName);
						var isStruct = switch (baseExpr.t) {
							case TInst(_, _): true;
							default: false;
						};

						{
							baseVarName: baseVarName,
							baseVarId: v.id,
							fieldNameSnake: fieldNameSnake,
							isStruct: isStruct,
							tupleIndex: tupleIndex
						};
					case TConst(TThis):
						var compilationCtx = context;
						if (compilationCtx == null || compilationCtx.currentReceiverParamName == null)
							return null;
						var baseVarName = compilationCtx.currentReceiverParamName;

						var rawFieldName = switch (fa) {
							case FInstance(_, _, cf): cf.get().name;
							case FStatic(_, cf): cf.get().name;
							case FAnon(cf): cf.get().name;
							case FClosure(_, cf): cf.get().name;
							case FEnum(_, ef): ef.name;
							case FDynamic(s): s;
						};

						{
							baseVarName: baseVarName,
							baseVarId: -1,
							fieldNameSnake: NameUtils.toSnakeCase(rawFieldName),
							isStruct: true,
							tupleIndex: null
						};
					default:
						null;
				}
			default:
				null;
		}
	}

	static function buildLocalFieldAssignUpdate(localField:LocalFieldAssign, rhsExpr:TypedExpr, context:CompilationContext):ElixirAST {
		var valueAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(rhsExpr, context);
		return buildLocalFieldAssignUpdateFromValue(localField, valueAST);
	}

	static function buildLocalFieldAssignUpdateFromValue(localField:LocalFieldAssign, valueAST:ElixirAST):ElixirAST {
		if (localField.tupleIndex != null) {
			return makeAST(ECall(null, "put_elem", [
				makeAST(EVar(localField.baseVarName)),
				makeAST(EInteger(localField.tupleIndex)),
				valueAST
			]));
		}

		if (localField.isStruct) {
			// %{base | field: value}
			return makeAST(EStructUpdate(makeAST(EVar(localField.baseVarName)), [{key: localField.fieldNameSnake, value: valueAST}]));
		}

		// Map.put(base, :field, value)
		return makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [
			makeAST(EVar(localField.baseVarName)),
			makeAST(EAtom(localField.fieldNameSnake)),
			valueAST
		]));
	}

	static function attachVarIdMetadata(matchNode:ElixirAST, lhs:TypedExpr, localField:Null<LocalFieldAssign>):Void {
		if (matchNode == null)
			return;
		if (matchNode.metadata == null)
			matchNode.metadata = {};

		switch (lhs.expr) {
			case TLocal(v):
				matchNode.metadata.varId = v.id;
			case TField(baseExpr, _):
				if (localField != null) {
					matchNode.metadata.varId = localField.baseVarId;
				} else {
					switch (baseExpr.expr) {
						case TLocal(v2):
							matchNode.metadata.varId = v2.id;
						default:
					}
				}
			default:
		}
	}
}
#end
