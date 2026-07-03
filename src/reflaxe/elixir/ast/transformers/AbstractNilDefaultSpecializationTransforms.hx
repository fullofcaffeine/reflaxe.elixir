package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

typedef NilDefaultReplacement = {
	var targetName:String;
	var defaultExpr:ElixirAST;
	var assignment:ElixirAST;
}

/**
 * AbstractNilDefaultSpecializationTransforms
 *
 * WHAT
 * - Collapse the nil-default temporary emitted by inlined Haxe multi-type abstract
 *   specialization helpers:
 *
 *     t = nil
 *     map = if Kernel.is_nil(t), do: %{}, else: t
 *
 *   into:
 *
 *     map = %{}
 *
 * WHY
 * - `haxe.ds.Map` is a multi-type abstract. When the target-owned `Map.cross.hx`
 *   is selected directly, Haxe can inline its specialization helper for
 *   `new Map()` as an absent source receiver (`t = nil`) followed by a default
 *   fallback. Keeping that helper shape produces noisier Elixir and can make an
 *   otherwise erased abstract implementation look runtime-relevant.
 *
 * HOW
 * - Scan each `EBlock`/`EDo` for an adjacent pair:
 *   1. `temp = nil`
 *   2. `target = if is_nil(temp), default, temp`
 * - Rewrite the pair to `target = default` only when:
 *   - `target` is a different local than `temp`;
 *   - `default` does not reference `temp`;
 *   - `temp` is not read before the next top-level rebind of the same local.
 * - If the target is already a discarded local (`_name`), the default is pure,
 *   and the target is not used later, drop the pair entirely.
 *
 * EXAMPLES
 * - Covered by the `core/maps` snapshot family, which should keep `new Map()`
 *   output as `map = %{}` rather than emitting the helper temporary.
 */
class AbstractNilDefaultSpecializationTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EBlock(stmts):
					makeASTWithMeta(EBlock(rewriteStatements(stmts)), n.metadata, n.pos);
				case EDo(stmts):
					makeASTWithMeta(EDo(rewriteStatements(stmts)), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	static function rewriteStatements(stmts:Array<ElixirAST>):Array<ElixirAST> {
		if (stmts == null || stmts.length < 2)
			return stmts;

		var out:Array<ElixirAST> = [];
		var i = 0;
		while (i < stmts.length) {
			if (i + 1 < stmts.length) {
				var tempName = matchNilAssignment(stmts[i]);
				var replacement = tempName != null ? matchNilDefaultAssignment(stmts[i + 1], tempName) : null;
				if (replacement != null && !isVarUsedBeforeRebind(stmts, tempName, i + 2)) {
					if (!(isDiscardedName(replacement.targetName)
						&& isPure(replacement.defaultExpr)
						&& !isVarUsedBeforeRebind(stmts, replacement.targetName, i + 2))) {
						out.push(replacement.assignment);
					}
					i += 2;
					continue;
				}
			}
			out.push(stmts[i]);
			i++;
		}
		return out;
	}

	static function matchNilAssignment(ast:ElixirAST):Null<String> {
		if (ast == null || ast.def == null)
			return null;
		return switch (ast.def) {
			case EMatch(PVar(name), value) if (isNil(value)):
				name;
			case EBinary(Match, {def: EVar(name)}, value) if (isNil(value)):
				name;
			default:
				null;
		};
	}

	static function matchNilDefaultAssignment(ast:ElixirAST, tempName:String):Null<NilDefaultReplacement> {
		if (ast == null || ast.def == null || tempName == null)
			return null;

		return switch (ast.def) {
			case EMatch(PVar(targetName), {def: EIf(cond, defaultExpr, elseExpr)})
				if (targetName != tempName && isNilCheckFor(cond, tempName) && isVar(elseExpr, tempName) && !containsVar(defaultExpr, tempName)):
				{
					targetName: targetName,
					defaultExpr: defaultExpr,
					assignment: markNilDefaultAssignment(makeASTWithMeta(EMatch(PVar(targetName), defaultExpr), ast.metadata, ast.pos))
				};
			case EBinary(Match, left = {def: EVar(targetName)}, {def: EIf(cond, defaultExpr, elseExpr)})
				if (targetName != tempName && isNilCheckFor(cond, tempName) && isVar(elseExpr, tempName) && !containsVar(defaultExpr, tempName)):
				{
					targetName: targetName,
					defaultExpr: defaultExpr,
					assignment: markNilDefaultAssignment(makeASTWithMeta(EBinary(Match, left, defaultExpr), ast.metadata, ast.pos))
				};
			default:
				null;
		};
	}

	static function markNilDefaultAssignment(ast:ElixirAST):ElixirAST {
		if (ast.metadata == null)
			ast.metadata = {};
		Reflect.setField(ast.metadata, "abstractNilDefaultSpecialization", true);
		return ast;
	}

	static function isNilCheckFor(ast:ElixirAST, tempName:String):Bool {
		if (ast == null || ast.def == null)
			return false;

		return switch (ast.def) {
			case ERemoteCall({def: EVar(moduleName)}, "is_nil", args) if (moduleName == "Kernel" && hasSingleVarArg(args, tempName)):
				true;
			case ECall({def: EVar(moduleName)}, "is_nil", args) if (moduleName == "Kernel" && hasSingleVarArg(args, tempName)):
				true;
			case ECall(null, "is_nil", args) if (hasSingleVarArg(args, tempName)):
				true;
			case EBinary(Equal, left, right): (isVar(left, tempName) && isNil(right)) || (isNil(left) && isVar(right, tempName));
			case EParen(inner):
				isNilCheckFor(inner, tempName);
			case EBlock([inner]) | EDo([inner]):
				isNilCheckFor(inner, tempName);
			default:
				false;
		};
	}

	static function hasSingleVarArg(args:Array<ElixirAST>, name:String):Bool {
		return args != null && args.length == 1 && isVar(args[0], name);
	}

	static function isNil(ast:ElixirAST):Bool {
		if (ast == null || ast.def == null)
			return false;
		return switch (ast.def) {
			case ENil:
				true;
			case EParen(inner):
				isNil(inner);
			case EBlock([inner]) | EDo([inner]):
				isNil(inner);
			default:
				false;
		};
	}

	static function isVar(ast:ElixirAST, name:String):Bool {
		if (ast == null || ast.def == null || name == null)
			return false;
		return switch (ast.def) {
			case EVar(varName) if (varName == name):
				true;
			case EParen(inner):
				isVar(inner, name);
			case EBlock([inner]) | EDo([inner]):
				isVar(inner, name);
			default:
				false;
		};
	}

	static function isVarUsedBeforeRebind(stmts:Array<ElixirAST>, name:String, startIndex:Int):Bool {
		if (stmts == null || name == null)
			return false;
		for (i in startIndex...stmts.length) {
			var rhs = matchAssignmentToVar(stmts[i], name);
			if (rhs != null)
				return containsVar(rhs, name);
			if (containsVar(stmts[i], name))
				return true;
		}
		return false;
	}

	static function matchAssignmentToVar(ast:ElixirAST, name:String):Null<ElixirAST> {
		if (ast == null || ast.def == null || name == null)
			return null;
		return switch (ast.def) {
			case EMatch(PVar(varName), rhs) if (varName == name):
				rhs;
			case EBinary(Match, {def: EVar(varName)}, rhs) if (varName == name):
				rhs;
			default:
				null;
		};
	}

	static function isDiscardedName(name:String):Bool {
		return name != null && name.length > 1 && name.charAt(0) == "_";
	}

	static function isPure(ast:ElixirAST):Bool {
		if (ast == null || ast.def == null)
			return false;
		return switch (ast.def) {
			case EVar(_) | EString(_) | EInteger(_) | EFloat(_) | EBoolean(_) | ENil | EAtom(_):
				true;
			case EMap(pairs): pairs != null && Lambda.foreach(pairs, pair -> pair != null && isPure(pair.key) && isPure(pair.value));
			case EKeywordList(pairs): pairs != null && Lambda.foreach(pairs, pair -> pair != null && isPure(pair.value));
			case ETuple(elements) | EList(elements): elements != null && Lambda.foreach(elements, isPure);
			case EStruct(_, fields): fields != null && Lambda.foreach(fields, field -> field != null && isPure(field.value));
			case EParen(inner):
				isPure(inner);
			case EBlock([inner]) | EDo([inner]):
				isPure(inner);
			default:
				false;
		};
	}

	static function containsVar(ast:ElixirAST, name:String):Bool {
		if (ast == null || ast.def == null || name == null)
			return false;

		var found = false;
		ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			if (!found) {
				switch (n.def) {
					case EVar(varName) if (varName == name):
						found = true;
					default:
				}
			}
			return n;
		});
		return found;
	}
}
#end
