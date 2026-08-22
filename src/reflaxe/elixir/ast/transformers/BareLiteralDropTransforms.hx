package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * BareLiteralDropTransforms
 *
 * WHAT
 * - Removes standalone literal expressions from statement lists (`EBlock`/`EDo`) when they are not
 *   the final expression of the block.
 * - Also removes non-final wildcard matches to pure literals, such as `_ = 1`, because those are
 *   explicit discard statements with no side effects.
 * - When a non-final `if` result is discarded, removes a pure literal tail that follows side
 *   effects in either branch.
 *
 * WHY
 * - Elixir warns on “code block contains unused literal …” when a literal appears in statement
 *   position. Haxe code frequently produces these as the return value of an expression that is
 *   used for its side-effects (e.g. `DynamicAccess.set("y", 7);` returns `7`).
 *
 * HOW
 * - Walk `EBlock` and `EDo` and filter out non-final statements that are either pure literals
 *   (`EInteger`, `EFloat`, signed numeric literals, `EString`, `EBoolean`, `ENil`, `EAtom`,
 *   `ECharlist`) or wildcard matches whose RHS is one of those pure literals.
 *
 * EXAMPLES
 * Haxe:
 *   payload.set("y", 7);
 * Elixir (before):
 *   payload = Map.put(payload, "y", 7)
 *   7
 * Elixir (after):
 *   payload = Map.put(payload, "y", 7)
 */
class BareLiteralDropTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EBlock(stmts):
					makeASTWithMeta(EBlock(filterNonFinalLiterals(stmts)), n.metadata, n.pos);
				case EDo(stmts2):
					makeASTWithMeta(EDo(filterNonFinalLiterals(stmts2)), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	static function filterNonFinalLiterals(stmts:Array<ElixirAST>):Array<ElixirAST> {
		if (stmts == null || stmts.length <= 1)
			return stmts;
		var out:Array<ElixirAST> = [];
		for (i in 0...stmts.length) {
			var s = i < stmts.length - 1 ? dropDiscardedIfBranchLiteralResult(stmts[i]) : stmts[i];
			if (i < stmts.length - 1 && isDiscardedPureLiteral(s)) {
				continue;
			}
			out.push(s);
		}
		return out;
	}

	static function dropDiscardedIfBranchLiteralResult(ast:ElixirAST):ElixirAST {
		if (ast == null)
			return ast;
		return switch (ast.def) {
			case EIf(condition, thenBranch, elseBranch): var nextThen = dropDiscardedBranchLiteralTail(thenBranch); var nextElse = elseBranch != null ? dropDiscardedBranchLiteralTail(elseBranch) : null; nextThen == thenBranch && nextElse == elseBranch ? ast : makeASTWithMeta(EIf(condition,
					nextThen, nextElse), ast.metadata, ast.pos);
			default:
				ast;
		}
	}

	static function dropDiscardedBranchLiteralTail(branch:ElixirAST):ElixirAST {
		if (branch == null)
			return branch;
		return switch (branch.def) {
			case EBlock(expressions) if (expressions != null
				&& expressions.length > 1
				&& isPureLiteral(expressions[expressions.length - 1])):
				var kept = expressions.slice(0, expressions.length - 1);
				makeASTWithMeta(EBlock(kept), branch.metadata, branch.pos);
			case EDo(expressions) if (expressions != null && expressions.length > 1 && isPureLiteral(expressions[expressions.length - 1])):
				var kept = expressions.slice(0, expressions.length - 1);
				makeASTWithMeta(EDo(kept), branch.metadata, branch.pos);
			default:
				branch;
		}
	}

	static function isDiscardedPureLiteral(ast:ElixirAST):Bool {
		if (ast == null)
			return false;
		return switch (ast.def) {
			case EParen(inner):
				isDiscardedPureLiteral(inner);
			case EMatch(pattern, rhs) if (isWildcardPattern(pattern)):
				isPureLiteral(rhs);
			case EBinary(Match, lhs, rhs) if (isWildcardExpr(lhs)):
				isPureLiteral(rhs);
			default:
				isPureLiteral(ast);
		}
	}

	static function isPureLiteral(ast:ElixirAST):Bool {
		if (ast == null)
			return false;
		return switch (ast.def) {
			case EParen(inner):
				isPureLiteral(inner);
			case EBlock(exprs): exprs != null && exprs.length == 1 && isPureLiteral(exprs[0]);
			case EUnary(Negate, inner) | EUnary(Positive, inner):
				isUnsignedNumericLiteral(inner);
			case EAtom(_) | EString(_) | EInteger(_) | EFloat(_) | EBoolean(_) | ENil | ECharlist(_):
				true;
			default:
				false;
		}
	}

	static function isUnsignedNumericLiteral(ast:ElixirAST):Bool {
		if (ast == null)
			return false;
		return switch (ast.def) {
			case EParen(inner):
				isUnsignedNumericLiteral(inner);
			case EInteger(_) | EFloat(_):
				true;
			default:
				false;
		}
	}

	static function isWildcardPattern(pattern:EPattern):Bool {
		return switch (pattern) {
			case PWildcard | PVar("_"):
				true;
			default:
				false;
		}
	}

	static function isWildcardExpr(ast:ElixirAST):Bool {
		if (ast == null)
			return false;
		return switch (ast.def) {
			case EParen(inner):
				isWildcardExpr(inner);
			case EVar("_"):
				true;
			default:
				false;
		}
	}
}
#end
