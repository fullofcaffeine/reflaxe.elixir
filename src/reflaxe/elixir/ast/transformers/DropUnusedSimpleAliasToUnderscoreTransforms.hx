package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * DropUnusedSimpleAliasToUnderscoreTransforms
 *
 * WHAT
 * - Converts trivial alias assignments like `tmp = value` to `_ = value` when `tmp` is not
 *   referenced later in the enclosing block.
 *
 * WHY
 * - Hygiene/aliasing passes may introduce helper locals (e.g., `n2 = value`, `x3 = n`) to
 *   stabilize shapes during transformation. When those locals are not subsequently referenced,
 *   they should be discarded to avoid numeric-suffix variables and warnings-as-errors.
 *
 * HOW
 * - For each statement in EBlock/EDo: if it is an assignment with a simple LHS variable and
 *   RHS that is a simple expression (var, atom, number, string, remote/local call) and the
 *   LHS is not used later in the same container, rewrite the LHS to `_`.
 * - A final variable copy becomes its RHS directly: the enclosing
 *   block consumes its value, so an explicit discard assignment is unnecessary.
 * - A block nested as a statement of another block prints as plain statements
 *   in the same Elixir scope. A read in the statements after it, in any such
 *   enclosing block, also counts as a later use.
 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 * - Kept: loop lowering emits `[_g = 0, g_value = n, g9 = Enum.reduce(...)]` as a
 *   nested block, and the enclosing block reads `g9` after it. Before this check
 *   the result became `_ = Enum.reduce(...)` and the program lost the loop's pushes.
 */
class DropUnusedSimpleAliasToUnderscoreTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return walk(ast, null);
	}

	/**
	 * Rewrites the blocks in `n`, top-down. `after` holds the statements that run after
	 * `n` in the same Elixir scope (null when `n` does not share its parent's scope).
	 */
	static function walk(n:ElixirAST, after:Null<OptimizedUsageIndex>):ElixirAST {
		if (n == null || n.def == null)
			return n;
		return switch (n.def) {
			case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts, after)), n.metadata, n.pos);
			case EDo(statements): makeASTWithMeta(EDo(rewrite(statements, after)), n.metadata, n.pos);
			default: ElixirASTTransformer.transformAST(n, child -> walk(child, null));
		}
	}

	static function rewrite(stmts:Array<ElixirAST>, after:Null<OptimizedUsageIndex>):Array<ElixirAST> {
		if (stmts == null)
			return stmts;
		var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);
		function usedLater(index:Int, name:String):Bool {
			return OptimizedVarUseAnalyzer.usedLater(useIndex, index + 1, name) || OptimizedVarUseAnalyzer.usedLater(after, 0, name);
		}
		var out:Array<ElixirAST> = [];
		for (i in 0...stmts.length) {
			var stmt = switch (stmts[i].def) {
				case EBlock(_) | EDo(_): walk(stmts[i], laterInScope(stmts, i, after));
				default: walk(stmts[i], null);
			};
			var rewrittenStmt = stmt;
			switch (stmt.def) {
				case EBinary(Match, {def: EVar(lhs)}, rhs) if (isSimple(rhs) && hasNumericSuffix(lhs) && !usedLater(i, lhs)):
					rewrittenStmt = (i == stmts.length - 1 && isVariable(rhs)) ? makeASTWithMeta(rhs.def, stmt.metadata,
						stmt.pos) : makeASTWithMeta(EBinary(Match, makeAST(EVar("_")), rhs), stmt.metadata, stmt.pos);
				case EMatch(PVar(lhs), rhs) if (isSimple(rhs) && hasNumericSuffix(lhs) && !usedLater(i, lhs)):
					rewrittenStmt = (i == stmts.length - 1 && isVariable(rhs)) ? makeASTWithMeta(rhs.def, stmt.metadata,
						stmt.pos) : makeASTWithMeta(EMatch(PVar("_"), rhs), stmt.metadata, stmt.pos);
				default:
			}
			out.push(rewrittenStmt);
		}
		return out;
	}

	/** Index of the statements that run after `stmts[position]` in the same scope. */
	static function laterInScope(stmts:Array<ElixirAST>, position:Int, after:Null<OptimizedUsageIndex>):OptimizedUsageIndex {
		final merged = OptimizedVarUseAnalyzer.buildExact(stmts.slice(position + 1));
		if (after != null && after.suffix != null && after.suffix.length > 0)
			for (name in after.suffix[0].keys())
				merged.suffix[0].set(name, true);
		return merged;
	}

	static function isVariable(expr:ElixirAST):Bool {
		return switch (expr.def) {
			case EVar(_): true;
			default: false;
		};
	}

	static function isSimple(e:ElixirAST):Bool {
		return switch (e.def) {
			case EVar(_) | EString(_) | EStringLiteral(_) | EInteger(_) | EFloat(_) | EBoolean(_) | ENil | EAtom(_): true;
			case ERemoteCall(_, _, _) | ECall(_, _, _): true;
			case EParen(inner): isSimple(inner);
			default: false;
		}
	}

	static inline function hasNumericSuffix(name:String):Bool {
		if (name == null)
			return false;
		var re = ~/^(.+?)(\d+)$/;
		return re.match(name);
	}
}
#end
