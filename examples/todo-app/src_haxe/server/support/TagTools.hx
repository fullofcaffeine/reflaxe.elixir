package server.support;

import elixir.ElixirString;

/**
 * Tag parsing helpers shared across LiveView handlers.
 * Pure Haxe implementation (no __elixir__ injections) that compiles to
 * TodoApp.TagTools.parse_tags/1.
 */
// @:keep: `parse_tags/1` is called via generated/native-named paths, so keeping this module avoids DCE pruning an indirect entrypoint.
@:keep
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("TodoApp.TagTools")
class TagTools {
	// @:native (function): pins the emitted function/callback name to match an exact Elixir API.
	@:native("parse_tags")
	public static function parseTags(tagsString:String):Array<String> {
		if (tagsString == null || tagsString == "")
			return [];
		// Split on commas, trim each tag with Elixir's String.trim/1, drop empties
		return ElixirString.splitOn(tagsString, ",").map(function(tag) return ElixirString.trim(tag)).filter(function(tag) return tag != "");
	}
}
