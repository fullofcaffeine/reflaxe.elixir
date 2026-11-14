package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
	* ConcatSelfAssignBinderUnderscoreTransforms
	*
	* WHAT
	* - Rewrites statements of the form `x = Enum.concat(x, y)` to
	*   `_x = Enum.concat(x, y)` to avoid overshadowing warnings when the
	*   local binder `x` is not subsequently referenced. This keeps semantics
	*   (the concat result is computed) but prevents redefining the outer `x`.
	*
	* WHY
	* - Phoenix render helpers often fold list building via Enum.concat/2 and
	*   code generation may emit `item = Enum.concat(item, [...])` inside a block
	*   where `item` is also a surrounding variable. Elixir warns about the local
	*   `item` being unused. Underscoring the binder is idiomatic and silences it.

	*
	* HOW
	* - Walk the ElixirAST once with `ElixirASTTransformer.transformNode`, which visits
	*   children before parents, and rewrite the matching statements of each block.
	* - Each block is handled exactly once, so the cost grows linearly with the size of
	*   the function, also for deeply nested `case` chains.

	*
	* EXAMPLES
	* - Covered by snapshot tests under `test/snapshot/**`.
 */
class ConcatSelfAssignBinderUnderscoreTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return rewriteNode(ast);
	}

	static function rewriteNode(node:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				// `transformNode` visits children before parents, so function, anonymous
				// function and `case` bodies need no extra recursive call here. An extra call
				// repeats all nested work once per level and doubles the cost with each level.
				case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
				case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
				default: n;
			}
		});
	}

	static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
		if (stmts == null)
			return stmts;
		var out:Array<ElixirAST> = [];
		for (i in 0...stmts.length) {
			var s = stmts[i];
			switch (s.def) {
				case EBinary(Match, {def: EVar(b)}, {def: ERemoteCall({def: EVar("Enum")}, "concat", args)}) if (args != null && args.length >= 1):
					switch (args[0].def) {
						case EVar(b2) if (b2 == b):
							out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b)), makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", args))),
								s.metadata, s.pos));
						default:
							out.push(s);
					}
				case EBinary(Match, {def: EVar(b)}, {def: ECall(target, fnName, argsC)}) if (fnName == "concat" && argsC != null && argsC.length >= 1):
					var isEnum = switch (target.def) {
						case EVar(m): m == "Enum";
						default: false;
					};
					if (isEnum)
						switch (argsC[0].def) {
							case EVar(b2c) if (b2c == b):
								out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b)), makeAST(ECall(target, fnName, argsC))), s.metadata, s.pos));
							default:
								out.push(s);
						}
					else
						out.push(s);
				case EMatch(PVar(b3), {def: ERemoteCall({def: EVar("Enum")}, "concat", args2)}) if (args2 != null && args2.length >= 1):
					switch (args2[0].def) {
						case EVar(b4) if (b4 == b3):
							out.push(makeASTWithMeta(EMatch(PVar('_' + b3), makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", args2))), s.metadata, s.pos));
						default:
							out.push(s);
					}
				case EMatch(PVar(b3c), {def: ECall(target2, fnName2, args2c)}) if (fnName2 == "concat" && args2c != null && args2c.length >= 1):
					var isEnum2 = switch (target2.def) {
						case EVar(m2): m2 == "Enum";
						default: false;
					};
					if (isEnum2)
						switch (args2c[0].def) {
							case EVar(b4c) if (b4c == b3c):
								out.push(makeASTWithMeta(EMatch(PVar('_' + b3c), makeAST(ECall(target2, fnName2, args2c))), s.metadata, s.pos));
							default:
								out.push(s);
						}
					else
						out.push(s);
				default:
					out.push(s);
			}
		}
		return out;
	}
}
#end
