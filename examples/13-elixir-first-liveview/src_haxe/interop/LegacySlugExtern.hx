package interop;

/**
 * LegacySlugExtern
 *
 * WHAT
 * - Thin typed boundary to a hand-written Elixir module.
 *
 * WHY
 * - This keeps interop explicit and API-faithful: Haxe calls a real Elixir module
 *   while keeping type signatures at the call site.
 *
 * HOW
 * - `@:native("ElixirFirstLiveview.LegacySlug")` maps this extern to the existing
 *   Elixir module.
 * - `@:unsafeExtern` marks this as an intentional app-local boundary in strict mode.
 *
 * EXAMPLE
 * - `LegacySlugExtern.normalize("Haxe + Elixir Interop")` -> `"haxe-elixir-interop"`
 */
@:native("ElixirFirstLiveview.LegacySlug")
@:unsafeExtern
extern class LegacySlugExtern {
	@:native("normalize")
	public static function normalize(value:String):String;
}
