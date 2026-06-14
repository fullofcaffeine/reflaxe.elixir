package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * Compile-time rejection helper for Haxe's host-database stdlib APIs.
 *
 * `sys.db.*` models direct host-driver access. BEAM applications should use
 * Ecto/Repo boundaries instead, so the Elixir target rejects these APIs at
 * compile time rather than emitting runtime stubs.
 */
class SysDbUnsupported {
	public static function reject(moduleName:String):Array<Field> {
		Context.error(moduleName
			+
			" is not supported on the Elixir target. Use Ecto schemas, Ecto.Query, and Repo calls through the `ecto.*` externs or an Elixir boundary module instead.",
			Context.currentPos());
		return Context.getBuildFields();
	}
}
#end
