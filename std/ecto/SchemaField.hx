package ecto;

#if (elixir || reflaxe_runtime)
import elixir.types.Atom;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * Schema-typed Ecto field token.
 *
 * WHAT
 * - Represents an Ecto schema field as an Elixir atom, tied to the schema type `T`.
 *
 * WHY
 * - Changeset APIs want atom fields (`:email`), while Haxe users want refactor-safe
 *   field references. `Field.of((user:User) -> user.email)` is the intended authoring
 *   path and returns `SchemaField<User>`.
 *
 * HOW
 * - The abstract wraps `elixir.types.Atom`, so literal tokens compile directly to
 *   Elixir atoms instead of runtime `String.to_atom/1` conversions.
 */
abstract SchemaField<T>(Atom) to Atom {
	/**
	 * Legacy literal compatibility.
	 *
	 * String literals like `"email"` are accepted where a `SchemaField<T>` is expected
	 * and compile to `:email`. Non-literal strings must use `Field.unsafe(...)` so
	 * dynamic atom creation is visible at the callsite.
	 */
	@:from
	public static macro function fromStringLiteral<T>(field:ExprOf<String>):ExprOf<SchemaField<T>> {
		return switch (field.expr) {
			case EConst(CString(name, _)):
				macro cast(($v{toSnakeCase(name)} : elixir.types.Atom));
			case _:
				Context.error("Dynamic Ecto field strings must use Field.unsafe(name) so runtime atom creation is explicit.", field.pos);
		}
	}

	#if macro
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
