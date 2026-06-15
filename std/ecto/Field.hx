package ecto;

#if (elixir || reflaxe_runtime)
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * Compile-time checked Ecto schema field selectors.
 *
 * WHAT: `Field.of((user:User) -> user.email)` returns `"email"` after Haxe
 * type-checks the selector against `User`.
 *
 * WHY: Existing `Changeset` APIs accept string field names for compatibility.
 * This helper keeps that stable surface while giving users refactor-checked
 * field authoring.
 *
 * HOW: the macro extracts a direct field access from a typed selector lambda
 * and rewrites camelCase names to snake_case for Ecto.
 */
class Field {
	/**
	 * Build a changeset field name from a typed schema-field selector.
	 *
	 * Example:
	 * ```haxe
	 * changeset.validateRequired([
	 *   Field.of((user:User) -> user.name),
	 *   Field.of((user:User) -> user.email)
	 * ]);
	 * ```
	 */
	public static macro function of<T, V>(selector:ExprOf<T->V>):ExprOf<String> {
		Context.typeof(selector);
		var fieldName = extractSelectedField(selector);
		return macro $v{toSnakeCase(fieldName)};
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
