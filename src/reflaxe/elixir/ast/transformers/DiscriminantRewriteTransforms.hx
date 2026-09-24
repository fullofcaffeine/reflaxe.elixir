package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

/**
 * Inline an adjacent, single-use case input without repeating its initializer.
 *
 * Only direct function-body statements are eligible: a nested block assignment
 * can remain visible outside that block in Elixir. Clause and suffix reads,
 * including pins, guards, closures and opaque native references, retain the
 * binding. Exact names are identities here; underscore variants are distinct.
 * For Haxe `var input = source(); var answer = switch input {...}`, move
 * `source()` into the Elixir case input and retain `answer = case ...`.
 * The initializer still runs once; only a plain result binding is eligible.
 */
class DiscriminantRewriteTransforms {
	public static function discriminantRewritePass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(node:ElixirAST):ElixirAST {
			return switch (node.def) {
				case EDef(name, args, guards, body):
					makeASTWithMeta(EDef(name, args, guards, rewriteBody(body)), node.metadata, node.pos);
				case EDefp(name, args, guards, body):
					makeASTWithMeta(EDefp(name, args, guards, rewriteBody(body)), node.metadata, node.pos);
				default:
					node;
			};
		});
	}

	static function reads(node:ElixirAST, name:String):Bool {
		return VarUseAnalyzer.usesFreeVarExact(node, name) || VarUseAnalyzer.stmtUsesVarExact(node, name);
	}

	static function rewriteBody(body:ElixirAST):ElixirAST {
		return switch (body.def) {
			case EBlock(statements):
				var result:Array<ElixirAST> = [];
				var index = 0;
				while (index < statements.length) {
					if (index + 1 < statements.length) {
						var original = statements[index + 1];
						var caseNode = switch (original.def) {
							case EMatch(PVar(_), value): value;
							default: original;
						};
						switch ([statements[index].def, caseNode.def]) {
							case [EMatch(PVar(name), init), ECase({def: EVar(target)}, clauses)] if (name == target):
								var live = reads(makeAST(ECase(makeAST(ENil), clauses)), name);
								for (later in index + 2...statements.length)
									if (reads(statements[later], name))
										live = true;
								if (!live) {
									var rewritten = makeASTWithMeta(ECase(init, clauses), caseNode.metadata, caseNode.pos);
									result.push(switch (original.def) {
										case EMatch(pattern, _): makeASTWithMeta(EMatch(pattern, rewritten), original.metadata, original.pos);
										default: rewritten;
									});
									index += 2;
									continue;
								}
							default:
						}
					}
					result.push(statements[index++]);
				}
				makeASTWithMeta(EBlock(result), body.metadata, body.pos);
			default:
				body;
		};
	}
}
#end
