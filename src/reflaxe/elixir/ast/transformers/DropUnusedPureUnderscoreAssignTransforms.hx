package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * DropUnusedPureUnderscoreAssignTransforms
 *
 * WHAT
 * - Remove non-final assignments of pure values to discarded local names when
 *   the assignment was created by `AbstractNilDefaultSpecializationTransforms`:
 *
 *     _empty_map = %{}
 *     nil
 *
 *   becomes:
 *
 *     nil
 *
 * WHY
 * - `AbstractNilDefaultSpecializationTransforms` can turn an unused `new Map()`
 *   helper into `empty_map = %{}`. A later hygiene pass correctly renames that
 *   unused local to `_empty_map`, but at that point the pure assignment itself
 *   is also unnecessary.
 *
 * HOW
 * - Walk `EBlock`/`EDo` statement lists.
 * - For each non-final assignment to `_name`, drop it only when:
 *   - the assignment carries the abstract nil-default marker;
 *   - the RHS is pure;
 *   - `_name` is not read later;
 *   - the base name `name` is not read later.
 *
 * EXAMPLES
 * - Covered by `core/MapIdiomatic`, where an unused `new Map()` must not emit
 *   `_empty_map = %{}`.
 */
class DropUnusedPureUnderscoreAssignTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EBlock(stmts):
					makeASTWithMeta(EBlock(filter(stmts)), n.metadata, n.pos);
				case EDo(stmts):
					makeASTWithMeta(EDo(filter(stmts)), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	static function filter(stmts:Array<ElixirAST>):Array<ElixirAST> {
		if (stmts == null || stmts.length < 2)
			return stmts;

		var usage = OptimizedVarUseAnalyzer.buildExact(stmts);
		var out:Array<ElixirAST> = [];
		for (i in 0...stmts.length) {
			var stmt = stmts[i];
			if (i < stmts.length - 1) {
				var assignment = matchDiscardedPureAssignment(stmt);
				if (assignment != null
					&& !OptimizedVarUseAnalyzer.usedLater(usage, i + 1, assignment.name)
					&& !OptimizedVarUseAnalyzer.usedLater(usage, i + 1, assignment.baseName)) {
					continue;
				}
			}
			out.push(stmt);
		}
		return out;
	}

	static function matchDiscardedPureAssignment(ast:ElixirAST):Null<{name:String, baseName:String}> {
		if (ast == null || ast.def == null)
			return null;
		return switch (ast.def) {
			case EMatch(PVar(name), rhs) if (hasNilDefaultMarker(ast) && isDiscardedName(name) && isPure(rhs)):
				{name: name, baseName: stripLeadingUnderscores(name)};
			case EBinary(Match, {def: EVar(name)}, rhs) if (hasNilDefaultMarker(ast) && isDiscardedName(name) && isPure(rhs)):
				{name: name, baseName: stripLeadingUnderscores(name)};
			default:
				null;
		};
	}

	static function hasNilDefaultMarker(ast:ElixirAST):Bool {
		return ast != null && ast.metadata != null && Reflect.field(ast.metadata, "abstractNilDefaultSpecialization") == true;
	}

	static function isDiscardedName(name:String):Bool {
		return name != null && name.length > 1 && name.charAt(0) == "_";
	}

	static function stripLeadingUnderscores(name:String):String {
		var i = 0;
		while (i < name.length && name.charAt(i) == "_")
			i++;
		var base = name.substr(i);
		return base.length > 0 ? base : "_";
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
}
#end
