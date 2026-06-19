package ecto;

#if (elixir || reflaxe_runtime)
import elixir.types.Atom;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * Schema-typed Ecto association token.
 *
 * WHAT
 * - Represents an Ecto association name as an Elixir atom, tied to schema type `T`.
 *
 * WHY
 * - Ecto joins and preloads use association atoms such as `:user` or `:comments`.
 *   `Association.of((todo:Todo) -> todo.user)` lets Haxe type-check that the
 *   selected association exists before the compiler emits the atom.
 *
 * HOW
 * - The abstract wraps `elixir.types.Atom`, so token arrays compile directly to
 *   atom lists without runtime `String.to_atom/1` conversion.
 */
abstract SchemaAssociation<T>(Atom) to Atom {
	/**
	 * Legacy literal compatibility.
	 *
	 * String literals like `"comments"` are accepted where a `SchemaAssociation<T>`
	 * is expected and compile to `:comments`. Non-literal strings must use
	 * `Association.unsafe(...)` so runtime atom creation is visible at the callsite.
	 */
	@:from
	public static macro function fromStringLiteral<T>(association:ExprOf<String>):ExprOf<SchemaAssociation<T>> {
		return switch (association.expr) {
			case EConst(CString(name, _)):
				macro cast(($v{toSnakeCase(name)} : elixir.types.Atom));
			case _:
				Context.error("Dynamic Ecto association strings must use Association.unsafe(name) so runtime atom creation is explicit.", association.pos);
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
