package ecto;

#if (elixir || reflaxe_runtime)
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * Compile-time checked Ecto association selectors.
 *
 * WHAT: `Association.of((todo:Todo) -> todo.user)` returns a schema-typed
 * token that prints as `:user` after Haxe type-checks the selector.
 *
 * WHY: Ecto join/preload APIs are commonly stringly typed in Haxe wrappers even
 * though association names are finite schema fields. Typed tokens catch typos
 * during Haxe compilation while still emitting normal Ecto atoms.
 *
 * HOW: the macro extracts a direct field access from a typed selector lambda and
 * rewrites camelCase names to snake_case for Ecto.
 */
class Association {
	/**
	 * Build an association token from a typed schema association selector.
	 *
	 * Example:
	 * ```haxe
	 * query.preload([
	 *   Association.of((todo:Todo) -> todo.user),
	 *   Association.of((todo:Todo) -> todo.comments)
	 * ]);
	 * ```
	 */
	public static macro function of<T, V>(selector:ExprOf<T->V>):ExprOf<SchemaAssociation<T>> {
		Context.typeof(selector);
		var associationName = extractSelectedAssociation(selector);
		return macro cast(($v{toSnakeCase(associationName)} : elixir.types.Atom));
	}

	/**
	 * Build an association token from a dynamic string.
	 *
	 * Prefer `Association.of((schema:T) -> schema.association)` for handwritten
	 * code. Use this only when the association name is not known until runtime.
	 */
	public static macro function unsafe<T>(associationName:ExprOf<String>):ExprOf<SchemaAssociation<T>> {
		return switch (strip(associationName).expr) {
			case EConst(CString(name, _)):
				macro cast(($v{toSnakeCase(name)} : elixir.types.Atom));
			case _:
				macro cast(untyped __elixir__('
          (fn association_name ->
             if is_atom(association_name) do
               association_name
             else
               association_name
               |> to_string()
               |> Macro.underscore()
               |> String.to_atom()
             end
           end).({0})
        ', $associationName));
		}
	}

	#if macro
	static function extractSelectedAssociation(selector:Expr):String {
		return switch (strip(selector).expr) {
			case EFunction(_, func):
				extractAssociationFromBody(func.expr, selector.pos);
			case _:
				Context.error("ecto.Association.of expects a selector lambda, for example Association.of((todo:Todo) -> todo.user)", selector.pos);
		}
	}

	static function extractAssociationFromBody(body:Expr, pos:Position):String {
		return switch (strip(body).expr) {
			case EReturn(value):
				extractFieldAccess(value, pos);
			case EBlock([value]):
				extractAssociationFromBody(value, pos);
			case _:
				extractFieldAccess(body, pos);
		}
	}

	static function extractFieldAccess(expr:Expr, pos:Position):String {
		return switch (strip(expr).expr) {
			case EField(_, fieldName):
				fieldName;
			case _:
				Context.error("ecto.Association.of selectors must return a direct schema association, for example Association.of((todo:Todo) -> todo.user)",
					pos);
		}
	}

	static function strip(expr:Expr):Expr {
		return switch (expr.expr) {
			case EParenthesis(inner) | EMeta(_, inner) | ECheckType(inner, _) | ECast(inner, _):
				strip(inner);
			case _:
				expr;
		}
	}

	static function toSnakeCase(name:String):String {
		var result = new StringBuf();
		for (index in 0...name.length) {
			var code = name.charCodeAt(index);
			var isUpper = code >= "A".code && code <= "Z".code;
			if (isUpper) {
				if (index > 0) {
					result.add("_");
				}
				result.addChar(code + 32);
			} else {
				result.addChar(code);
			}
		}
		return result.toString();
	}
	#end
}
#end
