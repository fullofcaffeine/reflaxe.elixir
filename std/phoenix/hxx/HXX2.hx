package phoenix.hxx;

/**
 * HXX2 entrypoint (AST-intercepted) (legacy)
 *
 * WHAT
 * - Stub functions so older generated code can call `phoenix.hxx.HXX2.root(...)`.
 *
 * WHY
 * - This type exists for backwards compatibility; new code should use `HeexTemplate.root/1`.
 *
 * HOW
 * - Keep a stable legacy call shape (`HXX2.root/1`) that the template pipeline intercepts.
 *
 * NOTE
 * - This module is compile-time only and is suppressed from emission in Elixir outputs.
 */
class HXX2 {
	// NOTE: Not `inline` on purpose.
	// The compiler detects HXX2.root calls in the typed AST and lowers them to ~H.
	@:deprecated("Use phoenix.hxx.HeexTemplate.root(...)")
	public static function root(template:String):String {
		throw "HXX2.root is compile-time only and must be lowered by the compiler pipeline";
	}
}
