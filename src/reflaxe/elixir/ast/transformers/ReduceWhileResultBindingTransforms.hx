package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTHelpers.*;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReduceWhileResultBindingTransforms
 *
 * WHAT
 * - Binds Enum.reduce_while(...) result back to the original accumulator locals
 *   when the accumulator is a variable tuple (e.g., `{s, l, r}`).
 *
 * WHY
 * - While→reduce_while desugaring sometimes emits unused reduce_while results.
 *   Without rebinding, subsequent code reads stale locals.
 *
 * HOW
 * - When encountering `Enum.reduce_while(collection, {v1, v2}, fn ... end)`
 *   with a variable-only accumulator tuple, rewrite to
 *   `{v1, v2} = Enum.reduce_while(...)`.
 *
 * EXAMPLES
 * Elixir before:
 *   Enum.reduce_while(stream, {s, l}, fn _, {s, l} -> ... end)
 *   if l > 0, do: String.slice(s, 0, l)
 *
 * Elixir after:
 *   {s, l} = Enum.reduce_while(stream, {s, l}, fn _, {s, l} -> ... end)
 *   if l > 0, do: String.slice(s, 0, l)
 */
class ReduceWhileResultBindingTransforms {
	public static function bindReduceWhileResultPass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(node:ElixirAST):ElixirAST {
			return switch (node.def) {
				case ERemoteCall(mod, fn, args) if (isEnumReduceWhile(mod, fn, args)):
					var acc = args[1];
					switch (acc.def) {
						case ETuple(items):
							var pattern = tuplePatternFromAccumulator(items);
							pattern != null ? makeASTWithMeta(EMatch(pattern, node), node.metadata, node.pos) : node;
						case EVar(name):
							// Single-variable accumulator: v = Enum.reduce_while(...)
							makeASTWithMeta(EMatch(PVar(name), node), node.metadata, node.pos);
						default:
							node;
					}
				default:
					node;
			}
		});
	}

	static inline function isEnumReduceWhile(mod:ElixirAST, fn:String, args:Array<ElixirAST>):Bool {
		if (fn != "reduce_while" || args == null || args.length < 3)
			return false;
		return switch (mod.def) {
			case EVar(m): m == "Enum";
			default: false;
		};
	}

	static function tuplePatternFromAccumulator(items:Array<ElixirAST>):Null<EPattern> {
		var patterns:Array<EPattern> = [];
		for (item in items) {
			switch (item.def) {
				case EVar(name) if (name != "_"):
					patterns.push(PVar(name));
				default:
					return null;
			}
		}
		return patterns.length > 0 ? PTuple(patterns) : null;
	}
}
#end
