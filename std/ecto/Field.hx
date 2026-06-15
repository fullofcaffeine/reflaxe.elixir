package ecto;

#if (elixir || reflaxe_runtime)
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * Compile-time checked Ecto schema field selectors.
 *
 * WHAT: `Field.of((user:User) -> user.email)` returns a schema-typed token
 * that prints as `:email` after Haxe type-checks the selector against `User`.
 *
 * WHY: Existing `Changeset` APIs keep string-literal compatibility for migration.
 * Dynamic field lists must use `Field.unsafe`, making runtime atom creation explicit.
 * New handwritten code should prefer typed tokens so field typos fail during Haxe
 * compilation and generated Elixir uses atoms.
 *
 * HOW: the macro extracts a direct field access from a typed selector lambda
 * and rewrites camelCase names to snake_case for Ecto.
 */
class Field {
	/**
	 * Build a changeset field token from a typed schema-field selector.
	 *
	 * Example:
	 * ```haxe
	 * changeset.validateRequired([
	 *   Field.of((user:User) -> user.name),
	 *   Field.of((user:User) -> user.email)
	 * ]);
	 * ```
	 */
	public static macro function of<T, V>(selector:ExprOf<T->V>):ExprOf<SchemaField<T>> {
		Context.typeof(selector);
		var fieldName = extractSelectedField(selector);
		return macro cast(($v{toSnakeCase(fieldName)} : elixir.types.Atom));
	}

	/**
	 * Build a schema field token from a dynamic string.
	 *
	 * Prefer `Field.of((schema:T) -> schema.field)` for handwritten code.
	 * Use this only for migration or interop paths where the field name is not
	 * known until runtime.
	 */
	public static macro function unsafe<T>(fieldName:ExprOf<String>):ExprOf<SchemaField<T>> {
		return switch (strip(fieldName).expr) {
			case EConst(CString(name, _)):
				macro cast(($v{toSnakeCase(name)} : elixir.types.Atom));
			case _:
				macro cast(untyped __elixir__('
          (fn field_name ->
             if is_atom(field_name) do
               field_name
             else
               field_name
               |> to_string()
               |> Macro.underscore()
               |> String.to_atom()
             end
           end).({0})
        ', $fieldName));
		}
	}

	#if macro
	static function extractSelectedField(selector:Expr):String {
		return switch (strip(selector).expr) {
			case EFunction(_, func):
				extractFieldFromBody(func.expr, selector.pos);
			case _:
				Context.error("ecto.Field.of expects a selector lambda, for example Field.of((user:User) -> user.email)", selector.pos);
		}
	}

	static function extractFieldFromBody(body:Expr, pos:Position):String {
		return switch (strip(body).expr) {
			case EReturn(value):
				extractFieldAccess(value, pos);
			case EBlock([value]):
				extractFieldFromBody(value, pos);
			case _:
				extractFieldAccess(body, pos);
		}
	}

	static function extractFieldAccess(expr:Expr, pos:Position):String {
		return switch (strip(expr).expr) {
			case EField(_, fieldName):
				fieldName;
			case _:
				Context.error("ecto.Field.of selectors must return a direct schema field, for example Field.of((user:User) -> user.email)", pos);
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
