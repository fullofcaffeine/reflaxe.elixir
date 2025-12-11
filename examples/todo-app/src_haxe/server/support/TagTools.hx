package server.support;

import elixir.ElixirString;


/**
 * Tag parsing helpers shared across LiveView handlers.
 * Pure Haxe implementation (no __elixir__ injections) that compiles to
 * TodoApp.TagTools.parse_tags/1.
 */
@:keep
@:native("TodoApp.TagTools")
class TagTools {
    @:native("parse_tags")
    public static function parseTags(tagsString:String):Array<String> {
        if (tagsString == null || tagsString == "") return [];
        // Split on commas, trim each tag with Elixir's String.trim/1, drop empties
        return ElixirString.splitOn(tagsString, ",")
            .map(function(tag) return ElixirString.trim(tag))
            .filter(function(tag) return tag != "");
    }
}
