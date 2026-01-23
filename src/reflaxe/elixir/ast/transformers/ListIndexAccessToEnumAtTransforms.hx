package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypeTools;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ListIndexAccessToEnumAtTransforms
 *
 * WHAT
 * - Rewrites Haxe-style array index access on values typed as `Array<T>` to `Enum.at/2`.
 *   Example: arr[idx] -> Enum.at(arr, idx)
 *
 * WHY
 * - Elixir's Access protocol does not support indexing lists by number with []
 *   (it raises). Haxe-style array indexing lowers to EAccess; we must emit
 *   Enum.at(list, index) for list values.
 *
 * HOW
 * - Prefer a type-driven rewrite using Haxe type metadata:
 *   - If the target is typed as `Array<...>` and the key is typed `Int`, rewrite to `Enum.at/2`.
 * - Keep a narrow structural fallback for legacy/no-metadata cases:
 *   - entry.metas[0] -> Enum.at(entry.metas, 0)

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class ListIndexAccessToEnumAtTransforms {
	static function isHaxeArrayType(t: Null<Type>): Bool {
		if (t == null) return false;
		return switch (TypeTools.follow(t)) {
			case TInst(ref, _):
				var cls = ref.get();
				cls.name == "Array" && cls.pack.length == 0;
			case TLazy(f):
				isHaxeArrayType(f());
			case TType(td, _):
				isHaxeArrayType(td.get().type);
			default:
				false;
		};
	}

	static function isIntType(t: Null<Type>): Bool {
		if (t == null) return false;
		return switch (TypeTools.follow(t)) {
			case TAbstract(ref, params):
				var a = ref.get();
				if (a.name == "Int" && a.pack.length == 0) {
					true;
				} else if (a.name == "Null" && a.pack.length == 0 && params != null && params.length == 1) {
					isIntType(params[0]);
				} else {
					false;
				}
			case TLazy(f):
				isIntType(f());
			case TType(td, _):
				isIntType(td.get().type);
			default:
				false;
		};
	}

	public static function transformPass(ast: ElixirAST): ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
			return switch (n.def) {
				case EAccess(target, key):
					var targetType = target != null && target.metadata != null ? target.metadata.type : null;
					var keyType = key != null && key.metadata != null ? key.metadata.type : null;
					var isArrayIndexAccess = isHaxeArrayType(targetType) && isIntType(keyType);
					if (!isArrayIndexAccess && n.metadata != null && n.metadata.sourceExpr != null) {
						switch (n.metadata.sourceExpr.expr) {
							case TArray(arrayExpr, indexExpr):
								isArrayIndexAccess = isHaxeArrayType(arrayExpr.t) && isIntType(indexExpr.t);
							default:
						}
					}
					if (isArrayIndexAccess) {
						makeASTWithMeta(ERemoteCall(makeAST(EVar('Enum')), 'at', [target, key]), n.metadata, n.pos);
					} else {
						switch [target.def, key.def] {
							case [EField(obj, field), EInteger(_)] if (field == 'metas'):
								var fieldExpr = makeAST(EField(obj, field));
								makeASTWithMeta(ERemoteCall(makeAST(EVar('Enum')), 'at', [fieldExpr, key]), n.metadata, n.pos);
							default:
								n;
						}
					}
				default:
					n;
			}
		});
	}
}

#end
