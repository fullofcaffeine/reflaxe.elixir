package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * Removes a zero-argument IIFE after its body has become one binding-free expression.
 *
 * WHAT
 * - Rewrites `(fn -> expression end).()` to `expression` when the anonymous
 *   function has one unguarded zero-argument clause and its body contains one
 *   expression that cannot bind or rebind a variable in the caller's scope.
 *
 * WHY
 * - `FunctionArgBlockToIIFETransforms` must isolate genuine multi-statement
 *   argument blocks while semantic lowering is still in progress.
 * - Later normalization can collapse such a block to a field read, collection
 *   operation, or other single expression. Keeping the obsolete function shell
 *   produces mechanically noisy Elixir such as
 *   `Path.join((fn -> root.absolute end).(), "package.json")`.
 * - Removing the shell only at the absolute end retains the early safety
 *   boundary while allowing final output to read like authored Elixir.
 *
 * HOW
 * - Recognize only an immediate call of one unguarded zero-argument `EFn` clause.
 * - Peel singleton `EBlock`/`EDo` containers left by earlier lowering.
 * - Require a recursively binding-free expression. Calls may have effects, but
 *   they still execute exactly once at the same argument position; assignments,
 *   matches, macros, control-flow binders, raw target code, and other uncertain
 *   forms retain the IIFE because moving them could change lexical scope.
 * - Preserve the outer expression's source metadata on the replacement.
 *
 * EXAMPLES
 * - `(fn -> package_root.absolute end).()` becomes `package_root.absolute`.
 * - `(fn -> List.insert_at(lines, index, value) end).()` becomes the direct call.
 * - `(fn -> value = compute(); value end).()` is retained because its binding is
 *   intentionally isolated from the caller.
 *
 * @see test/snapshot/core/trivial_iife_unwrap
 */
class TrivialIIFEUnwrapTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(node:ElixirAST):ElixirAST {
			return switch (node.def) {
				case ECall(target, functionName, args) if (target != null && functionName == "" && args.length == 0):
					var functionTarget = unwrapParens(target);
					switch (functionTarget.def) {
						case EFn(clauses) if (clauses.length == 1):
							var clause = clauses[0];
							var expression = singletonExpression(clause.body);
							if (clause.args.length == 0 && clause.guard == null && expression != null && isCallerBindingFree(expression))
								makeASTWithMeta(expression.def, node.metadata, node.pos); else node;
						default:
							node;
					}
				default:
					node;
			}
		});
	}

	static function unwrapParens(expression:ElixirAST):ElixirAST {
		var current = expression;
		while (current != null)
			switch (current.def) {
				case EParen(inner):
					current = inner;
				default:
					return current;
			}
		return expression;
	}

	static function singletonExpression(body:ElixirAST):Null<ElixirAST> {
		if (body == null || body.def == null)
			return null;
		return switch (body.def) {
			case EBlock(expressions) | EDo(expressions) if (expressions.length == 1):
				singletonExpression(expressions[0]);
			default:
				body;
		}
	}

	/**
	 * Proves that moving an expression out of an anonymous-function scope cannot
	 * introduce or rebind a caller-local variable. This is deliberately narrower
	 * than an effect analysis: a binding-free call may raise, send, or perform I/O,
	 * but direct evaluation preserves its position and exactly-once behavior.
	 */
	static function isCallerBindingFree(expression:ElixirAST):Bool {
		if (expression == null || expression.def == null)
			return false;

		return switch (expression.def) {
			case EAtom(_) | EString(_) | EInteger(_) | EFloat(_) | EBoolean(_) | ENil | ECharlist(_) | EVar(_) | EAssign(_) | ESigil(_, _, _):
				true;

			// Creating an anonymous function preserves its own lexical scope. Its body
			// is intentionally not evaluated while the outer IIFE is being removed.
			case EFn(_):
				true;

			case EParen(inner) | EUnary(_, inner) | EPin(inner) | ECapture(inner, _) | EThrow(inner):
				isCallerBindingFree(inner);

			case ERaise(exception, attributes): isCallerBindingFree(exception) && (attributes == null || isCallerBindingFree(attributes));

			case ECall(target, _, args): (target == null || isCallerBindingFree(target)) && allBindingFree(args);

			case ERemoteCall(module, _, args): isCallerBindingFree(module) && allBindingFree(args);

			case EPipe(left, right) | ESend(left, right): isCallerBindingFree(left) && isCallerBindingFree(right);

			case EBinary(binaryOp, left, right): binaryOp != Match && isCallerBindingFree(left) && isCallerBindingFree(right);

			case EField(target, _):
				isCallerBindingFree(target);

			case EAccess(target, key): isCallerBindingFree(target) && isCallerBindingFree(key);

			case ERange(start, end, _, step): isCallerBindingFree(start) && isCallerBindingFree(end) && (step == null || isCallerBindingFree(step));

			case EList(elements) | ETuple(elements):
				allBindingFree(elements);

			case EMap(pairs):
				var safe = true;
				for (pair in pairs)
					if (!isCallerBindingFree(pair.key) || !isCallerBindingFree(pair.value)) {
						safe = false;
						break;
					}
				safe;

			case EStruct(_, fields):
				var safe = true;
				for (field in fields)
					if (!isCallerBindingFree(field.value)) {
						safe = false;
						break;
					}
				safe;

			case EStructUpdate(struct, fields):
				var safe = isCallerBindingFree(struct);
				if (safe)
					for (field in fields)
						if (!isCallerBindingFree(field.value)) {
							safe = false;
							break;
						}
				safe;

			case EKeywordList(pairs):
				var safe = true;
				for (pair in pairs)
					if (!isCallerBindingFree(pair.value)) {
						safe = false;
						break;
					}
				safe;

			case EBitstring(segments):
				var safe = true;
				for (segment in segments)
					if (!isCallerBindingFree(segment.value) || (segment.size != null && !isCallerBindingFree(segment.size))) {
						safe = false;
						break;
					}
				safe;

			// Blocks nested inside a single expression are safe only when every child
			// is binding-free. Multi-expression outer bodies never reach this function.
			case EBlock(expressions) | EDo(expressions):
				allBindingFree(expressions);

			default:
				false;
		}
	}

	static function allBindingFree(expressions:Array<ElixirAST>):Bool {
		if (expressions == null)
			return true;
		for (expression in expressions)
			if (!isCallerBindingFree(expression))
				return false;
		return true;
	}
}
#end
