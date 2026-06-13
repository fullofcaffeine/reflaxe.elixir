package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PubSubModuleRewriteTransforms
 *
 * WHAT
 * - Normalize bare `PubSub.*` remote calls to `Phoenix.PubSub.*`.
 *
 * WHY
 * - Haxe extern class names can reach the AST as the short class name even when
 *   the class is annotated `@:native("Phoenix.PubSub")`. A bare `PubSub` module
 *   does not exist in Phoenix apps and causes WAE/undefined-module warnings.
 *
 * HOW
 * - Rewrite only call-shaped AST nodes. Bare `PubSub` values are left alone so
 *   app-specific module references or child specs are not reinterpreted.
 *
 * EXAMPLES
 * - `PubSub.subscribe(pubsub, topic)` -> `Phoenix.PubSub.subscribe(pubsub, topic)`
 * - `PubSub.broadcast_from(pubsub, self(), topic, msg)` ->
 *   `Phoenix.PubSub.broadcast_from(pubsub, self(), topic, msg)`
 */
class PubSubModuleRewriteTransforms {
	public static function rewritePass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(node:ElixirAST):ElixirAST {
			return switch (node.def) {
				case ERemoteCall(module, functionName, args):
					switch (module.def) {
						case EVar(moduleName) if (isMisqualifiedPubSubModule(moduleName) && isPhoenixPubSubFunction(functionName)):
							makeASTWithMeta(ERemoteCall(makeAST(EVar("Phoenix.PubSub")), functionName, args), node.metadata, node.pos);
						default:
							node;
					}
				case ECall(target, functionName, args):
					if (target != null) {
						switch (target.def) {
							case EVar(moduleName) if (isMisqualifiedPubSubModule(moduleName) && isPhoenixPubSubFunction(functionName)):
								makeASTWithMeta(ERemoteCall(makeAST(EVar("Phoenix.PubSub")), functionName, args), node.metadata, node.pos);
							default:
								node;
						}
					} else {
						node;
					}
				default:
					node;
			}
		});
	}

	static function isMisqualifiedPubSubModule(moduleName:String):Bool {
		return moduleName == "PubSub"
			|| moduleName == "Pubsub"
			|| StringTools.endsWith(moduleName, ".PubSub")
			|| StringTools.endsWith(moduleName, ".Pubsub");
	}

	static function isPhoenixPubSubFunction(functionName:String):Bool {
		return switch (functionName) {
			case "subscribe" | "broadcast" | "broadcast_from" | "unsubscribe": true;
			default: false;
		}
	}
}
#end
