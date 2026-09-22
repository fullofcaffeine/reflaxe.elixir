package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
	* JoinArgForceIIFETransforms
	*
	* WHAT
	* - Wrap a statement block used as the first join argument in a value scope.
	*
	* WHY
	* - Earlier rewrites may miss certain desugared list-builder forms outside of
	*   interpolation, leaving raw multi-statement sequences as the first arg.
	*   Elixir forbids statements in argument position.
	*
	* HOW
	* - Inspect the argument root, not expressions nested inside calls. Calls,
	*   assignments, and binary operators are already single Elixir expressions.
	*   Wrapping a call merely because one argument assigns a local would hide
	*   that write from the caller. Earlier effect lowering owns caller writeback
	*   from actual blocks; this pass must not introduce another scope around it.

	*
	* EXAMPLES
	* - Covered by snapshot tests under `test/snapshot/**`.
 */
class JoinArgForceIIFETransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case ERemoteCall(_, "join", args) if (args != null && args.length >= 1):
					var first = args[0];
					if (needsIIFE(first)) {
						var wrapped = makeIIFE(unwrapParens(first));
						var newArgs = [wrapped];
						for (i in 1...args.length)
							newArgs.push(args[i]);
						makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "join", newArgs), n.metadata, n.pos);
					} else {
						n;
					}
				default:
					n;
			}
		});
	}

	static inline function unwrapParens(e:ElixirAST):ElixirAST {
		return switch (e.def) {
			case EParen(inner): inner;
			default: e;
		}
	}

	static inline function makeIIFE(body:ElixirAST):ElixirAST {
		return makeAST(ECall(makeAST(EFn([{args: [], guard: null, body: body}])), "", []));
	}

	static function needsIIFE(e:ElixirAST):Bool {
		return switch (e.def) {
			case EBlock(_) | EDo(_): true;
			case EParen(inner): needsIIFE(inner);
			default: false;
		};
	}
}
#end
