package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * AccAliasLateRewriteTransforms
 *
 * WHAT
 * - As a final safety-net, inside any anonymous function with two parameters `(binder, acc)`,
 *   rewrite accumulator alias self-append assignments
 *     alias = Enum.concat(alias, list)
 *     alias ++ list
 *   into canonical accumulator form
 *     acc = Enum.concat(acc, list)
 *   without relying on the surrounding reduce call shape.
 *
 * WHY
 * - Some pipelines generate reduce-like anonymous functions that are not recognized by earlier passes
 *   due to intervening wrappers or shape differences. This pass guarantees canonical accumulator updates
 *   before printing, eliminating undefined-local and hygiene warnings while adhering to idiomatic Elixir.
 *
 * HOW
 * - For each anonymous function with at least two parameters, take the second parameter as the
 *   accumulator and rewrite its body, but not the bodies of nested anonymous functions.
 * - Whenever an assignment is encountered where the RHS structurally self-appends the LHS via
 *   `Enum.concat/2`, `concat/2`, or `++`, rewrite the assignment to target the acc parameter instead
 *   and normalize the RHS to `Enum.concat(acc, list)`.
 * - This is name-agnostic and strictly shape-based; it does not introduce new variables.
 *
 * EXAMPLES
 * Elixir (before):
 *   fn item, acc ->
 *     list = [item]
 *     alias = Enum.concat(alias, list)
 *   end
 * Elixir (after):
 *   fn item, acc ->
 *     list = [item]
 *     acc = Enum.concat(acc, list)
 *   end
 */
class AccAliasLateRewriteTransforms {
	static function isSelfAppend(rhs:ElixirAST, lhs:String):Bool {
		var result = false;
		ASTUtils.walk(rhs, function(n:ElixirAST) {
			if (result)
				return;
			switch (n.def) {
				case ERemoteCall(_, "concat", args) if (args.length == 2):
					switch (args[0].def) {
						case EVar(nm) if (nm == lhs): result = true;
						default:
					}
				case ECall(_, "concat", argsC) if (argsC.length == 2):
					switch (argsC[0].def) {
						case EVar(nm2) if (nm2 == lhs): result = true;
						default:
					}
				case EBinary(Concat, l, _):
					switch (l.def) {
						case EVar(nm3) if (nm3 == lhs): result = true;
						default:
					}
				default:
			}
		});
		return result;
	}

	static function rewriteToAcc(lhsName:String, rhs:ElixirAST, accName:String, meta:ElixirMetadata, pos:haxe.macro.Expr.Position):ElixirAST {
		var newRight = ElixirASTTransformer.transformNode(rhs, function(z:ElixirAST):ElixirAST {
			return switch (z.def) {
				case ERemoteCall(_, "concat", argsX) if (argsX.length == 2):
					makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), argsX[1]]), z.metadata, z.pos);
				case ECall(_, "concat", argsCX) if (argsCX.length == 2):
					makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), argsCX[1]]), z.metadata, z.pos);
				case EBinary(Concat, _, r):
					makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), r]), z.metadata, z.pos);
				default:
					z;
			}
		});
		return makeASTWithMeta(EBinary(Match, makeAST(EVar(accName)), newRight), meta, pos);
	}

	/**
	 * Rewrite the self-appends of one callback body to its accumulator `accName`.
	 *
	 * Nested anonymous functions are left as they are: each one has its own
	 * accumulator, and `transformPass` already rewrote it. For example, the inner
	 * loop of `[for (x in xs) for (k in m.keys()) x + k]` is
	 * `{acc} = Enum.reduce_while(keys, {acc}, fn k, {acc__g_acc} -> acc__g_acc = acc__g_acc ++ [x <> k] ... end)`;
	 * renaming its update to the outer `acc` lost every element.
	 */
	static function rewriteCurrentScope(body:ElixirAST, accName:String):ElixirAST {
		return ElixirASTTransformer.transformNodeUntil(body, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EBinary(Match, left, rhs):
					var lhsName:Null<String> = switch (left.def) {
						case EVar(nm): nm;
						default: null;
					};
					if (lhsName != null && isSelfAppend(rhs, lhsName)) {
						rewriteToAcc(lhsName, rhs, accName, n.metadata, n.pos);
					} else n;
				case EMatch(pat, rhs2):
					var lhsName2:Null<String> = switch (pat) {
						case PVar(nm): nm;
						default: null;
					};
					if (lhsName2 != null && isSelfAppend(rhs2, lhsName2)) {
						rewriteToAcc(lhsName2, rhs2, accName, n.metadata, n.pos);
					} else n;
				default:
					n;
			}
		}, n -> switch (n.def) {
			case EFn(_): true;
			default: false;
		});
	}

	public static function transformPass(ast:ElixirAST):ElixirAST {
		// Children first: an inner callback is rewritten before its parent, and the
		// parent's scoped rewrite does not enter it again.
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EFn(clauses) if (clauses.length == 1):
					var cl = clauses[0];
					if (cl.args.length < 2)
						return n;
					var accName:Null<String> = switch (cl.args[1]) {
						case PVar(a): a;
						default: null;
					};
					if (accName == null)
						return n;
					makeASTWithMeta(EFn([{args: cl.args, guard: cl.guard, body: rewriteCurrentScope(cl.body, accName)}]), n.metadata, n.pos);
				default:
					n;
			}
		});
	}
}
#end
